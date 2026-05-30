/// App-wide constants: identity, storage keys, network timeouts, and header
/// names used by the centralized [ApiClient].
///
/// Timeouts follow the design: 30 seconds for content/auth requests and a
/// single 10-second attempt for token refresh.
class AppConstants {
  const AppConstants._();

  /// Human-readable application name.
  static const String appName = 'Kiosk App';

  // ---- Network timeouts ----

  /// Timeout applied to standard content requests (GET/POST org content).
  static const Duration contentTimeout = Duration(seconds: 30);

  /// Timeout applied to the authentication (login) request.
  static const Duration authTimeout = Duration(seconds: 30);

  /// Timeout applied to the single token-refresh attempt triggered on 401.
  static const Duration refreshTimeout = Duration(seconds: 10);

  // ---- Request headers ----

  /// Header carrying the active organization identifier on every scoped
  /// request, injected by the [ApiClient] from the active organization context.
  static const String organizationIdHeader = 'X-Organization-Id';

  /// Header carrying the bearer access token.
  static const String authorizationHeader = 'Authorization';

  // ---- Storage keys (consumed by the StorageService in a later task) ----

  static const String tokenKey = 'kiosk_token';
  static const String refreshTokenKey = 'kiosk_refresh_token';
  static const String organizationIdKey = 'kiosk_organization_id';
  static const String cachedBrandingKeyPrefix = 'kiosk_branding_';
}
