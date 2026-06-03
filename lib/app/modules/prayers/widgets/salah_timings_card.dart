import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../prayer_format.dart';

/// White card listing salah rows with Athan and Iqamah columns.
class SalahTimingsCard extends StatelessWidget {
  const SalahTimingsCard({
    super.key,
    required this.prayers,
    required this.highlightIndex,
  });

  final List<PrayerTime> prayers;
  final int highlightIndex;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Salah Timings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    'SALAH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ATHAN',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'IQAMAH',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List<Widget>.generate(prayers.length, (int index) {
            final PrayerTime prayer = prayers[index];
            final bool highlighted = index == highlightIndex;
            return _SalahRow(
              prayer: prayer,
              highlighted: highlighted,
              scheme: scheme,
              theme: theme,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SalahRow extends StatelessWidget {
  const _SalahRow({
    required this.prayer,
    required this.highlighted,
    required this.scheme,
    required this.theme,
  });

  final PrayerTime prayer;
  final bool highlighted;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: highlighted
              ? Border.all(color: scheme.primary.withValues(alpha: 0.45))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Row(
                  children: <Widget>[
                    Icon(
                      iconForPrayer(prayer.name),
                      size: 22,
                      color: highlighted
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prayer.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: highlighted
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatTime12h(prayer.minutesSinceMidnight),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  prayer.hasIqamah
                      ? formatTime12h(prayer.iqamahMinutesSinceMidnight!)
                      : '—',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: highlighted
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return row;
  }
}
