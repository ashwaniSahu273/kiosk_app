import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../widgets/widgets.dart';
import '../home/next_prayer_resolver.dart';
import '../home/section_state.dart';
import '../home/widgets/widgets.dart';
import 'prayers_controller.dart';

/// The organization-scoped Prayers destination screen (Requirements 5.5, 6.x).
///
/// Shows the active organization's full prayer schedule with the next upcoming
/// prayer highlighted and a live countdown (reusing [NextPrayerCard], which
/// itself uses the resolved [NextPrayerResult] computed by the controller).
/// Themed consistently with the Home_Screen via the shared
/// [KioskDestinationScaffold].
///
/// Empty or failed loads show the matching empty-state (no countdown, Req 6.5)
/// or an error message with a Retry control (Req 3.6).
class PrayersView extends GetView<PrayersController> {
  const PrayersView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.prayers,
      child: SectionCard(
        title: 'Prayer Schedule',
        icon: Icons.mosque_rounded,
        expandChild: true,
        child: Obx(() {
          final SectionState<PrayerSchedule> state = controller.schedule.value;
          // Observe the live clock + resolved next prayer so the countdown
          // ticks while a schedule is displayed.
          final NextPrayerResult? next = controller.nextPrayer.value;
          controller.now.value;
          final bool hasCountdown = controller.hasCountdown;
          final String countdownLabel = controller.countdownLabel;

          if (state is SectionLoading<PrayerSchedule>) {
            return const SingleChildScrollView(
              child: ShimmerLoader(shape: ShimmerShape.nextPrayer),
            );
          }
          if (state is SectionEmpty<PrayerSchedule>) {
            return const _PrayersEmptyState();
          }
          if (state is SectionError<PrayerSchedule>) {
            return _PrayersErrorState(
              message: state.message,
              onRetry: controller.load,
            );
          }
          if (state is SectionLoaded<PrayerSchedule>) {
            return SingleChildScrollView(
              child: NextPrayerCard(
                schedule: state.data,
                next: next,
                hasCountdown: hasCountdown,
                countdownLabel: countdownLabel,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}

/// Empty-state shown when the schedule has no prayers; withholds the countdown
/// (Requirement 6.5).
class _PrayersEmptyState extends StatelessWidget {
  const _PrayersEmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.mosque_outlined,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No prayer schedule available.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error-state for the prayer schedule with a Retry control (Requirement 3.6).
class _PrayersErrorState extends StatelessWidget {
  const _PrayersErrorState({required this.message, required this.onRetry});

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
          Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 16),
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
