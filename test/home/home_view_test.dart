// Widget tests for HomeView (Task 14.3).
//
// Validates:
//   Req 5.4, 5.7  — all four section cards visible at 1024×600
//   Req 13.1, 13.3 — ShimmerLoader shown while loading, replaced when loaded
//   Req 3.5        — empty-state message shown for empty sections
//   Req 3.6, 13.4  — error state with Retry button shown for errored sections
//   Req 12.3       — full-screen error state shown when any section has error

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kiosk_app/app/core/data/models/models.dart';
import 'package:kiosk_app/app/core/notifications/notification_service.dart';
import 'package:kiosk_app/app/core/services/organization_context.dart';
import 'package:kiosk_app/app/core/services/theme_engine.dart';
import 'package:kiosk_app/app/modules/home/home_controller.dart';
import 'package:kiosk_app/app/modules/home/home_view.dart';
import 'package:kiosk_app/app/modules/home/section_state.dart';
import 'package:kiosk_app/app/widgets/shimmer_loader.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal [OrganizationContext] that always returns a fixed organization id
/// and branding, without needing [StorageService] or [KioskRepository].
class _FakeOrganizationContext extends OrganizationContext {
  _FakeOrganizationContext() : super();

  @override
  String? get organizationId => 'test-org';

  @override
  BrandingProfile? get branding => const BrandingProfile(
        organizationId: 'test-org',
        displayName: 'Test Org',
        primaryColor: 0xFF2E7D32,
        secondaryColor: 0xFF58BA47,
        accentColor: 0xFF81C784,
        scaffoldBackgroundColor: 0xFFF5F7FA,
      );
}

/// A [NotificationService] that silently swallows all messages (no snackbar
/// in tests).
class _SilentNotificationService extends NotificationService {
  @override
  void error(String message) {}
  @override
  void success(String message) {}
  @override
  void info(String message) {}
  @override
  void warning(String message) {}
}

/// Builds a [HomeController] with pre-set section states and no real
/// repository/network calls. The controller's [onInit] is bypassed by
/// injecting states directly after construction.
HomeController _makeController({
  SectionState<PrayerSchedule>? prayers,
  SectionState<List<Program>>? programs,
  SectionState<List<DonationCategory>>? donations,
  SectionState<String>? qr,
}) {
  final controller = HomeController(
    // No repository — we set states directly.
    notificationService: _SilentNotificationService(),
    // Provide a fixed clock so the timer never fires unexpectedly.
    clock: () => DateTime(2024, 1, 1, 12, 0),
    tickInterval: const Duration(hours: 999), // effectively never ticks
    contentTimeout: const Duration(seconds: 30),
  );

  // Override the initial SectionLoading states with the desired test states.
  if (prayers != null) controller.prayerSchedule.value = prayers;
  if (programs != null) controller.programs.value = programs;
  if (donations != null) controller.donations.value = donations;
  if (qr != null) controller.qr.value = qr;

  return controller;
}

/// Wraps [HomeView] in a [GetMaterialApp] with all required services
/// registered, sets the viewport to 1024×600, and pumps the widget.
Future<void> _pumpHomeView(
  WidgetTester tester, {
  required HomeController controller,
}) async {
  // Register required GetX services.
  Get.put<OrganizationContext>(_FakeOrganizationContext());
  Get.put<ThemeEngine>(ThemeEngine());
  Get.put<NotificationService>(_SilentNotificationService());
  // Register the controller directly so GetView<HomeController> resolves it.
  Get.put<HomeController>(controller);

  await tester.binding.setSurfaceSize(const Size(1024, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    GetMaterialApp(
      home: const HomeView(),
    ),
  );

  // Pump once to let the initial frame settle (no async work needed).
  await tester.pump();
}

/// Tears down all GetX registrations between tests.
void _tearDown() {
  Get.reset();
}

// ---------------------------------------------------------------------------
// Loaded section data
// ---------------------------------------------------------------------------

final _loadedPrayers = SectionLoaded<PrayerSchedule>(
  PrayerSchedule(
    organizationId: 'test-org',
    date: DateTime(2024, 1, 1),
    prayers: const <PrayerTime>[
      PrayerTime(name: 'Fajr', minutesSinceMidnight: 330),
      PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 750),
    ],
  ),
);

const _loadedPrograms = SectionLoaded<List<Program>>(<Program>[
  Program(organizationId: 'test-org', id: 'p1', name: 'Quran Circle'),
]);

const _loadedDonations = SectionLoaded<List<DonationCategory>>(
  <DonationCategory>[
    DonationCategory(organizationId: 'test-org', id: 'd1', name: 'Zakat'),
  ],
);

