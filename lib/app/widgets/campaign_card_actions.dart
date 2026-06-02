import 'package:flutter/material.dart';

import 'kiosk_button.dart';

/// Share / primary action row used on donation and program campaign cards.
class CampaignCardActions {
  CampaignCardActions._();

  static Widget share({
    required bool compact,
    required VoidCallback onPressed,
  }) {
    if (compact) {
      return _CompactCampaignButton.secondary(
        label: 'Share',
        icon: Icons.share_rounded,
        onPressed: onPressed,
      );
    }
    return KioskButton(
      label: 'Share',
      icon: Icons.share_rounded,
      variant: KioskButtonVariant.secondary,
      onPressed: onPressed,
    );
  }

  static Widget register({
    required bool compact,
    required VoidCallback onPressed,
  }) {
    if (compact) {
      return _CompactCampaignButton.primary(
        label: 'Register',
        icon: Icons.app_registration_rounded,
        onPressed: onPressed,
      );
    }
    return KioskButton(
      label: 'Register',
      icon: Icons.app_registration_rounded,
      onPressed: onPressed,
    );
  }

  static Widget donate({
    required bool compact,
    required VoidCallback onPressed,
  }) {
    if (compact) {
      return _CompactCampaignButton.primary(
        label: 'Donate',
        icon: Icons.volunteer_activism_rounded,
        onPressed: onPressed,
      );
    }
    return KioskButton(
      label: 'Donate',
      icon: Icons.volunteer_activism_rounded,
      onPressed: onPressed,
    );
  }
}

class _CompactCampaignButton extends StatelessWidget {
  const _CompactCampaignButton._({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  factory _CompactCampaignButton.primary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      _CompactCampaignButton._(
        label: label,
        icon: icon,
        onPressed: onPressed,
        isPrimary: true,
      );

  factory _CompactCampaignButton.secondary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      _CompactCampaignButton._(
        label: label,
        icon: icon,
        onPressed: onPressed,
        isPrimary: false,
      );

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(12);

    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }
}
