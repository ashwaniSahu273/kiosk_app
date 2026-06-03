import 'package:flutter/material.dart';

/// Elevated frame so campaign cards stand out from [SectionCard] backgrounds.
class CampaignCardFrame extends StatelessWidget {
  const CampaignCardFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Card surface and soft layered shadow (no border).
  static BoxDecoration decoration(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;
    final Color surface = isLight
        ? Colors.white
        : scheme.surfaceContainerHigh;

    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 28,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.1),
          blurRadius: 18,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration(context),
      child: child,
    );
  }
}

/// Soft inset behind a campaign card grid so tiles pop off the section surface.
class CampaignListCanvas extends StatelessWidget {
  const CampaignListCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
