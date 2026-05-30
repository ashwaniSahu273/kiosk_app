import 'package:get/get.dart';

import 'prayers_controller.dart';

/// Dependency wiring for the Prayers route (Requirement 10.7).
///
/// Registers the per-route [PrayersController] lazily so it is created when the
/// Prayers destination is resolved and disposed (its live-clock timer
/// cancelled) when the route leaves the stack. The controller resolves its
/// collaborators (`KioskRepository`, `OrganizationContext`,
/// `NotificationService`) from the permanent singletons registered during
/// bootstrap.
class PrayersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrayersController>(PrayersController.new);
  }
}
