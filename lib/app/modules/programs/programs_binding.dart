import 'package:get/get.dart';

import 'programs_controller.dart';

/// Dependency wiring for the Programs route (Requirement 10.7).
///
/// Registers the per-route [ProgramsController] lazily so it is created when
/// the Programs destination is resolved and disposed when the route leaves the
/// stack. The controller resolves its collaborators (`KioskRepository`,
/// `OrganizationContext`, `NotificationService`) from the permanent singletons
/// registered during bootstrap, and reads any `Program` route argument passed
/// from a Home "Register" control via `Get.arguments`.
class ProgramsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProgramsController>(ProgramsController.new);
  }
}
