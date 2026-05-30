import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../core/data/kiosk_repository.dart';
import '../../core/data/models/models.dart';
import '../../core/network/api_result.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/organization_context.dart';
import '../home/section_state.dart';

/// Drives the Programs destination screen (Requirement 7.2).
///
/// Loads the active organization's [Program] list (scoped via the
/// [KioskRepository] to [OrganizationContext.organizationId]) into a
/// [SectionState] the view binds to, and tracks an optional [selectedProgram]
/// supplied as the route argument when the screen is reached from a Home
/// "Register" control.
///
/// Navigation contract:
/// * reached via a Register control → `Get.arguments` carries the chosen
///   [Program]; [selectedProgram] is set so the view opens that program's
///   registration entry point directly;
/// * reached via the sidebar → no argument; the view lists every program, each
///   with a Register action that calls [selectProgram] to open the
///   registration entry point for that program.
///
/// The list always loads (even when arriving with a selection) so the
/// registration panel's "back to all programs" path has data to show without a
/// reload.
class ProgramsController extends GetxController {
  ProgramsController({
    KioskRepository? repository,
    OrganizationContext? organizationContext,
    NotificationService? notificationService,
    Object? initialArgument,
    Duration contentTimeout = AppConstants.contentTimeout,
  })  : _injectedRepository = repository,
        _injectedOrganizationContext = organizationContext,
        _injectedNotificationService = notificationService,
        _initialArgument = initialArgument,
        _contentTimeout = contentTimeout;

  final KioskRepository? _injectedRepository;
  final OrganizationContext? _injectedOrganizationContext;
  final NotificationService? _injectedNotificationService;
  final Object? _initialArgument;
  final Duration _contentTimeout;

  KioskRepository get _repository =>
      _injectedRepository ?? Get.find<KioskRepository>();

  OrganizationContext get _organizationContext =>
      _injectedOrganizationContext ?? Get.find<OrganizationContext>();

  NotificationService get _notificationService =>
      _injectedNotificationService ?? Get.find<NotificationService>();

  /// State of the Available Programs list for the active organization.
  final Rx<SectionState<List<Program>>> programs =
      Rx<SectionState<List<Program>>>(const SectionLoading<List<Program>>());

  /// The program whose registration entry point is currently shown, or null
  /// when the screen is showing the full list (sidebar entry).
  final Rxn<Program> selectedProgram = Rxn<Program>();

  @override
  void onInit() {
    super.onInit();
    final Object? argument = _resolveArgument();
    if (argument is Program) {
      selectedProgram.value = argument;
    }
    load();
  }

  /// The route argument the controller was launched with. Prefers the injected
  /// value (tests); otherwise reads `Get.arguments`.
  Object? _resolveArgument() => _initialArgument ?? Get.arguments;

  /// Loads the active organization's programs, scoped to the active org id.
  Future<void> load() async {
    final String? orgId = _organizationContext.organizationId;
    if (orgId == null) {
      _fail(_noOrganizationMessage);
      return;
    }

    if (_retained() == null) {
      programs.value = const SectionLoading<List<Program>>();
    }

    final ApiResult<List<Program>> result = await _repository
        .fetchPrograms(orgId)
        .timeout(_contentTimeout, onTimeout: _timeoutResult);

    if (!result.success || result.data == null) {
      _fail(result.message ?? _defaultErrorMessage);
      return;
    }

    final List<Program> items = result.data!;
    programs.value = items.isEmpty
        ? const SectionEmpty<List<Program>>()
        : SectionLoaded<List<Program>>(items);
  }

  /// Opens the registration entry point for [program] (Requirement 7.2).
  void selectProgram(Program program) {
    selectedProgram.value = program;
  }

  /// Returns from a program's registration entry point to the full list.
  void clearSelection() {
    selectedProgram.value = null;
  }

  /// Confirms a registration for the currently selected program.
  ///
  /// This is the demo registration submit: it surfaces a success confirmation
  /// through the [NotificationService] and returns to the program list.
  void confirmRegistration({required String name, required String email}) {
    final Program? program = selectedProgram.value;
    final String programName = program?.name ?? 'the program';
    _notificationService.success(
      'Registered $name for $programName. A confirmation was sent to $email.',
    );
    clearSelection();
  }

  List<Program>? _retained() {
    final SectionState<List<Program>> state = programs.value;
    if (state is SectionLoaded<List<Program>>) {
      return state.data;
    }
    if (state is SectionError<List<Program>>) {
      return state.previousData;
    }
    return null;
  }

  void _fail(String message) {
    programs.value =
        SectionError<List<Program>>(message, previousData: _retained());
    _notificationService.error(message);
  }

  ApiResult<List<Program>> _timeoutResult() =>
      ApiResult<List<Program>>.failure(408, _timeoutMessage);

  static const String _defaultErrorMessage =
      'Programs could not be loaded. Please try again.';
  static const String _timeoutMessage =
      'Programs could not be loaded. The request timed out.';
  static const String _noOrganizationMessage =
      'No active organization. Please sign in again.';
}
