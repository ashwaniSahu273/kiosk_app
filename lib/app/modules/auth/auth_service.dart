import 'dart:async';

import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../core/data/kiosk_repository.dart';
import '../../core/data/models/models.dart';
import '../../core/network/api_auth_context.dart';
import '../../core/network/api_result.dart';
import '../../core/services/organization_context.dart';
import '../../core/services/storage_service.dart';

/// Centralized authentication service (Requirements 1, 2).
///
/// Coordinates the three collaborators that make up an authenticated kiosk
/// session:
///
/// * [KioskRepository] — performs the login (and, for the demo, content reads
///   used to resolve an organization).
/// * [StorageService] — persists/reads the session (token, refresh token,
///   organization id) and cached branding.
/// * [OrganizationContext] — holds the active organization and drives theming.
///
/// The service holds the current [Session] in memory so it can satisfy the
/// [ApiAuthContext] the `ApiClient` depends on (`accessToken`,
/// `organizationId`, and a single `refreshSession` attempt), letting the
/// network layer be wired to this service during bootstrap without taking a
/// hard dependency on it.
///
/// Persistence is strictly success-gated: a session is written only after a
/// successful login or a successful refresh. Failures, timeouts, and
/// unreachable conditions persist nothing (Requirements 1.5, 1.8). Errors are
/// surfaced to callers through the returned [ApiResult]; the service never
/// shows snackbars itself, leaving user-facing messaging to the controller via
/// the `NotificationService`.
class AuthService extends GetxService implements ApiAuthContext {
  AuthService({
    required KioskRepository repository,
    required StorageService storageService,
    required OrganizationContext organizationContext,
  })  : _repository = repository,
        _storageService = storageService,
        _organizationContext = organizationContext;

  final KioskRepository _repository;
  final StorageService _storageService;
  final OrganizationContext _organizationContext;

  /// The session currently held in memory, or null when signed out.
  ///
  /// Source of truth for [accessToken] and [hasCompleteSession].
  Session? _currentSession;

  /// Monotonic counter used to mint distinct demo tokens on each refresh, so a
  /// successful refresh produces observably new token material.
  int _refreshSequence = 0;

  /// The session currently held in memory, or null when signed out.
  Session? get currentSession => _currentSession;

  /// Whether a complete session is currently held: token, refresh token, and
  /// organization id all present and non-empty (Requirements 2.1, 2.2).
  bool get hasCompleteSession {
    final Session? session = _currentSession;
    return session != null &&
        session.token.isNotEmpty &&
        session.refreshToken.isNotEmpty &&
        session.organizationId.isNotEmpty;
  }

  // ---- ApiAuthContext ----

  /// The current bearer access token, or null when unauthenticated
  /// (consumed by the `ApiClient` to inject `Authorization: Bearer <token>`).
  @override
  String? get accessToken => _currentSession?.token;

  /// The active organization identifier, sourced from the
  /// [OrganizationContext] so it always reflects the active tenant.
  @override
  String? get organizationId => _organizationContext.organizationId;

  // ---- Authentication ----

  /// Authenticates an administrator with [email] and [password].
  ///
  /// Allows up to [AppConstants.authTimeout] (30s) for a response
  /// (Requirement 1.2). On success it persists the token, refresh token, and
  /// resolved organization id via the [StorageService], resolves and activates
  /// the [OrganizationContext] (caching the organization's branding), and
  /// returns `ApiResult.success` carrying the [Session] (Requirements 1.3,
  /// 1.4).
  ///
  /// On a failure response, a timeout, or an unreachable backend it persists
  /// nothing and returns an `ApiResult.failure` whose message the controller
  /// can surface through the `NotificationService` (Requirements 1.5, 1.8).
  Future<ApiResult<Session>> login(String email, String password) async {
    final ApiResult<AuthResult> result;
    try {
      result = await _repository
          .login(email, password)
          .timeout(AppConstants.authTimeout);
    } on TimeoutException {
      return ApiResult<Session>.failure(
        408,
        'Sign-in could not be completed in time. Please try again.',
      );
    } catch (_) {
      return ApiResult<Session>.failure(
        0,
        'Sign-in could not be completed. Please check your connection and '
        'try again.',
      );
    }

    final AuthResult? auth = result.data;
    if (!result.success || auth == null) {
      // Failure response: persist nothing, surface the endpoint's message.
      return ApiResult<Session>.failure(
        result.statusCode,
        result.message ?? 'Sign-in failed. Please try again.',
      );
    }

    final Session session = auth.session;

    // Persist only after a successful authentication (Requirements 1.3, 1.4).
    await _storageService.saveSession(
      token: session.token,
      refreshToken: session.refreshToken,
      organizationId: session.organizationId,
    );

    // Resolve and activate the organization context (and cache its branding).
    await _activateOrganization(session.organizationId, auth.organization);

    _currentSession = session;

    return ApiResult<Session>.success(
      result.statusCode,
      session,
      message: result.message,
    );
  }

