import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_constants.dart';
import '../data/models/models.dart';

/// Centralized local-persistence service (Requirement 10.4).
///
/// Owns all reads/writes of the authentication session (token, refresh token,
/// organization id) and the per-organization cached [BrandingProfile], backed
/// by `shared_preferences`. Registered as a long-lived [GetxService] singleton
/// so [AuthService], the app bootstrap, and the theming layer share one
/// instance.
///
/// Initialize once during bootstrap with:
/// ```dart
/// await Get.putAsync<StorageService>(() => StorageService().init());
/// ```
class StorageService extends GetxService {
  StorageService({SharedPreferences? preferences}) : _preferences = preferences;

  static const String _logTag = 'STORAGE_SERVICE';

  SharedPreferences? _preferences;

  /// The resolved [SharedPreferences] instance. Throws a [StateError] if the
  /// service is used before [init] has completed, surfacing wiring mistakes
  /// early rather than silently no-opping.
  SharedPreferences get _prefs {
    final SharedPreferences? prefs = _preferences;
    if (prefs == null) {
      throw StateError(
        'StorageService used before init(). Register it via '
        'Get.putAsync<StorageService>(() => StorageService().init()).',
      );
    }
    return prefs;
  }

  /// Asynchronously resolves the backing [SharedPreferences] instance.
  ///
  /// Returns `this` so it composes with `Get.putAsync`. Safe to call multiple
  /// times; an instance injected via the constructor is left untouched.
  Future<StorageService> init() async {
    _preferences ??= await SharedPreferences.getInstance();
    return this;
  }

  // ---- Session persistence (Requirements 2.1, 2.2) ----

  /// Persists the [token], [refreshToken], and [organizationId] of a successful
  /// authentication. All three are stored together so the session is read back
  /// as a complete record.
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String organizationId,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _prefs.setString(AppConstants.tokenKey, token),
      _prefs.setString(AppConstants.refreshTokenKey, refreshToken),
      _prefs.setString(AppConstants.organizationIdKey, organizationId),
    ]);
  }

  /// Reads the persisted [Session].
  ///
  /// Returns a [Session] only when the token, refresh token, and organization
  /// id are all present and non-empty; otherwise returns `null`. This is the
  /// session-validity predicate that drives launch routing (Requirements 2.1,
  /// 2.2).
  Future<Session?> readSession() async {
    final String? token = _prefs.getString(AppConstants.tokenKey);
    final String? refreshToken =
        _prefs.getString(AppConstants.refreshTokenKey);
    final String? organizationId =
        _prefs.getString(AppConstants.organizationIdKey);

    if (token == null || token.isEmpty) {
      return null;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    if (organizationId == null || organizationId.isEmpty) {
      return null;
    }

    return Session(
      token: token,
      refreshToken: refreshToken,
      organizationId: organizationId,
    );
  }

  /// Clears the persisted session (token, refresh token, organization id).
  ///
  /// Used on logout and when a token refresh fails. Cached branding is left
  /// intact so a returning organization can still theme from cache.
  Future<void> clearSession() async {
    await Future.wait<void>(<Future<void>>[
      _prefs.remove(AppConstants.tokenKey),
      _prefs.remove(AppConstants.refreshTokenKey),
      _prefs.remove(AppConstants.organizationIdKey),
    ]);
  }

  // ---- Cached branding (Requirements 10.4) ----

  /// Caches the [profile] for the organization identified by [orgId].
  ///
  /// Stored under a per-organization key (`cachedBrandingKeyPrefix` + orgId) so
  /// each tenant's branding is isolated, serialized via the model's `toJson`.
  Future<void> cacheBranding(String orgId, BrandingProfile profile) async {
    final String key = _brandingKey(orgId);
    final String encoded = jsonEncode(profile.toJson());
    await _prefs.setString(key, encoded);
  }

  /// Reads the cached [BrandingProfile] for [orgId], or `null` when none is
  /// cached or the stored value cannot be decoded.
  Future<BrandingProfile?> readCachedBranding(String orgId) async {
    final String? encoded = _prefs.getString(_brandingKey(orgId));
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return BrandingProfile.fromJson(decoded);
      }
      return null;
    } catch (e) {
      log('$_logTag failed to decode cached branding for $orgId: $e');
      return null;
    }
  }

  /// Removes the cached branding for [orgId].
  ///
  /// Used when switching organizations so a previous tenant's branding does not
  /// linger (supports Requirement 3.4 clean tenant switch).
  Future<void> clearCachedBranding(String orgId) async {
    await _prefs.remove(_brandingKey(orgId));
  }

  String _brandingKey(String orgId) =>
      '${AppConstants.cachedBrandingKeyPrefix}$orgId';
}
