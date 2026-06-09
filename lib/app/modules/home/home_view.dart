import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../routes/app_routes.dart';
import '../auth/auth_service.dart';
import '../../widgets/widgets.dart';
import 'home_controller.dart';
import 'next_prayer_resolver.dart';
import 'section_state.dart';
import 'widgets/widgets.dart';

/// The full landscape Home_Screen (Requirements 5.1, 12.3, 12.4, 13.1, 13.3),
/// matching the reference design 1:1.
///
/// Layout (sidebar-less; shared [KioskDestinationScaffold] top navigation;
/// the content area below the bar scrolls vertically):
///   ┌────────────────────────────────────────────────────────────────────┐
///   │  KioskTopNavBar (logo · nav pills · clock · logout)                │
///   ├──────────────────────────────────────────────┬─────────────────────┤
///   │  Next Prayer (hero: countdown + upcoming)    │  Scan to Donate     │
///   ├──────────────────────────────────────────────┴─────────────────────┤
///   │  Today's Prayer Times (tile per prayer, next highlighted)          │
///   ├────────────────────────────────────────────────────────────────────┤
///   │  Donation Categories (horizontal campaign cards)                   │
///   ├────────────────────────────────────────────────────────────────────┤
///   │  Available Programs (horizontal campaign cards)                    │
///   └────────────────────────────────────────────────────────────────────┘
///
/// Each section sits at a comfortable fixed height inside a single
/// [SingleChildScrollView], so the page scrolls smoothly and nothing ever
/// overflows regardless of how much content an organization configures.
///
/// Each section renders from its own [SectionState] (Requirements 13.1, 13.3):
/// * [SectionLoading] → [ShimmerLoader] with the matching [ShimmerShape];
/// * [SectionLoaded]  → the section's content widget;
/// * [SectionEmpty]   → a per-section empty-state message (disabled Donate
///   control for empty donations, Req 8.3);
/// * [SectionError]   → an error message and a Retry control.
///
/// State transitions cross-fade through an [AnimatedSwitcher] so shimmer
/// placeholders dissolve smoothly into content.
///
/// Requirement 12.3/12.4 gating: while
/// [HomeController.hasUnresolvedRequiredError] is true, the content grid is
/// hidden and a full-screen "content could not be loaded" state lists every
/// errored section with its own Retry control. When false, the grid shows.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Clears the session and active organization, then returns to login
  /// (Requirement 1.9).
  Future<void> _logout() async {
    await Get.find<AuthService>().logout();
    await Get.offAllNamed<void>(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.home,
      trailing: _LogoutControl(onLogout: _logout),
      child: Obx(() {
        // Reading the gate registers all four section states, so this
        // rebuilds whenever any section resolves.
        if (controller.hasUnresolvedRequiredError) {
          return _FullScreenErrorState(controller: controller);
        }
        return _HomeContentGrid(controller: controller);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout control
// ---------------------------------------------------------------------------

/// A logout control rendered in the top navigation bar (Requirement 1.9).
class _LogoutControl extends StatelessWidget {
  const _LogoutControl({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return KioskButton(
      label: 'Log out',
      icon: Icons.logout_rounded,
      variant: KioskButtonVariant.secondary,
      onPressed: () => onLogout(),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen error state (Req 12.3, 12.4)
// ---------------------------------------------------------------------------

/// Shown while any required Home section has an unresolved loading error.
///
/// Hides the content grid and lists every errored section with its own Retry
/// control (Requirements 12.3, 12.4).
class _FullScreenErrorState extends StatelessWidget {
  const _FullScreenErrorState({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Content could not be loaded',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please retry the sections below. Every section must load '
              'before the home screen is shown.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Per-section retry controls (only errored sections render a row).
            _SectionRetryRow(
              label: 'Next Prayer',
              state: controller.prayerSchedule.value,
              onRetry: () =>
                  controller.retrySection(HomeSection.prayerSchedule),
            ),
            _SectionRetryRow(
              label: 'Available Programs',
              state: controller.programs.value,
              onRetry: () => controller.retrySection(HomeSection.programs),
            ),
            _SectionRetryRow(
              label: 'Donation Categories',
              state: controller.donations.value,
              onRetry: () => controller.retrySection(HomeSection.donations),
            ),
            _SectionRetryRow(
              label: 'Scan to Donate',
              state: controller.qr.value,
              onRetry: () => controller.retrySection(HomeSection.qr),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row showing an errored section's message and a Retry button. Only
/// rendered when [state] is a [SectionError].
class _SectionRetryRow extends StatelessWidget {
  const _SectionRetryRow({
    required this.label,
    required this.state,
    required this.onRetry,
  });

  final String label;
  final SectionState<dynamic> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SectionState<dynamic> current = state;
    if (current is! SectionError<dynamic>) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    current.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            KioskButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main scrollable content (reference-image layout)
// ---------------------------------------------------------------------------

/// The scrollable Home content shown when every required section is resolved.
///
/// Row 1: Next Prayer hero dashboard (countdown + upcoming prayers) with the
///        Scan-to-Donate QR card beside it.
/// Row 2: Today's Prayer Times — one tile per prayer, next prayer highlighted.
/// Row 3: Donation Categories — horizontally scrolling campaign cards.
/// Row 4: Available Programs — horizontally scrolling campaign cards.
///
/// Every section gets a comfortable fixed height inside one vertical
/// [SingleChildScrollView], so the page scrolls smoothly and never overflows.
class _HomeContentGrid extends StatelessWidget {
  const _HomeContentGrid({required this.controller});

  final HomeController controller;

  static const double _spacing = 14;
  static const double _heroHeight = 248;
  static const double _prayerTimesHeight = 124;
  static const double _campaignSectionHeight = 332;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ---- Row 1: hero next-prayer dashboard + scan-to-donate ----
          SizedBox(
            height: _heroHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _PrayerSectionContent(controller: controller),
                ),
                const SizedBox(width: _spacing),
                SizedBox(
                  width: 236,
                  child: SectionCard(
                    title: 'Scan to Donate',
                    icon: Icons.qr_code_2_rounded,
                    expandChild: true,
                    padding: const EdgeInsets.all(16),
                    child: _QrSectionContent(controller: controller),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 2: today's prayer times tiles ----
          SizedBox(
            height: _prayerTimesHeight,
            child: SectionCard(
              title: "Today's Prayer Times",
              icon: Icons.mosque_rounded,
              expandChild: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: _PrayerTimesRow(controller: controller),
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 3: donation categories ----
          SizedBox(
            height: _campaignSectionHeight,
            child: SectionCard(
              title: 'Donation Categories',
              icon: Icons.volunteer_activism_rounded,
              expandChild: true,
              child: _DonationsSectionContent(controller: controller),
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 4: available programs ----
          SizedBox(
            height: _campaignSectionHeight,
            child: SectionCard(
              title: 'Available Programs',
              icon: Icons.event_rounded,
              expandChild: true,
              child: _ProgramsSectionContent(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's prayer times row (tile per prayer, next prayer highlighted)
// ---------------------------------------------------------------------------

/// A horizontal row of prayer-time tiles for today's schedule. The resolved
/// next prayer is highlighted in the theme primary color so visitors can read
/// the full timetable at a glance beside the hero countdown.
class _PrayerTimesRow extends StatelessWidget {
  const _PrayerTimesRow({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<PrayerSchedule> state =
          controller.prayerSchedule.value;
      final NextPrayerResult? next = controller.nextPrayer.value;

      Widget body;
      if (state is SectionLoading<PrayerSchedule>) {
        body = const ShimmerLoader(shape: ShimmerShape.prayerTimes);
      } else if (state is SectionLoaded<PrayerSchedule>) {
        final List<PrayerTime> prayers =
            List<PrayerTime>.of(state.data.prayers)
              ..sort((PrayerTime a, PrayerTime b) =>
                  a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight));
        body = Row(
          children: <Widget>[
            for (int i = 0; i < prayers.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _PrayerTimeTile(
                  prayer: prayers[i],
                  isNext: next != null && next.prayer == prayers[i],
                ),
              ),
            ],
          ],
        );
      } else if (state is SectionEmpty<PrayerSchedule>) {
        body = const _EmptyState(message: 'No prayer schedule available.');
      } else if (state is SectionError<PrayerSchedule>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.prayerSchedule),
        );
      } else {
        body = const SizedBox.shrink();
      }

      return _animatedState(state: state, child: body);
    });
  }
}

/// One prayer tile: the prayer name above its time. The next prayer fills with
/// the theme primary color; the rest sit on a soft tinted surface.
class _PrayerTimeTile extends StatelessWidget {
  const _PrayerTimeTile({required this.prayer, required this.isNext});

  final PrayerTime prayer;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Color background = isNext
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.06);
    final Color nameColor = isNext
        ? scheme.onPrimary.withValues(alpha: 0.92)
        : scheme.onSurface.withValues(alpha: 0.65);
    final Color timeColor = isNext ? scheme.onPrimary : scheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: isNext
            ? null
            : Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayer.name,
              style: theme.textTheme.labelLarge?.copyWith(
                color: nameColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatTime12h(prayer.minutesSinceMidnight),
              style: theme.textTheme.titleMedium?.copyWith(
                color: timeColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-section content (state → shimmer / content / empty / error)
// ---------------------------------------------------------------------------

/// Cross-fades between section states (shimmer → content/empty/error) so
/// state changes feel smooth instead of popping (200 ms, matching the app's
/// route fade).
Widget _animatedState({
  required SectionState<dynamic> state,
  required Widget child,
}) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: KeyedSubtree(
      key: ValueKey<Type>(state.runtimeType),
      child: child,
    ),
  );
}

/// Next Prayer section: the hero dashboard with the day's prayer list, the
/// resolved next prayer, and its live countdown (Requirements 6.1, 6.3, 6.5,
/// 13.1, 13.3).
class _PrayerSectionContent extends StatelessWidget {
  const _PrayerSectionContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<PrayerSchedule> state = controller.prayerSchedule.value;
      // Observe the live clock + resolved next prayer so the countdown ticks.
      final NextPrayerResult? next = controller.nextPrayer.value;
      controller.now.value;
      final bool hasCountdown = controller.hasCountdown;
      final String countdownLabel = controller.countdownLabel;

      Widget body;
      if (state is SectionLoading<PrayerSchedule>) {
        body = const ShimmerLoader(shape: ShimmerShape.nextPrayer);
      } else if (state is SectionLoaded<PrayerSchedule>) {
        body = NextPrayerCard(
          fillHeight: true,
          schedule: state.data,
          next: next,
          hasCountdown: hasCountdown,
          countdownLabel: countdownLabel,
          now: controller.now.value,
        );
      } else if (state is SectionEmpty<PrayerSchedule>) {
        body = const _EmptyState(message: 'No prayer schedule available.');
      } else if (state is SectionError<PrayerSchedule>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.prayerSchedule),
        );
      } else {
        body = const SizedBox.shrink();
      }

      return _animatedState(state: state, child: body);
    });
  }
}

/// Scan-to-Donate section: renders the QR code for the active organization's
/// donation URL (Requirements 9.1, 9.2, 13.1, 13.3).
class _QrSectionContent extends StatelessWidget {
  const _QrSectionContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<String> state = controller.qr.value;

      Widget body;
      if (state is SectionLoading<String>) {
        body = const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ShimmerLoader(shape: ShimmerShape.qrCard),
          ),
        );
      } else if (state is SectionLoaded<String>) {
        body = Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ScanToDonateCard(donationUrl: state.data, showUrl: false),
          ),
        );
      } else if (state is SectionEmpty<String>) {
        body = const _EmptyState(message: 'Scan-to-Donate is unavailable.');
      } else if (state is SectionError<String>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.qr),
        );
      } else {
        body = const SizedBox.shrink();
      }

      return _animatedState(state: state, child: body);
    });
  }
}

/// Available Programs section: each program name with a Register control
/// (Requirements 7.1, 13.1, 13.3).
class _ProgramsSectionContent extends StatelessWidget {
  const _ProgramsSectionContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<Program>> state = controller.programs.value;

      return _sectionBody<List<Program>>(
        state: state,
        shimmerShape: ShimmerShape.programsList,
        onRetry: () => controller.retrySection(HomeSection.programs),
        emptyMessage: 'No programs available.',
        wrapInScrollView: false,
        onLoaded: (List<Program> programs) => ProgramsSection(
          programs: programs,
        ),
      );
    });
  }
}

/// Donation Categories section: each category name with a Donate control; the
/// empty state shows a disabled, grayed Donate control (Requirements 8.1, 8.3,
/// 13.1, 13.3).
class _DonationsSectionContent extends StatelessWidget {
  const _DonationsSectionContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<DonationCategory>> state =
          controller.donations.value;

      if (state is SectionEmpty<List<DonationCategory>>) {
        // Req 8.3: empty donations still surface a (disabled) Donate control.
        return _animatedState(
          state: state,
          child: const _DonationsEmptyState(),
        );
      }

      return _sectionBody<List<DonationCategory>>(
        state: state,
        shimmerShape: ShimmerShape.donationCategories,
        onRetry: () => controller.retrySection(HomeSection.donations),
        emptyMessage: 'No donation categories available.',
        wrapInScrollView: false,
        onLoaded: (List<DonationCategory> categories) => DonationsSection(
          categories: categories,
        ),
      );
    });
  }
}

