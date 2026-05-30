import 'package:get/get.dart';

import 'donate_controller.dart';

/// Dependency wiring for the Donate route (Requirement 10.7).
///
/// Registers the per-route [DonateController] lazily so it is created when the
/// Donate destination is resolved and disposed when the route leaves the stack.
/// The controller resolves its collaborators (`KioskRepository`,
/// `OrganizationContext`, `NotificationService`) from the permanent singletons
/// registered during bootstrap, and reads any `DonationCategory` route argument
/// passed from a Home "Donate" control via `Get.arguments`.
class DonateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DonateController>(DonateController.new);
  }
}
