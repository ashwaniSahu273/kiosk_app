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
import 'prayer_format.dart';
import 'prayer_schedule_builder.dart';

/// Tab on the prayer-times destination screen.
enum PrayerTimesTab { today, daily, monthly }

/// Drives the Prayers destination screen (Requirements 5.5, 6.x).
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

  final Rx<SectionState<PrayerSchedule>> schedule =
      Rx<SectionState<PrayerSchedule>>(const SectionLoading<PrayerSchedule>());

  final Rx<PrayerTimesTab> activeTab = PrayerTimesTab.today.obs;

  /// Calendar day used by the Daily tab.
  final Rx<DateTime> selectedDay = Rx<DateTime>(DateTime.now());

  /// First day of the month shown on the Monthly tab.
  final Rx<DateTime> selectedMonth =
      Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month));

  late final Rx<DateTime> now = Rx<DateTime>(_clock());

  final Rxn<NextPrayerResult> nextPrayer = Rxn<NextPrayerResult>();

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    final DateTime clockNow = _clock();
    selectedDay.value = DateTime(clockNow.year, clockNow.month, clockNow.day);
    selectedMonth.value = DateTime(clockNow.year, clockNow.month);
    _startClock();
    load();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _clockTimer = null;
    super.onClose();
  }

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

  void selectTab(PrayerTimesTab tab) {
    activeTab.value = tab;
    _recomputeNextPrayer();
  }

  void shiftSelectedDay(int deltaDays) {
    final DateTime d = selectedDay.value;
    selectedDay.value = DateTime(d.year, d.month, d.day + deltaDays);
    _recomputeNextPrayer();
  }

  void setSelectedDay(DateTime date) {
    selectedDay.value = DateTime(date.year, date.month, date.day);
    _recomputeNextPrayer();
  }

  void shiftSelectedMonth(int deltaMonths) {
    final DateTime m = selectedMonth.value;
    selectedMonth.value = DateTime(m.year, m.month + deltaMonths);
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
  }

  PrayerSchedule? get loadedSchedule {
    final SectionState<PrayerSchedule> state = schedule.value;
    if (state is SectionLoaded<PrayerSchedule>) {
      return state.data;
    }
    if (state is SectionError<PrayerSchedule>) {
      return state.previousData;
    }
    return null;
  }

  /// Salah rows for the active tab's date.
  List<PrayerTime> get displayPrayers {
    final PrayerSchedule? template = loadedSchedule;
    if (template == null) {
      return const <PrayerTime>[];
    }
    final DateTime date = switch (activeTab.value) {
      PrayerTimesTab.today => DateTime(now.value.year, now.value.month, now.value.day),
      PrayerTimesTab.daily => selectedDay.value,
      PrayerTimesTab.monthly => DateTime(now.value.year, now.value.month, now.value.day),
    };
    return sortSalahForDisplay(
      PrayerScheduleBuilder.prayersForDate(date, template),
    );
  }

  List<PrayerDaySchedule> get monthlyDays {
    final PrayerSchedule? template = loadedSchedule;
    if (template == null) {
      return const <PrayerDaySchedule>[];
    }
    final DateTime m = selectedMonth.value;
    return PrayerScheduleBuilder.monthDays(m.year, m.month, template);
  }

  List<FridayPrayerEvent> get fridayEvents =>
      loadedSchedule?.fridayEvents ?? const <FridayPrayerEvent>[];

  bool get showFridayCard =>
      activeTab.value == PrayerTimesTab.today && isFriday(now.value);

  int get highlightedPrayerIndex =>
      indexOfHighlightedPrayer(displayPrayers, nextPrayer.value?.prayer);

  bool get hasCountdown => nextPrayer.value != null;

  String get countdownHms {
    final NextPrayerResult? result = nextPrayer.value;
    if (result == null) {
      return '';
    }
    final PrayerTime prayer = result.prayer;
    final int hour = prayer.minutesSinceMidnight ~/ 60;
    final int minute = prayer.minutesSinceMidnight % 60;
    final DateTime target = DateTime(
      now.value.year,
      now.value.month,
      now.value.day + (result.isNextDay ? 1 : 0),
      hour,
      minute,
    );
    return formatCountdownHms(now.value, target);
  }

  String get upcomingAthanTime {
    final NextPrayerResult? result = nextPrayer.value;
    if (result == null) {
      return '';
    }
    return formatTime24hWithSeconds(result.prayer.minutesSinceMidnight);
  }

  String get upcomingPrayerName => nextPrayer.value?.prayer.name ?? '';

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(_tickInterval, (_) {
      now.value = _clock();
      _recomputeNextPrayer();
    });
  }

  void _recomputeNextPrayer() {
    final PrayerSchedule? template = loadedSchedule;
    if (template == null || template.prayers.isEmpty) {
      nextPrayer.value = null;
      return;
    }
    final List<PrayerTime> prayers = switch (activeTab.value) {
      PrayerTimesTab.today => PrayerScheduleBuilder.prayersForDate(
          DateTime(now.value.year, now.value.month, now.value.day),
          template,
        ),
      PrayerTimesTab.daily => PrayerScheduleBuilder.prayersForDate(
          selectedDay.value,
          template,
        ),
      PrayerTimesTab.monthly => PrayerScheduleBuilder.prayersForDate(
          DateTime(now.value.year, now.value.month, now.value.day),
          template,
        ),
    };
    nextPrayer.value = NextPrayerResolver.resolve(prayers, now.value);
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
