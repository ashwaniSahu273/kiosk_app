import 'package:flutter/material.dart';

/// The Sidebar_Navigation destinations (Requirement 5.3).
///
/// Ordered as they appear top-to-bottom in the kiosk sidebar.
enum KioskDestination {
  /// The kiosk Home_Screen.
  home,

  /// The Donate destination.
  donate,

  /// The Prayers destination.
  prayers,

  /// The Programs destination.
  programs;

  /// Human-readable label shown beside the icon.
  String get label {
    switch (this) {
      case KioskDestination.home:
        return 'Home';
      case KioskDestination.donate:
        return 'Donate';
      case KioskDestination.prayers:
        return 'Prayers';
      case KioskDestination.programs:
        return 'Programs';
    }
  }

  /// Icon shown for the destination.
  IconData get icon {
    switch (this) {
      case KioskDestination.home:
        return Icons.home_rounded;
      case KioskDestination.donate:
        return Icons.volunteer_activism_rounded;
      case KioskDestination.prayers:
        return Icons.mosque_rounded;
      case KioskDestination.programs:
        return Icons.event_rounded;
    }
  }
}

/// The left-hand kiosk navigation listing Home, Donate, Prayers, and Programs
/// (Requirements 5.3, 5.6).
///
/// Exactly one destination is selected at a time: the entry matching [active]
/// shows the selected-state indication and every other entry shows none, so
/// selection is mutually exclusive by construction. Tapping an entry invokes
/// [onSelect] with the chosen [KioskDestination]; the parent is responsible for
/// updating [active] and performing navigation.
class KioskSidebar extends StatelessWidget {
  const KioskSidebar({
    super.key,
    required this.active,
    required this.onSelect,
    this.width = 320,
    this.footer,
  });

  /// The currently active destination (the only one shown as selected).
  final KioskDestination active;

  /// Invoked with the tapped destination.
  final ValueChanged<KioskDestination> onSelect;

  /// Optional footer displayed at the bottom of the sidebar.
  final Widget? footer;

  /// Fixed sidebar width in logical pixels.
  final double width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: width,
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final KioskDestination destination in KioskDestination.values)
            _SidebarItem(
              destination: destination,
              isSelected: destination == active,
              onTap: () => onSelect(destination),
            ),
          if (footer != null) ...[
            const Spacer(),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// A single sidebar entry. Renders a selected-state background and accent bar
/// only when [isSelected] is true.
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
    final Color onPrimary = scheme.onPrimary;
    final Color selectedBackground = onPrimary.withValues(alpha: 0.18);
    final Color foreground =
        isSelected ? onPrimary : onPrimary.withValues(alpha: 0.78);

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? selectedBackground : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? onPrimary : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: foreground),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, Color? color, Widget? child) =>
                      Icon(destination.icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      destination.label,
                      overflow: TextOverflow.ellipsis,
                    ),
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
