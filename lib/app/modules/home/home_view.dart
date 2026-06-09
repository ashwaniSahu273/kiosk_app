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

/// The full landscape Home_Screen (Requirements 5.1, 5.4, 5.7, 12.3, 12.4,
/// 13.1, 13.3).
///
/// Layout (sidebar-less; shared [KioskDestinationScaffold] top navigation):
///   ┌────────────────────────────────────────────────────────────────────┐
///   │  KioskTopNavBar (logo · nav pills · clock · logout)                │
///   ├──────────────────────────────────────────────┬─────────────────────┤
///   │  Next Prayer (hero dashboard)                │  Scan to Donate     │
///   ├──────────────────────────────┬───────────────┴─────────────────────┤
///   │  Donation Categories         │  Available Programs                 │
///   └──────────────────────────────┴─────────────────────────────────────┘
///
/// All four required sections are simultaneously visible at ≥1024×600 without
/// scrolling the page (Requirements 5.4, 5.7); the layout is built entirely
/// from [Expanded]/[Flexible] so it fits the viewport and never overflows.
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
// Main content grid (all four sections visible simultaneously)
// ---------------------------------------------------------------------------

/// The content grid shown when every required section is resolved.
///
/// Top row:    Next Prayer hero dashboard (wide) + Scan to Donate (right)
/// Bottom row: Donation Categories + Available Programs
///
/// Built from [Expanded]/[Flexible] so the four sections fit 1024×600 without
/// page scrolling or overflow (Requirements 5.4, 5.7).
class _HomeContentGrid extends StatelessWidget {
  const _HomeContentGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    const double spacing = 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ---- Top row: hero next-prayer dashboard + scan-to-donate ----
        Expanded(
          flex: 11,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: _PrayerSectionContent(controller: controller),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: 240,
                child: SectionCard(
                  title: 'Scan to Donate',
                  icon: Icons.qr_code_2_rounded,
                  expandChild: true,
                  child: _QrSectionContent(controller: controller),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: spacing),

        // ---- Bottom row: donations + programs ----
        Expanded(
          flex: 9,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SectionCard(
                  title: 'Donation Categories',
                  icon: Icons.volunteer_activism_rounded,
                  expandChild: true,
                  child: _DonationsSectionContent(controller: controller),
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: SectionCard(
                  title: 'Available Programs',
                  icon: Icons.event_rounded,
                  expandChild: true,
                  child: _ProgramsSectionContent(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ],
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

      return _sectionBody<String>(
        state: state,
        shimmerShape: ShimmerShape.qrCard,
        onRetry: () => controller.retrySection(HomeSection.qr),
        emptyMessage: 'Scan-to-Donate is unavailable.',
        wrapInScrollView: false,
        onLoaded: (String url) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ScanToDonateCard(donationUrl: url, showUrl: false),
          ),
        ),
      );
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
