import 'package:flutter/material.dart';

/// A framed container used to frame Home_Screen sections (Requirement 10.6).
///
/// Applies the palos-style card decoration: rounded corners, the theme surface
/// background, and a subtle shadow. It exposes a [title] header slot (with an
/// optional leading [icon] and a trailing [action] slot) above the [child]
/// content area, so each home section (Next Prayer, Programs, Donations,
/// Scan-to-Donate) shares one consistent frame.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.expandChild = false,
  });

  /// Optional header title. When null, no header row is rendered.
  final String? title;

  /// Optional leading icon shown before the [title].
  final IconData? icon;

  /// Optional trailing widget in the header (e.g. a "see all" / retry control).
  final Widget? action;

  /// The card's content area.
  final Widget child;

  /// Inner padding around the header and content.
  final EdgeInsetsGeometry padding;

  /// When true, the content area expands to fill available vertical space
  /// (useful inside a fixed-height landscape column).
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        if (title != null) ...<Widget>[
          _buildHeader(theme, scheme),
          const SizedBox(height: 16),
        ],
        if (expandChild) Expanded(child: child) else child,
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(padding: padding, child: content),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme) {
    final TextStyle titleStyle =
        (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );

    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title!.toUpperCase(),
            style: titleStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
