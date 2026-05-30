import '../../core/data/models/prayer_time.dart';

/// The resolved next upcoming prayer together with whether it falls on the
/// following day and the non-negative countdown until its next occurrence.
///
/// See Requirement 6 (Next Prayer Countdown).
class NextPrayerResult {
  const NextPrayerResult({
    required this.prayer,
    required this.isNextDay,
    required this.countdown,
  });

  /// The prayer identified as the next upcoming prayer.
  final PrayerTime prayer;

  /// True when no prayer remained strictly later than `now` today, so the
  /// resolved prayer is the earliest prayer of the following day (Req 6.4).
  final bool isNextDay;

  /// Duration from `now` to the next occurrence of [prayer]; always `>= 0`.
  final Duration countdown;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NextPrayerResult &&
            runtimeType == other.runtimeType &&
            prayer == other.prayer &&
            isNextDay == other.isNextDay &&
            countdown == other.countdown;
  }

  @override
  int get hashCode => Object.hash(prayer, isNextDay, countdown);

  @override
  String toString() =>
      'NextPrayerResult(prayer: $prayer, isNextDay: $isNextDay, '
      'countdown: $countdown)';
}

/// Pure, side-effect-free logic that resolves the next upcoming prayer from a
/// day's schedule relative to a given moment.
///
/// Implements Requirement 6 acceptance criteria 6.2 (strict-later selection,
/// equal-time exclusion) and 6.4 (next-day rollover).
class NextPrayerResolver {
  const NextPrayerResolver._();

  /// Resolves the next upcoming prayer for [schedule] relative to [now].
  ///
  /// Returns `null` when [schedule] is empty (Req 6.5 empty-state, no
  /// countdown).
  ///
  /// The next prayer is the earliest prayer whose [PrayerTime.minutesSinceMidnight]
  /// is strictly greater than `now`'s minutes-since-midnight (Req 6.2; a prayer
  /// scheduled at exactly the current time is not selected). When no prayer is
  /// strictly later, the earliest prayer of the schedule is chosen and marked
  /// with `isNextDay = true` (Req 6.4).
  ///
  /// The countdown is computed from a precise occurrence [DateTime] built from
  /// `now`'s calendar date (plus one day when [NextPrayerResult.isNextDay]) at
  /// the prayer's hour/minute, and is guaranteed non-negative.
  static NextPrayerResult? resolve(List<PrayerTime> schedule, DateTime now) {
    if (schedule.isEmpty) {
      return null;
    }

    // Order a copy by time of day; do not assume the input is pre-sorted.
    final List<PrayerTime> sorted = List<PrayerTime>.of(schedule)
      ..sort((a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight));

    final int nowMinutes = now.hour * 60 + now.minute;

    PrayerTime? upcoming;
    for (final PrayerTime prayer in sorted) {
      if (prayer.minutesSinceMidnight > nowMinutes) {
        upcoming = prayer;
        break;
      }
    }

    final bool isNextDay = upcoming == null;
    final PrayerTime prayer = upcoming ?? sorted.first;

    // Build the precise occurrence DateTime from now's calendar date so the
    // countdown accounts for the seconds component of `now`.
    final int hour = prayer.minutesSinceMidnight ~/ 60;
    final int minute = prayer.minutesSinceMidnight % 60;
    final DateTime occurrence = DateTime(
      now.year,
      now.month,
      now.day + (isNextDay ? 1 : 0),
      hour,
      minute,
    );

    Duration countdown = occurrence.difference(now);
    if (countdown.isNegative) {
      countdown = Duration.zero;
    }

    return NextPrayerResult(
      prayer: prayer,
      isNextDay: isNextDay,
      countdown: countdown,
    );
  }
}
