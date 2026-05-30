import '../../config/app_constants.dart';

/// Centralized endpoint paths and network timing constants for the
/// [ApiClient]. Paths are relative to [baseUrl] and are joined as
/// `baseUrl + endpoint`.
class ApiEndpoints {
  const ApiEndpoints._();

  /// Base URL for all outbound requests. Trailing slash is intentional so
  /// endpoint constants below can be appended directly.
  static const String baseUrl = 'https://api.kiosk.example.com/v1/';

  // ---- Auth ----

  /// Administrator login (email + password).
  static const String login = 'auth/login';

  /// Single-attempt token refresh using the persisted refresh token.
  static const String refreshToken = 'auth/refresh';

  // ---- Organization-scoped content ----

  static const String organization = 'organization';
  static const String branding = 'organization/branding';
  static const String prayerSchedule = 'organization/prayers';
  static const String programs = 'organization/programs';
  static const String donationCategories = 'organization/donations';

  // ---- Timeouts (re-exported from AppConstants for convenient access) ----

  /// Timeout for content/auth requests (30s).
  static const Duration contentTimeout = AppConstants.contentTimeout;

  /// Timeout for the single token-refresh attempt (10s).
  static const Duration refreshTimeout = AppConstants.refreshTimeout;
}
