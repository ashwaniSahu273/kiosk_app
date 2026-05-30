import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/kiosk_repository.dart';
import '../data/models/models.dart';
import 'storage_service.dart';

/// Builds a [ThemeData] from a [BrandingProfile].
///
/// The concrete `ThemeEngine` (a later task) is the intended producer of this
/// function. [OrganizationContext] depends only on this signature so the
/// theming layer can be wired in without the context taking a hard dependency
/// on `ThemeEngine`.
typedef ThemeBuilder = ThemeData Function(BrandingProfile profile);

/// The currently active organization (tenant) whose identifier scopes all data
/// the kiosk requests and displays after authentication (Requirement 3).
///
/// Registered as a long-lived [GetxService] singleton. It holds:
///
/// * [active] — the active [Organization] (and, through it, the active
///   [BrandingProfile]), as an observable.
/// * [theme] — an observable [ThemeData] that the root `GetMaterialApp` can
///   drive so the whole tree re-themes when the organization changes.
///
/// The service is intentionally decoupled from the theming layer: instead of
/// constructing a `ThemeEngine` it accepts an injectable [ThemeBuilder] (see
/// [setThemeBuilder]). Until a builder is supplied it falls back gracefully and
/// leaves [theme] null, letting the app render with framework defaults.
///
/// Switching organizations is a clean replacement (Requirements 3.4, 4.6): when
/// [activate] is given an organization different from the previously resident
/// one, the previous organization's cached branding is cleared from the
/// [StorageService] so no residue from the prior tenant remains.
class OrganizationContext extends GetxService {
  OrganizationContext({
    StorageService? storageService,
    ThemeBuilder? themeBuilder,
  })  : _injectedStorage = storageService,
        _themeBuilder = themeBuilder;

  final StorageService? _injectedStorage;

  /// The active organization, or null when no administrator is signed in.
  final Rxn<Organization> active = Rxn<Organization>();

  /// The active organization's theme, or null when no [ThemeBuilder] has been
  /// supplied yet (the root app then renders with framework defaults).
  final Rxn<ThemeData> theme = Rxn<ThemeData>();

  /// Injectable theme producer. Wired by the theming layer (task 7).
  ThemeBuilder? _themeBuilder;

  /// Id of the organization whose state currently resides in the context
  /// (in-memory and cached). Survives [clear] so the next [activate] can purge
  /// a different previous tenant's cache even after a logout.
  String? _residentOrganizationId;

  /// Active organization id, or null when none is active.
  ///
  /// Exposed for an [ApiAuthContext] adapter (and the `ApiClient`) to inject the
  /// `X-Organization-Id` on outgoing requests, without coupling this service to
  /// the network/auth layers.
  String? get organizationId => active.value?.id;

  /// The active organization's [BrandingProfile], or null when none is active.
  BrandingProfile? get branding => active.value?.branding;

  /// Whether an organization is currently active.
  bool get hasActiveOrganization => active.value != null;

  /// Resolves the [StorageService] used to clear cached branding.
  ///
  /// Prefers a constructor-injected instance; otherwise resolves the registered
  /// singleton when present. Returns null when storage is unavailable so cache
  /// clearing degrades to a no-op rather than throwing.
  StorageService? get _storage {
    final StorageService? injected = _injectedStorage;
    if (injected != null) {
      return injected;
    }
    if (Get.isRegistered<StorageService>()) {
      return Get.find<StorageService>();
    }
    return null;
  }

  /// Supplies (or replaces) the [ThemeBuilder] used to build [theme].
  ///
  /// Lets the theming layer wire `ThemeEngine.buildTheme` after this service is
  /// constructed. If an organization is already active, its theme is rebuilt
  /// immediately so the new builder takes effect without re-activation.
  void setThemeBuilder(ThemeBuilder builder) {
    _themeBuilder = builder;
    final BrandingProfile? current = branding;
    if (current != null) {
      _applyTheme(current);
    }
  }

  /// Sets [org] as the active organization and (re)builds its [theme].
  ///
  /// This is the synchronous in-memory state mutation. Use [activate] when the
  /// previous tenant's cached branding must also be purged.
  void setActive(Organization org) {
    active.value = org;
    _residentOrganizationId = org.id;
    _applyTheme(org.branding);
  }

  /// Activates [org] as the active organization for the session.
  ///
  /// When [org] differs from the previously resident organization, the previous
  /// organization's cached branding is cleared from storage so no branding or
  /// content residue from the prior tenant remains (Requirements 3.4, 4.6).
  /// The active organization is then set and its theme built/applied.
  Future<void> activate(Organization org) async {
    final String? previousId = _residentOrganizationId;
    if (previousId != null && previousId != org.id) {
      await _clearCachedBranding(previousId);
    }
    setActive(org);
  }

  /// Clears the active organization on logout.
  ///
  /// Resets the in-memory active organization and theme to their fallback
  /// (null) state. The resident organization id is retained so a subsequent
  /// [activate] for a *different* organization can still purge this tenant's
  /// cached branding; cached branding itself is left intact so the same
  /// organization signing back in can re-theme from cache.
  void clear() {
    active.value = null;
    theme.value = null;
  }

  /// Filters [items] to those owned by the active organization, dropping every
  /// item whose `organizationId` does not match (Requirements 3.2, 3.3).
  ///
  /// Returns an empty list when no organization is active, ensuring no
  /// cross-tenant (or orphaned) content is ever surfaced. Reuses the pure
  /// [KioskRepository.scopeToOrganization] filter so scoping behaves
  /// identically wherever it is applied.
  List<T> scoped<T extends OrgOwned>(List<T> items) {
    final String? activeId = organizationId;
    if (activeId == null) {
      return List<T>.unmodifiable(const <Never>[]);
    }
    return KioskRepository.scopeToOrganization<T>(items, activeId);
  }

  /// Builds and applies the theme for [profile] via the injected
  /// [ThemeBuilder], or leaves [theme] unchanged when no builder is set yet.
  void _applyTheme(BrandingProfile profile) {
    final ThemeBuilder? builder = _themeBuilder;
    if (builder == null) {
      return;
    }
    theme.value = builder(profile);
  }

  /// Clears the cached branding for [orgId] when storage is available.
  Future<void> _clearCachedBranding(String orgId) async {
    final StorageService? storage = _storage;
    if (storage == null) {
      return;
    }
    await storage.clearCachedBranding(orgId);
  }
}
