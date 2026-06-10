import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../next_prayer_resolver.dart';
import 'scan_to_donate_card.dart';

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
    this.donationUrl,
  });

  final PrayerSchedule schedule;
  final NextPrayerResult? next;
  final bool hasCountdown;
  final String countdownLabel;
  final DateTime now;
  final bool fillHeight;

  /// The active organization's donation URL, rendered as a Scan-to-Donate QR
  /// inside the dashboard. Null/blank hides the QR column.
  final String? donationUrl;

  @override
  Widget build(BuildContext context) {
    final NextPrayerResult? resolved = next;
    final bool showCountdown = hasCountdown && resolved != null;

    if (fillHeight) {
      if (showCountdown) {
        return _HomeNextPrayerDashboard(
          schedule: schedule,
          next: resolved,
          donationUrl: donationUrl,
        );
      }
      return const _HomeNoCountdownState();
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
    required this.schedule,
    required this.next,
    this.donationUrl,
  });

  final PrayerSchedule schedule;
  final NextPrayerResult next;
  final String? donationUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Duration countdown = next.countdown;
    final double progress = _countdownProgress(
      schedule.prayers,
      next,
      countdown,
    );
    final List<PrayerTime> upcoming = _upcomingPrayers(
      schedule.prayers,
      next.prayer,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 330,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(58),
                  bottomRight: Radius.circular(58),
                ),
              ),
              child: Text(
                'NEXT PRAYER',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 62, 28, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          next.prayer.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                            height: 0.98,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                      if (next.isNextDay)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tomorrow',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _CountdownRing(
                          countdown: countdown,
                          progress: progress,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 42,
                  child: _UpcomingPrayersList(prayers: upcoming, theme: theme),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 26,
                  child: _DashboardQr(donationUrl: donationUrl, theme: theme),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.countdown,
    required this.progress,
    required this.theme,
  });

  final Duration countdown;
  final double progress;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 230;
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 230;
        final double ringSize = math.min(300, math.min(maxWidth, maxHeight));

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
                    strokeWidth: ringSize * 0.07,
                    backgroundColor: scheme.primary.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Positioned(
                  top: ringSize * 0.015,
                  child: Container(
                    width: ringSize * 0.09,
                    height: ringSize * 0.09,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                  ),
                ),
                SizedBox(
                  width: ringSize * 0.78,
                  height: ringSize * 0.48,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          formatCountdownHms(countdown),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'UNTIL ADHAN',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
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
  const _UpcomingPrayersList({required this.prayers, required this.theme});

  final List<PrayerTime> prayers;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.mosque_rounded, color: scheme.primary, size: 18),
            const SizedBox(width: 7),
            Text(
              'UPCOMING PRAYERS',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prayers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (BuildContext context, int index) {
              final PrayerTime prayer = prayers[index];
              final bool isNight =
                  prayer.name.toLowerCase().contains('isha') ||
                  prayer.name.toLowerCase().contains('fajr');
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isNight
                          ? Icons.nightlight_round
                          : Icons.wb_twilight_rounded,
                      color: scheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prayer.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatTime12h(prayer.minutesSinceMidnight),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Scan-to-Donate QR rendered as the dashboard's right-most column.
class _DashboardQr extends StatelessWidget {
  const _DashboardQr({required this.donationUrl, required this.theme});

  final String? donationUrl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;
    final String? url = donationUrl;
    final bool hasUrl = url != null && url.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.qr_code_2_rounded, color: scheme.primary, size: 18),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'SCAN TO DONATE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double qrSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                ).clamp(60.0, 150.0);

                if (!hasUrl) {
                  return Icon(
                    Icons.qr_code_2_rounded,
                    size: qrSize,
                    color: scheme.onSurface.withValues(alpha: 0.30),
                  );
                }

                return ScanToDonateCard(
                  donationUrl: url,
                  size: qrSize,
                  showUrl: false,
                  showCaption: false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeNoCountdownState extends StatelessWidget {
  const _HomeNoCountdownState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Center(
        child: Text(
          'No upcoming prayer countdown available.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
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
