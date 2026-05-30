import 'package:get/get.dart';

import 'login_controller.dart';

/// Dependency wiring for the authentication (login) route (Requirement 10.7).
///
/// Lazily provides the [LoginController] when the login route is entered. The
/// controller resolves its collaborators — the permanent [AuthService] and
/// [NotificationService] singletons registered during bootstrap — via
/// `Get.find` internally, so this binding only needs to register the
/// per-route controller.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(LoginController.new);
  }
}
