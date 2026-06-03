import '../../core/data/models/models.dart';
import 'prayer_format.dart';

/// One day in the monthly prayer calendar.
class PrayerDaySchedule {
  const PrayerDaySchedule({required this.date, required this.prayers});

  final DateTime date;
  final List<PrayerTime> prayers;
}

/// Builds daily and monthly schedules from a loaded [PrayerSchedule] template.
class PrayerScheduleBuilder {
  const PrayerScheduleBuilder._();

  /// Salah times for [date], derived from [template] with a small day offset.
  static List<PrayerTime> prayersForDate(
    DateTime date,
    PrayerSchedule template,
  ) {
    final int drift = (date.day + date.month) % 5 - 2;
    return template.prayers
        .map(
          (PrayerTime p) => PrayerTime(
            name: p.name,
            minutesSinceMidnight: _clampMinutes(p.minutesSinceMidnight + drift),
            iqamahMinutesSinceMidnight: p.iqamahMinutesSinceMidnight == null
                ? null
                : _clampMinutes(p.iqamahMinutesSinceMidnight! + drift),
          ),
        )
        .toList();
  }

  /// All days in [year]/[month] with generated salah times.
  static List<PrayerDaySchedule> monthDays(
    int year,
    int month,
    PrayerSchedule template,
  ) {
    final int lastDay = DateTime(year, month + 1, 0).day;
    return List<PrayerDaySchedule>.generate(lastDay, (int index) {
      final int day = index + 1;
      final DateTime date = DateTime(year, month, day);
      return PrayerDaySchedule(
        date: date,
        prayers: sortSalahForDisplay(prayersForDate(date, template)),
      );
    });
  }

  static int _clampMinutes(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1439) {
      return 1439;
    }
    return value;
  }
}
