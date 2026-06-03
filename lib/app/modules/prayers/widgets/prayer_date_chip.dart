import 'package:flutter/material.dart';

import '../prayer_format.dart';

/// Rounded date pill with optional calendar icon.
class PrayerDateChip extends StatelessWidget {
  const PrayerDateChip({
    super.key,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget chip = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.calendar_month_rounded,
                size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: chip,
      ),
    );
  }
}

/// Chevron row for picking a day (Daily tab).
class PrayerDayNavigator extends StatelessWidget {
  const PrayerDayNavigator({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left_rounded, color: scheme.primary),
        ),
        Expanded(
          child: Center(
            child: PrayerDateChip(
              label: formatLongDate(date),
              onTap: onPickDate,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: scheme.primary),
        ),
      ],
    );
  }
}

/// Month selector row for the Monthly tab.
class PrayerMonthNavigator extends StatelessWidget {
  const PrayerMonthNavigator({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        PrayerDateChip(
          label: formatMonthYear(month),
          onTap: onPickMonth,
          compact: true,
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _LegendDot(color: scheme.onSurface, label: 'Athan'),
            const SizedBox(width: 16),
            _LegendDot(color: scheme.primary, label: 'Iqamah'),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left_rounded, color: scheme.primary),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: scheme.primary),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
