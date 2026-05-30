import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../next_prayer_resolver.dart';

/// Renders the loaded Next_Prayer_Card content (Requirements 6.1, 6.3, 6.5).
///
/// Shows the day's [PrayerSchedule] with each prayer's name and scheduled time
/// formatted as a 12-hour clock (e.g. "5:03 AM"), visually highlights the
/// resolved [next] upcoming prayer, and — when a countdown is available —
/// displays the remaining hours and minutes until that prayer.
///
/// This widget only renders the *loaded* schedule; the empty/failed schedule
/// states (no countdown, Req 6.5) are handled by the Home view, which routes
/// those section states to its empty/error widgets. As a defensive measure the
/// card still renders gracefully when [next]/[hasCountdown] indicate no
/// countdown by simply omitting the countdown block.
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.schedule,
    required this.next,
    required this.hasCountdown,
    required this.countdownLabel,
  });

  /// The day's prayer schedule to render.
  final PrayerSchedule schedule;

  /// The resolved next upcoming prayer (and rollover flag), or null when no
  /// countdown applies.
  final NextPrayerResult? next;

  /// Whether a live countdown should be shown (Req 6.5).
  final bool hasCountdown;

  /// Pre-formatted "Hh Mm" countdown label supplied by the controller
  /// (Req 6.3).
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final NextPrayerResult? resolved = next;
    final bool showCountdown = hasCountdown && resolved != null;

    // Index of the prayer row to highlight as "next". Prefer identity so a
    // duplicated name/time elsewhere in the list is not also highlighted.
    final int highlightIndex = resolved == null
        ? -1
        : _indexOfNext(schedule.prayers, resolved.prayer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showCountdown) ...<Widget>[
          Text(
            'Next: ${resolved.prayer.name}'
            '${resolved.isNextDay ? ' (tomorrow)' : ''}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                countdownLabel,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (int i = 0; i < schedule.prayers.length; i++)
          _PrayerRow(
            prayer: schedule.prayers[i],
            isNext: i == highlightIndex,
          ),
      ],
    );
  }

  /// Returns the index of the prayer to highlight, preferring identity over
  /// equality so duplicate name/time entries are not all highlighted.
  static int _indexOfNext(List<PrayerTime> prayers, PrayerTime target) {
    final int identityIndex =
        prayers.indexWhere((PrayerTime p) => identical(p, target));
    if (identityIndex != -1) {
      return identityIndex;
    }
    return prayers.indexWhere((PrayerTime p) => p == target);
  }
}

/// A single prayer row: name on the left, scheduled time on the right. When
/// [isNext] is true the row is visually emphasized as the upcoming prayer.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.prayer, required this.isNext});

  final PrayerTime prayer;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget row = Row(
      children: <Widget>[
        if (isNext) ...<Widget>[
          Icon(Icons.arrow_right_rounded, size: 22, color: scheme.primary),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            prayer.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
              color: isNext ? scheme.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatTimeOfDay(prayer.minutesSinceMidnight),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isNext ? scheme.primary : null,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
      ],
    );

    if (!isNext) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: row,
      ),
    );
  }
}

/// Formats [minutesSinceMidnight] (0..1439) as a 12-hour time, e.g. "5:03 AM".
String formatTimeOfDay(int minutesSinceMidnight) {
  final int hour24 = minutesSinceMidnight ~/ 60;
  final int minute = minutesSinceMidnight % 60;
  final String period = hour24 < 12 ? 'AM' : 'PM';
  int hour12 = hour24 % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
