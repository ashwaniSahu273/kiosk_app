import 'package:flutter/material.dart';

import 'kiosk_header.dart';
import 'kiosk_sidebar.dart' show KioskDestination;

/// The sidebar-less kiosk top navigation bar (Requirements 5.1, 5.2, 5.3,
/// 5.6).
///
/// Lays out, left to right:
/// * the active organization's logo and name ([KioskHeaderBrand]);
/// * one navigation pill per [KioskDestination], with the [active] entry
///   shown filled in the theme's primary color — exactly one pill is selected
///   at a time;
/// * a live clock above the current date ([KioskHeaderClock]);
/// * an optional [trailing] control (e.g. the Home screen's logout button).
///
/// Tapping a pill invokes [onSelect]; the parent performs navigation.
/// All colors come from the active [ColorScheme], so the bar re-themes with
/// the organization's branding.
class KioskTopNavBar extends StatelessWidget {
  const KioskTopNavBar({
    super.key,
    required this.active,
    required this.onSelect,
    this.trailing,
  });

  /// The currently active destination (the only pill shown as selected).
  final KioskDestination active;

  /// Invoked with the tapped destination.
  final ValueChanged<KioskDestination> onSelect;

  /// Optional trailing control rendered after the clock.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Flexible(child: KioskHeaderBrand(logoSize: 48)),
          const SizedBox(width: 16),

          // ---- Centered navigation pills ----
          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final KioskDestination destination
                      in KioskDestination.values) ...<Widget>[
                    _NavPill(
                      destination: destination,
                      isSelected: destination == active,
                      onTap: () => onSelect(destination),
                    ),
                    if (destination != KioskDestination.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          const KioskHeaderClock(),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A single navigation pill. Renders a primary-filled background only when
/// [isSelected] is true; state changes animate over 180 ms.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final KioskDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 180);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground =
        isSelected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.70);

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: foreground),
                  duration: _duration,
                  curve: _curve,
                  builder:
                      (BuildContext context, Color? color, Widget? child) =>
                          Icon(destination.icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  curve: _curve,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(destination.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
