import 'package:flutter/material.dart';

import '../../core/data/models/models.dart';

const List<String> _weekdayShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Display order for salah rows in tables.
const List<String> kSalahDisplayOrder = <String>[
  'Fajr',
  'Sunrise',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

/// Sorts [prayers] into the standard salah display order.
List<PrayerTime> sortSalahForDisplay(List<PrayerTime> prayers) {
  final Map<String, PrayerTime> byName = <String, PrayerTime>{
    for (final PrayerTime p in prayers) p.name: p,
  };
  final List<PrayerTime> ordered = <PrayerTime>[];
  for (final String name in kSalahDisplayOrder) {
    final PrayerTime? match = byName[name];
    if (match != null) {
      ordered.add(match);
    }
  }
  for (final PrayerTime p in prayers) {
    if (!ordered.contains(p)) {
      ordered.add(p);
    }
  }
  return ordered;
}

String formatLongDate(DateTime date) {
  final String weekday = _weekdayLong(date.weekday);
  final String month = _monthNames[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}

String formatMonthYear(DateTime month) {
  return '${_monthNames[month.month - 1]} ${month.year}';
}

String formatWeekdayShort(DateTime date) => _weekdayShort[date.weekday - 1];

String _weekdayLong(int weekday) {
  const List<String> names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

/// 12-hour clock, e.g. "5:30 AM".
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

/// 24-hour clock with seconds, e.g. "12:50:00".
String formatTime24hWithSeconds(int minutesSinceMidnight, {int seconds = 0}) {
  final int hour = minutesSinceMidnight ~/ 60;
  final int minute = minutesSinceMidnight % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Live countdown HH:MM:SS until [target].
String formatCountdownHms(DateTime now, DateTime target) {
  Duration remaining = target.difference(now);
  if (remaining.isNegative) {
    remaining = Duration.zero;
  }
  final int hours = remaining.inHours;
  final int minutes = remaining.inMinutes.remainder(60);
  final int secs = remaining.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}';
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isFriday(DateTime date) => date.weekday == DateTime.friday;

IconData iconForPrayer(String name) {
  final String lower = name.toLowerCase();
  if (lower.contains('fajr')) {
    return Icons.wb_twilight_rounded;
  }
  if (lower.contains('sunrise')) {
    return Icons.wb_twilight_rounded;
  }
  if (lower.contains('dhuhr') || lower.contains('zuhr')) {
    return Icons.wb_sunny_rounded;
  }
  if (lower.contains('asr')) {
    return Icons.wb_cloudy_rounded;
  }
  if (lower.contains('maghrib')) {
    return Icons.wb_twilight_outlined;
  }
  if (lower.contains('isha')) {
    return Icons.nightlight_round_rounded;
  }
  return Icons.access_time_rounded;
}

/// Index of the prayer row to highlight as current/next, or -1.
int indexOfHighlightedPrayer(
  List<PrayerTime> prayers,
  PrayerTime? next,
) {
  if (next == null) {
    return -1;
  }
  final int identityIndex =
      prayers.indexWhere((PrayerTime p) => identical(p, next));
  if (identityIndex != -1) {
    return identityIndex;
  }
  final int valueIndex = prayers.indexWhere((PrayerTime p) => p == next);
  if (valueIndex != -1) {
    return valueIndex;
  }
  return prayers.indexWhere(
    (PrayerTime p) =>
        p.name == next.name &&
        p.minutesSinceMidnight == next.minutesSinceMidnight,
  );
}
