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
/// Layout (landscape `Row`):
///   ┌──────────────┬──────────────────────────────────────────────────────┐
///   │  KioskSidebar│  KioskHeader (+ logout control)                      │
///   │   (320 px)   ├──────────────────────────────────────────────────────┤
///   │              │  Next Prayer       │  Donation Categories            │
///   │              │  Available Programs │  Scan to Donate                │
///   └──────────────┴──────────────────────────────────────────────────────┘
///
/// All four required sections are simultaneously visible at ≥1024×600 without
/// scrolling the page (Requirements 5.4, 5.7); the layout is built entirely
/// from [Expanded]/[Flexible] so it fits the viewport and never overflows.
///
/// Each section renders from its own [SectionState] (Requirements 13.1, 13.3):
/// * [SectionLoading] → [ShimmerLoader] with the matching [ShimmerShape];
/// * [SectionLoaded]  → interim inline content (Task 15 replaces these with
///   dedicated section widgets);
/// * [SectionEmpty]   → a per-section empty-state message (disabled Donate
///   control for empty donations, Req 8.3);
/// * [SectionError]   → an error message and a Retry control.
///
/// Requirement 12.3/12.4 gating: while
/// [HomeController.hasUnresolvedRequiredError] is true, the content grid is
/// hidden and a full-screen "content could not be loaded" state lists every
/// errored section with its own Retry control. When false, the 2×2 grid shows.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Clears the session and active organization, then returns to login
  /// (Requirement 1.9).
  Future<void> _logout() async {
    await Get.find<AuthService>().logout();
    await Get.offAllNamed<void>(AppRoutes.login);
  }

  void _select(KioskDestination destination) {
    switch (destination) {
      case KioskDestination.home:
        return; // Already on Home; no-op.
      case KioskDestination.donate:
        Get.toNamed<void>(AppRoutes.donate);
        return;
      case KioskDestination.prayers:
        Get.toNamed<void>(AppRoutes.prayers);
        return;
      case KioskDestination.programs:
        Get.toNamed<void>(AppRoutes.programs);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ---- Left sidebar (fixed width) ----
            KioskSidebar(
              active: KioskDestination.home,
              onSelect: _select,
              footer: const KioskSidebarScanFooter(),
            ),

            // ---- Right: header + content ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header (logo, org name, live date/time) with a logout
                  // control beside it (Req 1.9, 5.1, 5.2).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Expanded(child: KioskHeader()),
                      _LogoutControl(onLogout: _logout),
                    ],
                  ),

                  // Content area fills the remaining height.
                  Expanded(
                    child: Obx(() {
                      // Reading the gate registers all four section states,
                      // so this rebuilds whenever any section resolves.
                      if (controller.hasUnresolvedRequiredError) {
                        return _FullScreenErrorState(
                          controller: controller,
                        );
                      }
                      return _HomeContentGrid(controller: controller);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout control
// ---------------------------------------------------------------------------

/// A logout control rendered beside the header (Requirement 1.9).
class _LogoutControl extends StatelessWidget {
  const _LogoutControl({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignment: Alignment.center,
      child: KioskButton(
        label: 'Log out',
        icon: Icons.logout_rounded,
        variant: KioskButtonVariant.secondary,
        onPressed: () => onLogout(),
      ),
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

/// The 2×2 content grid shown when every required section is resolved.
///
/// Left column:  Next Prayer (top) + Available Programs (bottom)
/// Right column: Donation Categories (top) + Scan to Donate (bottom)
///
/// Built from [Expanded]/[Flexible] so the four sections fit 1024×600 without
/// page scrolling or overflow (Requirements 5.4, 5.7).
class _HomeContentGrid extends StatelessWidget {
  const _HomeContentGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    const double spacing = 12;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SectionCard(
                    title: 'Next Prayer',
                    icon: Icons.mosque_rounded,
                    expandChild: true,
                    child: _PrayerSectionContent(controller: controller),
                  ),
                ),
                const SizedBox(width: spacing),
                Expanded(
                  child: SectionCard(
                    title: 'Donation Categories',
                    icon: Icons.volunteer_activism_rounded,
                    expandChild: true,
                    child: _DonationsSectionContent(controller: controller),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: spacing),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Per-section content (state → shimmer / interim content / empty / error)
// ---------------------------------------------------------------------------

/// Next Prayer section: the day's prayer list plus the resolved next prayer and
/// its live countdown (Requirements 6.1, 6.3, 6.5, 13.1, 13.3).
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

      if (state is SectionLoading<PrayerSchedule>) {
        return const ShimmerLoader(shape: ShimmerShape.nextPrayer);
      }
      if (state is SectionLoaded<PrayerSchedule>) {
        return NextPrayerCard(
          fillHeight: true,
          schedule: state.data,
          next: next,
          hasCountdown: hasCountdown,
          countdownLabel: countdownLabel,
        );
      }
      if (state is SectionEmpty<PrayerSchedule>) {
        return const _EmptyState(message: 'No prayer schedule available.');
      }
      if (state is SectionError<PrayerSchedule>) {
        return _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.prayerSchedule),
        );
      }
      return const SizedBox.shrink();
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
        return const _DonationsEmptyState();
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
Widget _sectionBody<T>({
  required SectionState<T> state,
  required ShimmerShape shimmerShape,
  required VoidCallback onRetry,
  required Widget Function(T data) onLoaded,
  required String emptyMessage,
  bool wrapInScrollView = true,
}) {
  if (state is SectionLoading<T>) {
    final Widget loader = ShimmerLoader(shape: shimmerShape);
    return wrapInScrollView ? SingleChildScrollView(child: loader) : loader;
  }
  if (state is SectionLoaded<T>) {
    final Widget content = onLoaded(state.data);
    return wrapInScrollView
        ? SingleChildScrollView(child: content)
        : content;
  }
  if (state is SectionEmpty<T>) {
    return _EmptyState(message: emptyMessage);
  }
  if (state is SectionError<T>) {
    return _ErrorState(message: state.message, onRetry: onRetry);
  }
  return const SizedBox.shrink();
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