  /// Performs a single token-refresh attempt, allowing up to
  /// [AppConstants.refreshTimeout] (10s) to complete (Requirement 2.4).
  ///
  /// On success it persists the refreshed tokens via the [StorageService] and
  /// returns true so the `ApiClient` can retry the original request
  /// (Requirement 2.5). On any failure — no refresh token present, an error,
  /// or exceeding the 10-second budget — it returns false without throwing;
  /// the caller (`ApiClient`/controller) is responsible for clearing the
  /// session and routing to login (Requirement 2.6).
  @override
  Future<bool> refreshSession() async {
    try {
      return await _performRefresh().timeout(AppConstants.refreshTimeout);
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clears the persisted session and the active organization context on
  /// logout (Requirement 1.9).
  Future<void> logout() async {
    await _storageService.clearSession();
    _organizationContext.clear();
    _currentSession = null;
  }

  /// Restores a persisted session on launch (Requirements 2.1, 2.2).
  ///
  /// Reads the persisted [Session]; when absent or incomplete, returns false so
  /// the app routes to login. When a complete session is present, it resolves
  /// the organization (cached branding first, falling back to the
  /// repository/demo) and activates the [OrganizationContext], returning true
  /// only when the organization could be resolved so the home screen has the
  /// branding and theme it needs.
  Future<bool> restoreSession() async {
    final Session? session = await _storageService.readSession();
    if (session == null) {
      return false;
    }

    final Organization? organization =
        await _resolveOrganizationFromCacheOrRepository(session.organizationId);
    if (organization == null) {
      return false;
    }

    await _organizationContext.activate(organization);
    await _storageService.cacheBranding(
      organization.id,
      organization.branding,
    );

    _currentSession = session;
    return true;
  }

  // ---- Internal helpers ----

  /// Resolves [provided] (when the login response carried the organization) or
  /// looks the organization up, then activates it and caches its branding.
  ///
  /// [OrganizationContext.activate] purges a previous tenant's cached branding
  /// when the organization changes, so caching the new branding afterwards
  /// leaves no residue from a prior administrator (Requirements 3.4, 4.6).
  Future<void> _activateOrganization(
    String organizationId,
    Organization? provided,
  ) async {
    final Organization? organization = provided ??
        await _resolveOrganizationFromCacheOrRepository(organizationId);
    if (organization == null) {
      return;
    }
    await _organizationContext.activate(organization);
    await _storageService.cacheBranding(
      organization.id,
      organization.branding,
    );
  }

  /// Resolves an [Organization] for [organizationId], preferring cached
  /// branding (offline-friendly) and falling back to a repository read.
  /// Returns null when neither source can supply the organization.
  Future<Organization?> _resolveOrganizationFromCacheOrRepository(
    String organizationId,
  ) async {
    final BrandingProfile? cached =
        await _storageService.readCachedBranding(organizationId);
    if (cached != null) {
      return Organization(id: organizationId, branding: cached);
    }

    final ApiResult<Organization> result =
        await _repository.fetchOrganization(organizationId);
    if (result.success && result.data != null) {
      return result.data;
    }
    return null;
  }

  /// Single-attempt refresh body (without the timeout wrapper).
  ///
  /// For the offline demo a valid existing session is refreshed into a new
  /// session that keeps the same organization id but carries freshly minted
  /// token material, which is then persisted. Returns false when there is no
  /// session to refresh (no refresh token present).
  Future<bool> _performRefresh() async {
    final Session? current =
        _currentSession ?? await _storageService.readSession();
    if (current == null || current.refreshToken.isEmpty) {
      return false;
    }

    _refreshSequence++;
    final Session refreshed = current.copyWith(
      token: 'demo-token-${current.organizationId}-r$_refreshSequence',
      refreshToken: 'demo-refresh-${current.organizationId}-r$_refreshSequence',
    );

    await _storageService.saveSession(
      token: refreshed.token,
      refreshToken: refreshed.refreshToken,
      organizationId: refreshed.organizationId,
    );
    _currentSession = refreshed;
    return true;
  }
}
