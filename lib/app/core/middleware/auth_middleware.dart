import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_service.dart';
import '../../routes/app_routes.dart';

/// Route guard for protected kiosk routes (Requirement 2.3).
///
/// Attached to every protected `GetPage` (Home, Donate, Prayers, Programs).
/// Before such a route is shown, [redirect] consults the [AuthService]: when no
/// complete session exists the navigation is redirected to the login screen;
/// when a session exists the navigation is allowed (no redirect).
///
/// This is a session-existence check only — it does not validate the token with
/// the backend. Token expiry is handled separately by the `ApiClient`'s
/// 401 -> single-refresh -> retry flow and `AuthService.refreshSession`.
///
/// The [AuthService] is resolved lazily (preferring an injected instance) so
/// the guard works once the bootstrap has registered the permanent singleton.
class AuthMiddleware extends GetMiddleware {
  AuthMiddleware({AuthService? authService}) : _injectedAuthService = authService;

  final AuthService? _injectedAuthService;

  AuthService get _authService =>
      _injectedAuthService ??
      (Get.isRegistered<AuthService>() ? Get.find<AuthService>() : _missing());

  AuthService _missing() {
    throw StateError(
      'AuthMiddleware requires a registered AuthService. Ensure the app '
      'bootstrap registers AuthService before navigation begins.',
    );
  }

  @override
  RouteSettings? redirect(String? route) {
    // Allow the navigation when a complete session exists; otherwise redirect
    // the unauthenticated request to the login screen (Requirement 2.3).
    if (_authService.hasCompleteSession) {
      return null;
    }
    return const RouteSettings(name: AppRoutes.login);
  }
}