/// Empty Donation Categories state with a disabled, grayed Donate control
/// (Requirement 8.3).
class _DonationsEmptyState extends StatelessWidget {
  const _DonationsEmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.volunteer_activism_outlined,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'No donation categories available.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          const KioskButton(
            label: 'Donate',
            icon: Icons.volunteer_activism_rounded,
            variant: KioskButtonVariant.secondary,
            isEnabled: false,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic section body + shared empty/error widgets
// ---------------------------------------------------------------------------

/// Maps a [SectionState] to its widget (Requirements 13.1, 13.3):
/// * [SectionLoading] → [ShimmerLoader];
/// * [SectionLoaded]  → [onLoaded] result;
/// * [SectionEmpty]   → empty-state message;
/// * [SectionError]   → error message + Retry control.
///
/// State changes cross-fade via [_animatedState].
Widget _sectionBody<T>({
  required SectionState<T> state,
  required ShimmerShape shimmerShape,
  required VoidCallback onRetry,
  required Widget Function(T data) onLoaded,
  required String emptyMessage,
  bool wrapInScrollView = true,
}) {
  Widget body;
  if (state is SectionLoading<T>) {
    final Widget loader = ShimmerLoader(shape: shimmerShape);
    body = wrapInScrollView ? SingleChildScrollView(child: loader) : loader;
  } else if (state is SectionLoaded<T>) {
    final Widget content = onLoaded(state.data);
    body =
        wrapInScrollView ? SingleChildScrollView(child: content) : content;
  } else if (state is SectionEmpty<T>) {
    body = _EmptyState(message: emptyMessage);
  } else if (state is SectionError<T>) {
    body = _ErrorState(message: state.message, onRetry: onRetry);
  } else {
    body = const SizedBox.shrink();
  }

  return _animatedState(state: state, child: body);
}

/// A centered empty-state message.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.inbox_rounded,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// A centered error message with a Retry control (Requirement 13.4).
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 14),
          KioskButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
