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
    this.fillHeight = false,
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

  /// Expands to fill the Home [SectionCard] content area.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final NextPrayerResult? resolved = next;
    final bool showCountdown = hasCountdown && resolved != null;

    final int highlightIndex = resolved == null
        ? -1
        : _indexOfNext(schedule.prayers, resolved.prayer);

    final Widget hero = showCountdown
        ? _NextPrayerHero(
            prayerName: resolved.prayer.name,
            isNextDay: resolved.isNextDay,
            countdownLabel: countdownLabel,
            fillHeight: fillHeight,
          )
        : _ScheduleHeader(fillHeight: fillHeight);

    final Widget strip = _PrayerScheduleStrip(
      prayers: schedule.prayers,
      highlightIndex: highlightIndex,
      fillHeight: fillHeight,
    );

    if (fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showCountdown)
            Expanded(flex: 3, child: hero)
          else ...<Widget>[
            hero,
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Expanded(flex: 2, child: strip),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        hero,
        const SizedBox(height: 14),
        strip,
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

/// Gradient feature block for the upcoming prayer and live countdown.
class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero({
    required this.prayerName,
    required this.isNextDay,
    required this.countdownLabel,
    this.fillHeight = false,
  });

  final String prayerName;
  final bool isNextDay;
  final String countdownLabel;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return _buildHero(context);
  }

  Widget _buildHero(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ({int hours, int minutes})? parts = _parseCountdown(countdownLabel);

    final Widget? countdownRow = parts != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _CountdownUnit(
                  value: parts.hours,
                  unit: 'hours',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountdownUnit(
                  value: parts.minutes,
                  unit: 'mins',
                ),
              ),
            ],
          )
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(fillHeight ? 12 : 16),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: _gradient(scheme)),
        child: Stack(
          fit: fillHeight ? StackFit.expand : StackFit.loose,
          children: <Widget>[
            Positioned(
              right: -8,
              top: -12,
              child: Icon(
                Icons.mosque_rounded,
                size: fillHeight ? 120 : 96,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, fillHeight ? 10 : 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (fillHeight)
                    Flexible(
                      fit: FlexFit.loose,
                      child: LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          final double maxH = constraints.maxHeight;
                          if (!maxH.isFinite || maxH <= 0) {
                            return const SizedBox.shrink();
                          }
                          return ClipRect(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: maxH,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _HeroBadges(isNextDay: isNextDay),
                                    const SizedBox(height: 6),
                                    Text(
                                      prayerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Time remaining',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else ...<Widget>[
                    _HeroBadges(isNextDay: isNextDay),
                    const SizedBox(height: 10),
                    Text(
                      prayerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time remaining',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (countdownRow != null) ...<Widget>[
                    SizedBox(height: fillHeight ? 6 : 10),
                    if (fillHeight)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: countdownRow,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      countdownRow,
                  ] else if (!fillHeight)
                    Text(
                      countdownLabel,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static LinearGradient _gradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        scheme.primary,
        Color.lerp(scheme.primary, scheme.secondary, 0.45) ?? scheme.secondary,
      ],
    );
  }

  static ({int hours, int minutes})? _parseCountdown(String label) {
    final RegExp pattern = RegExp(r'^(\d+)h (\d+)m$');
    final RegExpMatch? match = pattern.firstMatch(label.trim());
    if (match == null) {
      return null;
    }
    return (
      hours: int.parse(match.group(1)!),
      minutes: int.parse(match.group(2)!),
    );
  }
}

class _HeroBadges extends StatelessWidget {
  const _HeroBadges({required this.isNextDay});

  final bool isNextDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Next Prayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isNextDay) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Tomorrow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({
    required this.value,
    required this.unit,
  });

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value.toString().padLeft(2, '0'),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple header when the live countdown is not shown.
class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({this.fillHeight = false});

  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(Icons.calendar_today_rounded, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          "Today's schedule",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Horizontal strip of prayer time chips for the full day.
class _PrayerScheduleStrip extends StatelessWidget {
  const _PrayerScheduleStrip({
    required this.prayers,
    required this.highlightIndex,
    this.fillHeight = false,
  });

  final List<PrayerTime> prayers;
  final int highlightIndex;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(prayers.length, (int index) {
        final PrayerTime prayer = prayers[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == prayers.length - 1 ? 0 : 8,
            ),
            child: _PrayerChip(
              prayer: prayer,
              isNext: index == highlightIndex,
              fillHeight: fillHeight,
            ),
          ),
        );
      }),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({
    required this.prayer,
    required this.isNext,
    this.fillHeight = false,
  });

  final PrayerTime prayer;
  final bool isNext;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final IconData icon = _iconForPrayer(prayer.name);

    final BoxDecoration decoration = isNext
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                scheme.primary.withValues(alpha: 0.14),
                scheme.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.2),
            ),
          );

    final double iconSize = fillHeight ? (isNext ? 22 : 20) : (isNext ? 20 : 18);

    final Widget chipContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: iconSize,
          color: isNext
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.45),
        ),
        SizedBox(height: fillHeight ? 6 : 6),
        Text(
          prayer.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
            color: isNext
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.72),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatTimeOfDay(prayer.minutesSinceMidnight),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isNext
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.55),
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
        if (isNext) ...<Widget>[
          SizedBox(height: fillHeight ? 6 : 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: fillHeight ? 6 : 10,
        ),
        child: fillHeight
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: chipContent,
              )
            : chipContent,
      ),
    );
  }

  static IconData _iconForPrayer(String name) {
    final String lower = name.toLowerCase();
    if (lower.contains('fajr')) {
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
