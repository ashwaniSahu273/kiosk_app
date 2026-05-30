import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../core/data/kiosk_repository.dart';
import '../../core/data/models/models.dart';
import '../../core/network/api_result.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/organization_context.dart';
import '../home/section_state.dart';

/// Drives the Donate destination screen (Requirement 8.2).
///
/// Loads the active organization's [DonationCategory] list (scoped via the
/// [KioskRepository] to [OrganizationContext.organizationId]) into a
/// [SectionState] the view binds to, and tracks an optional
/// [selectedCategory] supplied as the route argument when the screen is reached
/// from a Home "Donate" control.
///
/// Navigation contract:
/// * reached via a Donate control → `Get.arguments` carries the chosen
///   [DonationCategory]; [selectedCategory] is set so the view opens that
///   category's donation entry point directly;
/// * reached via the sidebar → no argument; the view lists every category, each
///   with a Donate action that calls [selectCategory] to open the donation
///   entry point for that category.
class DonateController extends GetxController {
  DonateController({
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

  /// Preset donation amounts (in whole currency units) offered in the donation
  /// entry point.
  static const List<int> presetAmounts = <int>[10, 25, 50, 100];

  /// State of the Donation Categories list for the active organization.
  final Rx<SectionState<List<DonationCategory>>> categories =
      Rx<SectionState<List<DonationCategory>>>(
    const SectionLoading<List<DonationCategory>>(),
  );

  /// The category whose donation entry point is currently shown, or null when
  /// the screen is showing the full list (sidebar entry).
  final Rxn<DonationCategory> selectedCategory = Rxn<DonationCategory>();

  @override
  void onInit() {
    super.onInit();
    final Object? argument = _resolveArgument();
    if (argument is DonationCategory) {
      selectedCategory.value = argument;
    }
    load();
  }

  /// The route argument the controller was launched with. Prefers the injected
  /// value (tests); otherwise reads `Get.arguments`.
  Object? _resolveArgument() => _initialArgument ?? Get.arguments;

  /// Loads the active organization's donation categories, scoped to the active
  /// org id.
  Future<void> load() async {
    final String? orgId = _organizationContext.organizationId;
    if (orgId == null) {
      _fail(_noOrganizationMessage);
      return;
    }

    if (_retained() == null) {
      categories.value = const SectionLoading<List<DonationCategory>>();
    }

    final ApiResult<List<DonationCategory>> result = await _repository
        .fetchDonationCategories(orgId)
        .timeout(_contentTimeout, onTimeout: _timeoutResult);

    if (!result.success || result.data == null) {
      _fail(result.message ?? _defaultErrorMessage);
      return;
    }

    final List<DonationCategory> items = result.data!;
    categories.value = items.isEmpty
        ? const SectionEmpty<List<DonationCategory>>()
        : SectionLoaded<List<DonationCategory>>(items);
  }

  /// Opens the donation entry point for [category] (Requirement 8.2).
  void selectCategory(DonationCategory category) {
    selectedCategory.value = category;
  }

  /// Returns from a category's donation entry point to the full list.
  void clearSelection() {
    selectedCategory.value = null;
  }

  /// Confirms a donation of [amount] toward the currently selected category.
  ///
  /// This is the demo donation submit: it surfaces a success confirmation
  /// through the [NotificationService] and returns to the category list.
  void confirmDonation(int amount) {
    final DonationCategory? category = selectedCategory.value;
    final String categoryName = category?.name ?? 'your selected fund';
    _notificationService.success(
      'Thank you! A \$$amount donation to $categoryName was recorded.',
    );
    clearSelection();
  }

  List<DonationCategory>? _retained() {
    final SectionState<List<DonationCategory>> state = categories.value;
    if (state is SectionLoaded<List<DonationCategory>>) {
      return state.data;
    }
    if (state is SectionError<List<DonationCategory>>) {
      return state.previousData;
    }
    return null;
  }

  void _fail(String message) {
    categories.value = SectionError<List<DonationCategory>>(
      message,
      previousData: _retained(),
    );
    _notificationService.error(message);
  }

  ApiResult<List<DonationCategory>> _timeoutResult() =>
      ApiResult<List<DonationCategory>>.failure(408, _timeoutMessage);

  static const String _defaultErrorMessage =
      'Donation categories could not be loaded. Please try again.';
  static const String _timeoutMessage =
      'Donation categories could not be loaded. The request timed out.';
  static const String _noOrganizationMessage =
      'No active organization. Please sign in again.';
}