const _loadedQr = SectionLoaded<String>('https://example.org/donate');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(_tearDown);

  // ---- 1. All four section cards visible at 1024×600 (Req 5.4, 5.7) --------

  group('All four section cards visible at 1024×600 (Req 5.4, 5.7)', () {
    testWidgets('shows Next Prayer, Available Programs, Donation Categories, '
        'and Scan to Donate cards simultaneously', (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Next Prayer'), findsOneWidget);
      expect(find.text('Available Programs'), findsOneWidget);
      expect(find.text('Donation Categories'), findsOneWidget);
      expect(find.text('Scan to Donate'), findsOneWidget);
    });
  });

  // ---- 2. ShimmerLoader shown while loading, replaced when loaded ----------
  //         (Req 13.1, 13.3)

  group('ShimmerLoader shown while loading, replaced when loaded '
      '(Req 13.1, 13.3)', () {
    testWidgets('shows ShimmerLoader for every section in loading state',
        (WidgetTester tester) async {
      // All four sections start in SectionLoading (the default).
      final controller = _makeController(
        prayers: const SectionLoading<PrayerSchedule>(),
        programs: const SectionLoading<List<Program>>(),
        donations: const SectionLoading<List<DonationCategory>>(),
        qr: const SectionLoading<String>(),
      );

      await _pumpHomeView(tester, controller: controller);

      // Four ShimmerLoaders — one per section.
      expect(find.byType(ShimmerLoader), findsNWidgets(4));
    });

    testWidgets('replaces ShimmerLoader with content when section is loaded',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      // No shimmer loaders once all sections are loaded.
      expect(find.byType(ShimmerLoader), findsNothing);

      // Loaded content is visible.
      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Quran Circle'), findsOneWidget);
      expect(find.text('Zakat'), findsOneWidget);
      expect(find.text('https://example.org/donate'), findsOneWidget);
    });

    testWidgets('shows ShimmerLoader only for the still-loading section',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionLoading<PrayerSchedule>(),
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      // Only one shimmer (prayers section).
      expect(find.byType(ShimmerLoader), findsOneWidget);
      // Other sections show their content.
      expect(find.text('Quran Circle'), findsOneWidget);
    });
  });

  // ---- 3. Empty-state message shown for empty sections (Req 3.5) -----------

  group('Empty-state message shown for empty sections (Req 3.5)', () {
    testWidgets('shows "No prayer schedule available." for empty prayers',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionEmpty<PrayerSchedule>(),
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('No prayer schedule available.'), findsOneWidget);
    });

    testWidgets('shows "No programs available." for empty programs',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: const SectionEmpty<List<Program>>(),
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('No programs available.'), findsOneWidget);
    });

    testWidgets(
        'shows "No donation categories available." for empty donations',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: const SectionEmpty<List<DonationCategory>>(),
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(
          find.text('No donation categories available.'), findsOneWidget);
    });

    testWidgets('shows "Scan-to-Donate is unavailable." for empty QR',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: const SectionEmpty<String>(),
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Scan-to-Donate is unavailable.'), findsOneWidget);
    });
  });

  // ---- 4. Error state with Retry button (Req 3.6, 13.4) -------------------

  group('Error state with Retry button shown for errored sections '
      '(Req 3.6, 13.4)', () {
    testWidgets('shows error message and Retry button for errored prayers',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionError<PrayerSchedule>('Prayer load failed'),
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      // When prayers is in error, hasUnresolvedRequiredError is true, so the
      // full-screen error state is shown. We verify the error message and
      // Retry button appear there.
      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Prayer load failed'), findsOneWidget);
      // At least one Retry button is present.
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error message and Retry button for errored programs',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: const SectionError<List<Program>>('Programs load failed'),
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Programs load failed'), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error message and Retry button for errored donations',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: const SectionError<List<DonationCategory>>(
            'Donations load failed'),
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Donations load failed'), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error message and Retry button for errored QR',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: const SectionError<String>('QR load failed'),
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('QR load failed'), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'inline section error shows Retry button when no other section errors',
        (WidgetTester tester) async {
      // All sections loaded except prayers — but prayers is in error, so the
      // full-screen error state is shown (Req 12.3). The Retry button for
      // "Next Prayer" must be present.
      final controller = _makeController(
        prayers: const SectionError<PrayerSchedule>('Timeout'),
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      // Full-screen error state is shown.
      expect(find.text('Content could not be loaded'), findsOneWidget);
      // The per-section retry row for "Next Prayer" is present.
      expect(find.text('Next Prayer'), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });
  });

  // ---- 5. Full-screen error state (Req 12.3) --------------------------------

  group('Full-screen error state shown when any section has error (Req 12.3)',
      () {
    testWidgets(
        'shows full-screen error state and hides content grid when prayers '
        'section errors', (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionError<PrayerSchedule>('Network error'),
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      // Full-screen error headline is visible.
      expect(find.text('Content could not be loaded'), findsOneWidget);
      // The content grid section titles are NOT shown (grid is hidden).
      expect(find.text('Available Programs'), findsNothing);
      expect(find.text('Donation Categories'), findsNothing);
      expect(find.text('Scan to Donate'), findsNothing);
    });

    testWidgets(
        'shows full-screen error state when multiple sections error',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionError<PrayerSchedule>('Error A'),
        programs: const SectionError<List<Program>>('Error B'),
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Content could not be loaded'), findsOneWidget);
      expect(find.text('Error A'), findsOneWidget);
      expect(find.text('Error B'), findsOneWidget);
    });

    testWidgets(
        'does NOT show full-screen error state when all sections are loaded',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: _loadedQr,
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Content could not be loaded'), findsNothing);
      // Content grid is shown.
      expect(find.text('Next Prayer'), findsOneWidget);
    });

    testWidgets(
        'does NOT show full-screen error state when sections are empty '
        '(empty ≠ error)', (WidgetTester tester) async {
      final controller = _makeController(
        prayers: const SectionEmpty<PrayerSchedule>(),
        programs: const SectionEmpty<List<Program>>(),
        donations: const SectionEmpty<List<DonationCategory>>(),
        qr: const SectionEmpty<String>(),
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Content could not be loaded'), findsNothing);
      // Content grid is shown with empty-state messages.
      expect(find.text('No prayer schedule available.'), findsOneWidget);
    });

    testWidgets(
        'full-screen error state lists only errored sections with Retry',
        (WidgetTester tester) async {
      final controller = _makeController(
        prayers: _loadedPrayers,
        programs: _loadedPrograms,
        donations: _loadedDonations,
        qr: const SectionError<String>('QR unavailable'),
      );

      await _pumpHomeView(tester, controller: controller);

      expect(find.text('Content could not be loaded'), findsOneWidget);
      // Only the QR section error row is shown.
      expect(find.text('QR unavailable'), findsOneWidget);
      // The Retry button for the QR section is present.
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
