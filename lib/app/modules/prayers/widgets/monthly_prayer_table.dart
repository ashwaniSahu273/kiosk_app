import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../prayer_format.dart';
import '../prayer_schedule_builder.dart';

/// Scrollable monthly grid with Athan / Iqamah per prayer column.
class MonthlyPrayerTable extends StatelessWidget {
  const MonthlyPrayerTable({
    super.key,
    required this.days,
    required this.today,
  });

  final List<PrayerDaySchedule> days;
  final DateTime today;

  static const List<String> _columns = <String>[
    'Day',
    'Fajir',
    'Sunrise',
    'Dhuhar',
    'Asr',
    'Maghrit',
    'Isha',
  ];

  static const List<String> _prayerKeys = <String>[
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              color: scheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: _columns.map((String label) {
                  return Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Container(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: List<Widget>.generate(_columns.length, (int col) {
                  if (col == 0) {
                    return const Expanded(child: SizedBox.shrink());
                  }
                  return Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Athan',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                        if (_prayerKeys[col - 1] != 'Sunrise')
                          Text(
                            'Iqamah',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (BuildContext context, int index) {
                  final PrayerDaySchedule day = days[index];
                  final bool isToday = isSameCalendarDay(day.date, today);
                  final bool isFridayRow = isFriday(day.date);
                  final Color rowColor = isToday
                      ? scheme.primary.withValues(alpha: 0.12)
                      : (index.isEven
                          ? scheme.surface
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35));

                  return Container(
                    color: rowColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _DayCell(
                          date: day.date,
                          isToday: isToday,
                          isFriday: isFridayRow,
                          scheme: scheme,
                          theme: theme,
                        )),
                        ..._prayerKeys.map((String key) {
                          final PrayerTime? prayer = _findPrayer(day.prayers, key);
                          return Expanded(
                            child: _TimeCell(prayer: prayer, scheme: scheme, theme: theme),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PrayerTime? _findPrayer(List<PrayerTime> prayers, String key) {
    for (final PrayerTime p in prayers) {
      if (p.name.toLowerCase() == key.toLowerCase()) {
        return p;
      }
    }
    return null;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isFriday,
    required this.scheme,
    required this.theme,
  });

  final DateTime date;
  final bool isToday;
  final bool isFriday;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isToday
        ? scheme.primary
        : (isFriday ? Colors.red.shade700 : scheme.onSurface);

    return Column(
      children: <Widget>[
        Text(
          '${date.day}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        Text(
          formatWeekdayShort(date),
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isToday)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'TODAY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.prayer,
    required this.scheme,
    required this.theme,
  });

  final PrayerTime? prayer;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (prayer == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: <Widget>[
        Text(
          formatTime12h(prayer!.minutesSinceMidnight),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        if (prayer!.hasIqamah)
          Text(
            formatTime12h(prayer!.iqamahMinutesSinceMidnight!),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
      ],
    );
  }
}
