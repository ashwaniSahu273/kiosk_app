import 'package:get/get.dart';

import 'home_controller.dart';

/// Dependency wiring for the Home route (Requirement 10.7).
///
/// Registers the per-route [HomeController] lazily so it is created when the
/// Home_Screen is first resolved and disposed (its live-clock timer cancelled)
/// when the route leaves the stack. The controller resolves its collaborators
/// (`KioskRepository`, `OrganizationContext`, `NotificationService`) from the
/// permanent singletons registered during bootstrap.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(HomeController.new);
  }
}
