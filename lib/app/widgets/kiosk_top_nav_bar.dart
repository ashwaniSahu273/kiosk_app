import 'package:flutter/material.dart';

import 'kiosk_header.dart';
import 'kiosk_sidebar.dart' show KioskDestination;

/// The sidebar-less kiosk top navigation bar (Requirements 5.1, 5.2, 5.3,
/// 5.6).
///
/// Lays out, left to right inside a single framed bar:
/// * the active organization's logo and name ([KioskHeaderBrand]);
/// * one navigation pill per [KioskDestination], with the [active] entry
///   shown filled in the theme's primary color — exactly one pill is selected
///   at a time;
/// * a live clock above the current date ([KioskHeaderStatusStrip]);
/// * an optional [trailing] control (e.g. the Home screen's logout button).
///
/// Tapping a pill invokes [onSelect]; the parent performs navigation. Because
/// every kiosk screen routes through this bar, the pill row gives every screen
/// a consistent way back to Home and across destinations.
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

  bool get _isHome => active == KioskDestination.home;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const KioskHeaderBrand(),
          const SizedBox(width: 20),
          if (_isHome) ...<Widget>[
            const Spacer(),
            const KioskHeaderStatusStrip(),
          ] else ...<Widget>[
            Expanded(
              child: Center(
                child: _NavPillBar(active: active, onSelect: onSelect),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// The horizontal row of destination pills, exactly one shown as selected.
class _NavPillBar extends StatelessWidget {
  const _NavPillBar({required this.active, required this.onSelect});

  final KioskDestination active;
  final ValueChanged<KioskDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final KioskDestination destination in KioskDestination.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _NavPill(
                destination: destination,
                isSelected: destination == active,
                onTap: () => onSelect(destination),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single navigation pill (icon + label). Filled in the primary color when
/// selected; a subtle outlined surface otherwise.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final KioskDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(10);

    final Color background =
        isSelected ? scheme.primary : scheme.primary.withValues(alpha: 0.06);
    final Color foreground =
        isSelected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.78);
    final Color borderColor = isSelected
        ? scheme.primary
        : scheme.outline.withValues(alpha: 0.20);

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(destination.icon, color: foreground, size: 20),
                const SizedBox(width: 8),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
