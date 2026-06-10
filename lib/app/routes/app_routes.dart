/// Centralized route-name constants for the kiosk app (Requirement 10.7).
///
/// All navigation targets are referenced through these constants so route
/// names live in exactly one place and stay consistent across the routing
/// table ([AppPages]), the [AuthMiddleware] redirect target, and every
/// `Get.toNamed` / `Get.offAllNamed` call site.
class AppRoutes {
  const AppRoutes._();

  /// The administrator login screen (unprotected).
  static const String login = '/login';

  /// The kiosk Home_Screen (protected).
  static const String home = '/home';

  /// The Donate destination (protected).
  static const String donate = '/donate';

  /// The Prayers destination (protected).
  static const String prayers = '/prayers';

  /// The Programs destination (protected).
  static const String programs = '/programs';

  /// The Events destination (protected).
  static const String events = '/events';
}
