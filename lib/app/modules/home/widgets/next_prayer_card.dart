import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../next_prayer_resolver.dart';

/// Home next-prayer dashboard (Requirements 6.1, 6.3, 6.5).
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.schedule,
    required this.next,
    required this.hasCountdown,
    required this.countdownLabel,
    required this.now,
    this.fillHeight = false,
  });

  final PrayerSchedule schedule;
  final NextPrayerResult? next;
  final bool hasCountdown;
  final String countdownLabel;
  final DateTime now;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final NextPrayerResult? resolved = next;
    final bool showCountdown = hasCountdown && resolved != null;

    if (fillHeight) {
      if (showCountdown) {
        return _HomeNextPrayerDashboard(
          now: now,
          schedule: schedule,
          next: resolved,
        );
      }
      return _HomeNoCountdownState(now: now);
    }

    return _CompactNextPrayerCard(
      schedule: schedule,
      next: resolved,
      showCountdown: showCountdown,
      countdownLabel: countdownLabel,
    );
  }
}

/// Landscape home layout matching the next-prayer mockup.
class _HomeNextPrayerDashboard extends StatelessWidget {
  const _HomeNextPrayerDashboard({
    required this.now,
    required this.schedule,
    required this.next,
  });

  final DateTime now;
  final PrayerSchedule schedule;
  final NextPrayerResult next;

  static LinearGradient _cardGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        scheme.primary,
        Color.lerp(scheme.primary, scheme.secondary, 0.55) ?? scheme.secondary,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Duration countdown = next.countdown;
    final double progress = _countdownProgress(schedule.prayers, next, countdown);
    final List<PrayerTime> upcoming = _upcomingPrayers(schedule.prayers, next.prayer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DateTimeStatusRow(now: now),
        const SizedBox(height: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _cardGradient(scheme)),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    left: -12,
                    bottom: -8,
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 110,
                      color: Colors.black.withValues(alpha: 0.22),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          flex: 34,
                          child: _NextPrayerLabel(
                            prayerName: next.prayer.name,
                            isNextDay: next.isNextDay,
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          flex: 32,
                          child: _CountdownRing(
                            countdown: countdown,
                            progress: progress,
                            theme: theme,
                            scheme: scheme,
                          ),
                        ),
                        Expanded(
                          flex: 34,
                          child: _UpcomingPrayersList(
                            prayers: upcoming,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static double _countdownProgress(
    List<PrayerTime> prayers,
    NextPrayerResult next,
    Duration remaining,
  ) {
    final List<PrayerTime> sorted = List<PrayerTime>.of(prayers)
      ..sort(
        (PrayerTime a, PrayerTime b) =>
            a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
      );
    final int nextMinutes = next.prayer.minutesSinceMidnight;
    int prevMinutes = sorted.first.minutesSinceMidnight;
    for (final PrayerTime prayer in sorted) {
      if (prayer.minutesSinceMidnight < nextMinutes) {
        prevMinutes = prayer.minutesSinceMidnight;
      }
    }
    int windowMinutes = nextMinutes - prevMinutes;
    if (windowMinutes <= 0) {
      windowMinutes = 90;
    }
    final int totalSeconds = windowMinutes * 60;
    final int remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final double elapsed = (totalSeconds - remainingSeconds).toDouble();
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  static List<PrayerTime> _upcomingPrayers(
    List<PrayerTime> prayers,
    PrayerTime nextPrayer,
  ) {
    final List<PrayerTime> sorted = List<PrayerTime>.of(prayers)
      ..sort(
        (PrayerTime a, PrayerTime b) =>
            a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
      );
    return sorted
        .where(
          (PrayerTime p) =>
              p.name.toLowerCase() != nextPrayer.name.toLowerCase() &&
              !p.name.toLowerCase().contains('sunrise'),
        )
        .toList();
  }
}

class _DateTimeStatusRow extends StatelessWidget {
  const _DateTimeStatusRow({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Row(
      children: <Widget>[
        Icon(Icons.calendar_month_outlined, size: 18, color: muted),
        const SizedBox(width: 6),
        Text(
          formatHeaderDate(now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.schedule_rounded, size: 18, color: muted),
        const SizedBox(width: 6),
        Text(
          formatTime12h(now.hour * 60 + now.minute),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NextPrayerLabel extends StatelessWidget {
  const _NextPrayerLabel({
    required this.prayerName,
    required this.isNextDay,
    required this.theme,
  });

  final String prayerName;
  final bool isNextDay;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Next Prayer',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            prayerName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        if (isNextDay)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tomorrow',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.countdown,
    required this.progress,
    required this.theme,
    required this.scheme,
  });

  final Duration countdown;
  final double progress;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    const double size = 108;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ringSize = math.min(size, constraints.maxHeight - 4);

        return Center(
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: ringSize * 0.09,
                    backgroundColor: Color.lerp(scheme.primary, Colors.black, 0.45)!
                        .withValues(alpha: 0.55),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scheme.onPrimary.withValues(alpha: 0.55),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  formatCountdownHms(countdown),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingPrayersList extends StatelessWidget {
  const _UpcomingPrayersList({
    required this.prayers,
    required this.theme,
  });

  final List<PrayerTime> prayers;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Upcoming Prayers',
          textAlign: TextAlign.right,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: prayers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (BuildContext context, int index) {
              final PrayerTime prayer = prayers[index];
              return Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      prayer.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeNoCountdownState extends StatelessWidget {
  const _HomeNoCountdownState({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DateTimeStatusRow(now: now),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Text(
              'No upcoming prayer countdown available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact fallback when not expanding to fill the section.
class _CompactNextPrayerCard extends StatelessWidget {
  const _CompactNextPrayerCard({
    required this.schedule,
    required this.next,
    required this.showCountdown,
    required this.countdownLabel,
  });

  final PrayerSchedule schedule;
  final NextPrayerResult? next;
  final bool showCountdown;
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showCountdown && next != null) ...<Widget>[
          Text(
            'Next: ${next!.prayer.name}'
            '${next!.isNextDay ? ' (tomorrow)' : ''}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countdownLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...schedule.prayers.map((PrayerTime prayer) {
          final bool isNext = next != null && next!.prayer == prayer;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    prayer.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isNext ? FontWeight.w700 : null,
                      color: isNext ? scheme.primary : null,
                    ),
                  ),
                ),
                Text(
                  formatTime12h(prayer.minutesSinceMidnight),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isNext ? scheme.primary : null,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String formatHeaderDate(DateTime date) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final String day = date.day.toString().padLeft(2, '0');
  return '${weekdays[date.weekday - 1]} ${months[date.month - 1]} $day, ${date.year}';
}

String formatCountdownHms(Duration duration) {
  final Duration d = duration.isNegative ? Duration.zero : duration;
  final int hours = d.inHours;
  final int minutes = d.inMinutes.remainder(60);
  final int seconds = d.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Formats [minutesSinceMidnight] (0..1439) as a 12-hour time, e.g. "5:03 AM".
String formatTime12h(int minutesSinceMidnight) {
  final int hour24 = minutesSinceMidnight ~/ 60;
  final int minute = minutesSinceMidnight % 60;
  final String period = hour24 < 12 ? 'AM' : 'PM';
  int hour12 = hour24 % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
