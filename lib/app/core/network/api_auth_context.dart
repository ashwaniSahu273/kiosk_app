import 'dart:async';

/// Abstraction the [ApiClient] depends on for the values it must inject into
/// every request and for the token-refresh action it triggers on a 401.
///
/// This decouples the network layer from the concrete `OrganizationContext`
/// and `AuthService`, which are implemented in later tasks. Those services (or
/// a thin adapter) implement this interface and are wired into the client at
/// composition time, keeping the network layer free of direct dependencies on
/// authentication or organization state.
abstract class ApiAuthContext {
  /// The current bearer access token, or null when unauthenticated.
  ///
  /// Injected as `Authorization: Bearer <token>` when present.
  String? get accessToken;

  /// The active organization identifier, or null when no organization is
  /// active. Injected as the `X-Organization-Id` header when present.
  String? get organizationId;

  /// Performs a single token-refresh attempt.
  ///
  /// Returns true when the refresh succeeded (new tokens persisted and
  /// available via [accessToken]); false when it failed, timed out, or no
  /// refresh token was available. Implementations must not throw.
  Future<bool> refreshSession();
}

/// Callback-based [ApiAuthContext] adapter.
///
/// Useful for wiring the client to plain functions/closures (for example
/// during bootstrap before the concrete services are registered) without
/// creating a dedicated implementation class.
class CallbackApiAuthContext implements ApiAuthContext {
  CallbackApiAuthContext({
    required String? Function() accessTokenProvider,
    required String? Function() organizationIdProvider,
    required Future<bool> Function() onRefresh,
  })  : _accessTokenProvider = accessTokenProvider,
        _organizationIdProvider = organizationIdProvider,
        _onRefresh = onRefresh;

  final String? Function() _accessTokenProvider;
  final String? Function() _organizationIdProvider;
  final Future<bool> Function() _onRefresh;

  @override
  String? get accessToken => _accessTokenProvider();

  @override
  String? get organizationId => _organizationIdProvider();

  @override
  Future<bool> refreshSession() => _onRefresh();
}

/// A no-op [ApiAuthContext] that injects nothing and never refreshes.
///
/// Acts as a safe default before the real authentication/organization services
/// are wired in, so the client is always usable.
class NoopApiAuthContext implements ApiAuthContext {
  const NoopApiAuthContext();

  @override
  String? get accessToken => null;

  @override
  String? get organizationId => null;

  @override
  Future<bool> refreshSession() async => false;
}
