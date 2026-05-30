import 'dart:async';

import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../core/data/kiosk_repository.dart';
import '../../core/data/models/models.dart';
import '../../core/network/api_result.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/organization_context.dart';
import '../home/next_prayer_resolver.dart';
import '../home/section_state.dart';

/// Drives the Prayers destination screen (Requirements 5.5, 6.x).
///
/// Loads the active organization's [PrayerSchedule] (scoped via the
/// [KioskRepository] to [OrganizationContext.organizationId]) into a
/// [SectionState] the view binds to, and runs a live clock that recomputes the
/// next upcoming prayer and countdown from the loaded schedule via
/// [NextPrayerResolver] (so the countdown ticks and rolls over automatically,
/// Requirements 6.3, 6.6).
///
/// An empty or failed schedule yields no countdown (Req 6.5); a failure shows
/// the error message with a retry control and retains any previously loaded
/// schedule (Req 3.6).
class PrayersController extends GetxController {
  PrayersController({
    KioskRepository? repository,
    OrganizationContext? organizationContext,
    NotificationService? notificationService,
    DateTime Function()? clock,
    Duration tickInterval = const Duration(seconds: 1),
    Duration contentTimeout = AppConstants.contentTimeout,
  })  : _injectedRepository = repository,
        _injectedOrganizationContext = organizationContext,
        _injectedNotificationService = notificationService,
        _clock = clock ?? DateTime.now,
        _tickInterval = tickInterval,
        _contentTimeout = contentTimeout;

  final KioskRepository? _injectedRepository;
  final OrganizationContext? _injectedOrganizationContext;
  final NotificationService? _injectedNotificationService;
  final DateTime Function() _clock;
  final Duration _tickInterval;
  final Duration _contentTimeout;

  KioskRepository get _repository =>
      _injectedRepository ?? Get.find<KioskRepository>();

  OrganizationContext get _organizationContext =>
      _injectedOrganizationContext ?? Get.find<OrganizationContext>();

  NotificationService get _notificationService =>
      _injectedNotificationService ?? Get.find<NotificationService>();

  /// State of the prayer schedule for the active organization.
  final Rx<SectionState<PrayerSchedule>> schedule =
      Rx<SectionState<PrayerSchedule>>(const SectionLoading<PrayerSchedule>());

  /// The current time, refreshed every tick so the countdown stays live
  /// (Req 6.3).
  late final Rx<DateTime> now = Rx<DateTime>(_clock());

  /// The resolved next upcoming prayer and its countdown, or null when the
  /// schedule is empty/unavailable (Req 6.5).
  final Rxn<NextPrayerResult> nextPrayer = Rxn<NextPrayerResult>();

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    _startClock();
    load();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _clockTimer = null;
    super.onClose();
  }

  /// Loads the active organization's prayer schedule, scoped to the active org
  /// id.
  Future<void> load() async {
    final String? orgId = _organizationContext.organizationId;
    if (orgId == null) {
      _fail(_noOrganizationMessage);
      _recomputeNextPrayer();
      return;
    }

    if (_retained() == null) {
      schedule.value = const SectionLoading<PrayerSchedule>();
    }

    final ApiResult<PrayerSchedule> result = await _repository
        .fetchPrayerSchedule(orgId)
        .timeout(_contentTimeout, onTimeout: _timeoutResult);

    if (!result.success || result.data == null) {
      _fail(result.message ?? _defaultErrorMessage);
      _recomputeNextPrayer();
      return;
    }

    final PrayerSchedule loaded = result.data!;
    schedule.value = loaded.prayers.isEmpty
        ? const SectionEmpty<PrayerSchedule>()
        : SectionLoaded<PrayerSchedule>(loaded);
    _recomputeNextPrayer();
  }

  /// Human-readable countdown to the next prayer in hours and minutes
  /// (Req 6.3), or an empty string when no countdown applies.
  String get countdownLabel {
    final NextPrayerResult? result = nextPrayer.value;
    if (result == null) {
      return '';
    }
    final Duration d = result.countdown;
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  /// Whether a live countdown is currently available (Req 6.5).
  bool get hasCountdown => nextPrayer.value != null;

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(_tickInterval, (_) {
      now.value = _clock();
      _recomputeNextPrayer();
    });
  }

  void _recomputeNextPrayer() {
    final PrayerSchedule? displayed = _displayedSchedule();
    if (displayed == null || displayed.prayers.isEmpty) {
      nextPrayer.value = null;
      return;
    }
    nextPrayer.value =
        NextPrayerResolver.resolve(displayed.prayers, now.value);
  }

  /// The schedule currently visible to the user: the loaded one, or the content
  /// retained behind an error (Req 3.6). Null when none is available.
  PrayerSchedule? _displayedSchedule() {
    final SectionState<PrayerSchedule> state = schedule.value;
    if (state is SectionLoaded<PrayerSchedule>) {
      return state.data;
    }
    if (state is SectionError<PrayerSchedule>) {
      return state.previousData;
    }
    return null;
  }

  PrayerSchedule? _retained() {
    final SectionState<PrayerSchedule> state = schedule.value;
    if (state is SectionLoaded<PrayerSchedule>) {
      return state.data;
    }
    if (state is SectionError<PrayerSchedule>) {
      return state.previousData;
    }
    return null;
  }

  void _fail(String message) {
    schedule.value =
        SectionError<PrayerSchedule>(message, previousData: _retained());
    _notificationService.error(message);
  }

  ApiResult<PrayerSchedule> _timeoutResult() =>
      ApiResult<PrayerSchedule>.failure(408, _timeoutMessage);

  static const String _defaultErrorMessage =
      'Prayer schedule could not be loaded. Please try again.';
  static const String _timeoutMessage =
      'Prayer schedule could not be loaded. The request timed out.';
  static const String _noOrganizationMessage =
      'No active organization. Please sign in again.';
}
