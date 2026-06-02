import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_result.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/data/models/models.dart';
import 'auth_service.dart';
import 'login_validator.dart';

/// Drives the administrator login form (Requirement 1).
///
/// Owns the email/password [TextEditingController]s and the observable form
/// state the [LoginView] binds to:
///
/// * [emailError] / [passwordError] — per-field inline validation messages,
///   set on a failed [submit] and cleared as the user edits (Requirement 1.6).
/// * [isSubmitting] — true while an authentication request is in flight, which
///   the view uses to show the button spinner and disable the submit control
///   (Requirement 1.7).
///
/// Validation is delegated to the pure [LoginValidator]; authentication and
/// persistence are delegated to the [AuthService]. On success the controller
/// navigates to the home screen; on failure it surfaces the endpoint's message
/// through the [NotificationService] and leaves the user on the login screen
/// with nothing persisted (Requirements 1.5, 1.8). Transient messages always go
/// through the [NotificationService] — never `Get.snackbar` directly.
class LoginController extends GetxController {
  LoginController({
    AuthService? authService,
    NotificationService? notificationService,
  })  : _injectedAuthService = authService,
        _injectedNotificationService = notificationService;

  /// Route the controller navigates to after a successful sign-in.
  ///
  /// Kept as a plain constant so this module does not depend on the routing
  /// layer (defined in a later task); the matching route is registered there.
  static const String homeRoute = '/home';

  final AuthService? _injectedAuthService;
  final NotificationService? _injectedNotificationService;

  /// Editing controller for the email field.
  final TextEditingController emailController = TextEditingController();

  /// Editing controller for the password field.
  final TextEditingController passwordController = TextEditingController();

  /// Inline validation message for the email field, or null when valid.
  final RxnString emailError = RxnString();

  /// Inline validation message for the password field, or null when valid.
  final RxnString passwordError = RxnString();

  /// Whether the password field is currently obscured.
  final RxBool isPasswordObscured = true.obs;

  /// Whether an authentication request is currently in progress.
  ///
  /// While true the view shows a loading indicator and disables the submit
  /// control (Requirement 1.7).
  final RxBool isSubmitting = false.obs;

  /// The [AuthService] singleton, resolved lazily so the controller can also be
  /// constructed with an explicit instance.
  AuthService get _authService => _injectedAuthService ?? Get.find<AuthService>();

  /// The [NotificationService] singleton used for all transient messaging.
  NotificationService get _notificationService =>
      _injectedNotificationService ?? Get.find<NotificationService>();

  /// Clears the email field error (call as the user edits the field).
  void onEmailChanged(String _) {
    if (emailError.value != null) {
      emailError.value = null;
    }
  }

  /// Clears the password field error (call as the user edits the field).
  void onPasswordChanged(String _) {
    if (passwordError.value != null) {
      passwordError.value = null;
    }
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  /// Validates the form and, when valid, authenticates the administrator.
  ///
  /// Per-field validation runs first; if either field is invalid the matching
  /// inline message is set and the authentication request is withheld
  /// (Requirement 1.6). When both fields are valid, [isSubmitting] is raised to
  /// disable the submit control and show the spinner (Requirement 1.7), and
  /// [AuthService.login] is invoked (its own 30s timeout applies). On success
  /// the app navigates to the home screen (Requirement 1.4); on failure or
  /// timeout the endpoint's message is surfaced via the [NotificationService],
  /// the user stays on the login screen, and nothing is persisted (Requirements
  /// 1.5, 1.8). [isSubmitting] is always cleared in the `finally` block so the
  /// control is re-enabled regardless of outcome.
  Future<void> submit() async {
    // A submit already in flight must not be issued twice.
    if (isSubmitting.value) {
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    final String? emailValidation = LoginValidator.validateEmail(email);
    final String? passwordValidation =
        LoginValidator.validatePassword(password);
    emailError.value = emailValidation;
    passwordError.value = passwordValidation;

    // Withhold the request while any field is invalid (Requirement 1.6).
    if (emailValidation != null || passwordValidation != null) {
      return;
    }

    isSubmitting.value = true;
    try {
      final ApiResult<Session> result =
          await _authService.login(email, password);

      if (result.success && result.data != null) {
        // Success: navigate to the home screen (Requirement 1.4).
        Get.offAllNamed(homeRoute);
        return;
      }

      // Failure/timeout/unreachable: surface the message, stay on login, and
      // persist nothing (handled by AuthService) (Requirements 1.5, 1.8).
      _notificationService.error(
        result.message ?? 'Sign-in failed. Please try again.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
