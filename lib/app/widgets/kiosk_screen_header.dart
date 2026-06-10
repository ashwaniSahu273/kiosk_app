import 'package:flutter/material.dart';

/// A themed hero header band for destination list screens (Donate, Events,
/// Programs, Prayers).
///
/// Renders a leading icon chip, a title with an optional subtitle/count line,
/// and an optional trailing [action] slot, over a subtle primary-tinted
/// gradient consistent with [SectionCard] / the kiosk top bar. All colors come
/// from the active [ColorScheme] so the band re-themes with the organization.
class KioskScreenHeader extends StatelessWidget {
  const KioskScreenHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.action,
  });

  /// The screen title (e.g. "Donation Campaigns").
  final String title;

  /// The leading icon shown inside the rounded chip.
  final IconData icon;

  /// Optional secondary line, typically an item count (e.g. "12 campaigns").
  final String? subtitle;

  /// Optional trailing control (e.g. a refresh or back action).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.12),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: scheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(width: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
