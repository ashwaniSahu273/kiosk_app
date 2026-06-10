import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../widgets/widgets.dart';
import '../home/section_state.dart';
import 'prayers_controller.dart';
import 'widgets/prayer_times_body.dart';
import 'widgets/prayer_times_header.dart';

/// Organization-scoped Prayer Times screen with Today's, Daily, and Monthly tabs.
class PrayersView extends GetView<PrayersController> {
  const PrayersView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.prayers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const KioskScreenHeader(
            title: 'Prayer Times',
            icon: Icons.mosque_rounded,
            subtitle: "Today's salah, daily timetable, and the monthly schedule",
          ),
          const SizedBox(height: 14),
          PrayerTimesHeader(controller: controller),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Obx(() {
                  final SectionState<PrayerSchedule> state =
                      controller.schedule.value;

                  if (state is SectionLoading<PrayerSchedule>) {
                    return const _PrayerTimesLoading();
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
                    return PrayerTimesBody(controller: controller);
                  }
                  return const SizedBox.shrink();
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimesLoading extends StatelessWidget {
  const _PrayerTimesLoading();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoader(shape: ShimmerShape.prayerTimes);
  }
}

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
