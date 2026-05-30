import 'dart:async';

import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../core/data/kiosk_repository.dart';
import '../../core/data/models/models.dart';
import '../../core/network/api_result.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/organization_context.dart';
import 'next_prayer_resolver.dart';
import 'section_state.dart';

/// The four required Home_Screen content sections, each loaded and retried
/// independently (Requirements 3.5, 3.6, 12.3, 12.4).
enum HomeSection {
  /// The day's prayer schedule that drives the Next Prayer card.
  prayerSchedule,

  /// The Available Programs list.
  programs,

  /// The Donation Categories list.
  donations,

  /// The Scan-to-Donate QR (the active organization's donation URL).
  qr,
}

/// Drives the Home_Screen with **per-section independent state**.
///
/// Each of the four required Home elements (prayer schedule, programs,
/// donations, QR) owns its own [SectionState] observable, is loaded
/// independently via the [KioskRepository] scoped to the active organization,
/// and can be retried on its own ([retrySection]) without disturbing the
/// others. A failure in one section never blocks another (Requirements 3.5,
/// 3.6).
///
/// Loading rules per section:
/// * starts in [SectionLoading] (the shared shimmer) when no content is yet
///   displayed (Req 13.1);
/// * transitions to [SectionLoaded] on a successful non-empty result (13.3);
/// * transitions to [SectionEmpty] on a successful empty result (3.5, 13.4);
/// * transitions to [SectionError] on failure or a 30s timeout, **retaining**
///   any previously loaded content and surfacing a [NotificationService] error
///   (Req 3.6, 13.4).
///
/// A live clock [Timer] ticks every second (well within the "at least every
/// 60s" requirement) updating [now] and recomputing [nextPrayer] from the
/// loaded schedule via [NextPrayerResolver]; the countdown therefore rolls over
/// to the next prayer automatically when the current time crosses a prayer time
/// (Requirements 6.3, 6.6). An empty/failed schedule yields no countdown
/// (Req 6.5).
///
/// Home gating (Requirements 12.3, 12.4): the four content sections are treated
/// as **required** Home elements. [hasUnresolvedRequiredError] is true while any
/// required section is in an error state, so the view can hide all elements
/// until every loading error is resolved while still showing each errored
/// element's error message and retry control.
class HomeController extends GetxController {
  HomeController({
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

  // ---- Per-section observable state ----

  /// State of the prayer schedule section; its loaded payload is the day's
  /// [PrayerSchedule] (the derived [nextPrayer] is exposed separately).
  final Rx<SectionState<PrayerSchedule>> prayerSchedule =
      Rx<SectionState<PrayerSchedule>>(const SectionLoading<PrayerSchedule>());

  /// State of the Available Programs section.
  final Rx<SectionState<List<Program>>> programs =
      Rx<SectionState<List<Program>>>(const SectionLoading<List<Program>>());

  /// State of the Donation Categories section.
  final Rx<SectionState<List<DonationCategory>>> donations =
      Rx<SectionState<List<DonationCategory>>>(
    const SectionLoading<List<DonationCategory>>(),
  );

  /// State of the Scan-to-Donate QR section; its loaded payload is the active
  /// organization's donation URL. An absent URL resolves to [SectionEmpty]
  /// (the unavailable state, Req 9.2) rather than an error.
  final Rx<SectionState<String>> qr =
      Rx<SectionState<String>>(const SectionLoading<String>());

  // ---- Live clock / countdown ----

  /// The current time, refreshed every tick. Exposed so the header/cards can
  /// render a live clock and so the countdown recomputes (Req 5.2, 6.3).
  late final Rx<DateTime> now = Rx<DateTime>(_clock());

  /// The resolved next upcoming prayer and its countdown, or null when the
  /// schedule is empty/unavailable (Req 6.5).
  final Rxn<NextPrayerResult> nextPrayer = Rxn<NextPrayerResult>();

  Timer? _clockTimer;

  // ---- Lifecycle ----

  @override
  void onInit() {
    super.onInit();
    _startClock();
    loadAll();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _clockTimer = null;
    super.onClose();
  }

  // ---- Loading ----

  /// Loads every section independently and concurrently (Requirements 3.5,
  /// 3.6). Each section manages its own state and never throws, so one
  /// section's failure cannot abort another's load.
  Future<void> loadAll() async {
    await Future.wait<void>(<Future<void>>[
      _loadPrayerSchedule(),
      _loadPrograms(),
      _loadDonations(),
      _loadQr(),
    ]);
  }

  /// Re-issues the request for [section] only, leaving the other sections
  /// untouched (Requirements 3.6, 12.4).
  Future<void> retrySection(HomeSection section) {
    switch (section) {
      case HomeSection.prayerSchedule:
        return _loadPrayerSchedule();
      case HomeSection.programs:
        return _loadPrograms();
      case HomeSection.donations:
        return _loadDonations();
      case HomeSection.qr:
        return _loadQr();
    }
  }

  Future<void> _loadPrayerSchedule() async {
    final String? orgId = _activeOrganizationId();
    final PrayerSchedule? retained = _retained<PrayerSchedule>(prayerSchedule);
    if (orgId == null) {
      _failSection(prayerSchedule, _noOrganizationMessage, retained);
      _recomputeNextPrayer();
      return;
    }

    _beginLoading(prayerSchedule, retained);

    final ApiResult<PrayerSchedule> result = await _repository
        .fetchPrayerSchedule(orgId)
        .timeout(_contentTimeout, onTimeout: () => _timeoutResult());

    if (!result.success || result.data == null) {
      _failSection(prayerSchedule, _messageOf(result), retained);
      _recomputeNextPrayer();
      return;
    }

    final PrayerSchedule schedule = result.data!;
    // An empty schedule is a valid, non-error result that drives the empty
    // state with no countdown (Req 6.5).
    if (schedule.prayers.isEmpty) {
      prayerSchedule.value = const SectionEmpty<PrayerSchedule>();
    } else {
      prayerSchedule.value = SectionLoaded<PrayerSchedule>(schedule);
    }
    _recomputeNextPrayer();
  }

  Future<void> _loadPrograms() async {
    final String? orgId = _activeOrganizationId();
    final List<Program>? retained = _retained<List<Program>>(programs);
    if (orgId == null) {
      _failSection(programs, _noOrganizationMessage, retained);
      return;
    }

    _beginLoading(programs, retained);

    final ApiResult<List<Program>> result = await _repository
        .fetchPrograms(orgId)
        .timeout(_contentTimeout, onTimeout: () => _timeoutResult());

    if (!result.success || result.data == null) {
      _failSection(programs, _messageOf(result), retained);
      return;
    }

    final List<Program> items = result.data!;
    programs.value = items.isEmpty
        ? const SectionEmpty<List<Program>>()
        : SectionLoaded<List<Program>>(items);
  }

  Future<void> _loadDonations() async {
    final String? orgId = _activeOrganizationId();
    final List<DonationCategory>? retained =
        _retained<List<DonationCategory>>(donations);
    if (orgId == null) {
      _failSection(donations, _noOrganizationMessage, retained);
      return;
    }

    _beginLoading(donations, retained);

    final ApiResult<List<DonationCategory>> result = await _repository
        .fetchDonationCategories(orgId)
        .timeout(_contentTimeout, onTimeout: () => _timeoutResult());

    if (!result.success || result.data == null) {
      _failSection(donations, _messageOf(result), retained);
      return;
    }

    final List<DonationCategory> items = result.data!;
    donations.value = items.isEmpty
        ? const SectionEmpty<List<DonationCategory>>()
        : SectionLoaded<List<DonationCategory>>(items);
  }

  Future<void> _loadQr() async {
    final String? orgId = _activeOrganizationId();
    final String? retained = _retained<String>(qr);
    if (orgId == null) {
      _failSection(qr, _noOrganizationMessage, retained);
      return;
    }

    _beginLoading(qr, retained);

    final ApiResult<BrandingProfile> result = await _repository
        .fetchBranding(orgId)
        .timeout(_contentTimeout, onTimeout: () => _timeoutResult());

    if (!result.success || result.data == null) {
      _failSection(qr, _messageOf(result), retained);
      return;
    }

    final String? url = result.data!.donationUrl;
    // A missing/blank donation URL is the unavailable state, not an error
    // (Req 9.2): no QR is rendered and the section shows its empty/unavailable
    // message.
    if (url == null || url.trim().isEmpty) {
      qr.value = const SectionEmpty<String>();
    } else {
      qr.value = SectionLoaded<String>(url);
    }
  }

  // ---- Countdown ----

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _onTick() {
    now.value = _clock();
    _recomputeNextPrayer();
  }

  /// Recomputes [nextPrayer] from the currently displayed schedule (loaded, or
  /// retained behind an error) relative to [now].
  ///
  /// Yields null when there is no schedule or the schedule has no prayers, so
  /// the empty/unavailable state shows no countdown (Req 6.5). Because the
  /// resolver is evaluated against the live [now], the next prayer recomputes
  /// automatically as time crosses a scheduled prayer (Req 6.6).
  void _recomputeNextPrayer() {
    final PrayerSchedule? schedule = _displayedSchedule();
    if (schedule == null || schedule.prayers.isEmpty) {
      nextPrayer.value = null;
      return;
    }
    nextPrayer.value =
        NextPrayerResolver.resolve(schedule.prayers, now.value);
  }

  /// The schedule currently visible to the user: the loaded one, or the content
  /// retained behind an error (Req 3.6). Null when none is available.
  PrayerSchedule? _displayedSchedule() {
    final SectionState<PrayerSchedule> state = prayerSchedule.value;
    if (state is SectionLoaded<PrayerSchedule>) {
      return state.data;
    }
    if (state is SectionError<PrayerSchedule>) {
      return state.previousData;
    }
    return null;
  }

  /// Human-readable countdown to the next prayer in hours and minutes
  /// (Req 6.3), or an empty string when no countdown applies.
  String get countdownLabel {
    final NextPrayerResult? result = nextPrayer.value;
    if (result == null) {
      return '';
    }
    final Duration d = result.countdown;
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Whether a live countdown is currently available (Req 6.5).
  bool get hasCountdown => nextPrayer.value != null;

  // ---- Home gating (Req 12.3, 12.4) ----

  /// True while at least one required Home element has an unresolved loading
  /// error. The view hides all elements while this holds, yet each errored
  /// element still shows its error message and retry control (Req 12.3, 12.4).
  bool get hasUnresolvedRequiredError =>
      prayerSchedule.value is SectionError ||
      programs.value is SectionError ||
      donations.value is SectionError ||
      qr.value is SectionError;

  /// True when no required Home element has an unresolved error, so the view
  /// may reveal all resolved elements (Req 12.3).
  bool get allRequiredResolved => !hasUnresolvedRequiredError;

  // ---- Helpers ----

  String? _activeOrganizationId() => _organizationContext.organizationId;

  /// Moves [section] into [SectionLoading] (showing the shimmer) only when no
  /// content is currently displayed; when content exists it stays visible
  /// during the in-flight reload so the shimmer is not shown over real content
  /// (Req 13.1).
  void _beginLoading<T>(Rx<SectionState<T>> section, T? retained) {
    if (retained == null) {
      section.value = SectionLoading<T>();
    }
  }

  /// Moves [section] into [SectionError] retaining [retained] content and
  /// surfaces the error through the [NotificationService] (Req 3.6).
  void _failSection<T>(
    Rx<SectionState<T>> section,
    String message,
    T? retained,
  ) {
    section.value = SectionError<T>(message, previousData: retained);
    _notificationService.error(message);
  }

  /// Extracts the content currently held by [section] (loaded data, or the data
  /// retained behind an error), or null when none is available.
  T? _retained<T>(Rx<SectionState<T>> section) {
    final SectionState<T> state = section.value;
    if (state is SectionLoaded<T>) {
      return state.data;
    }
    if (state is SectionError<T>) {
      return state.previousData;
    }
    return null;
  }

  String _messageOf<T>(ApiResult<T> result) =>
      result.message ?? _defaultErrorMessage;

  ApiResult<T> _timeoutResult<T>() =>
      ApiResult<T>.failure(408, _timeoutMessage);

  static const String _defaultErrorMessage =
      'Content could not be loaded. Please try again.';
  static const String _timeoutMessage =
      'Content could not be loaded. The request timed out.';
  static const String _noOrganizationMessage =
      'No active organization. Please sign in again.';
}
