import 'package:flutter/material.dart';

/// Visual variant of a [KioskButton].
enum KioskButtonVariant {
  /// Filled, high-emphasis button using the theme's primary color.
  primary,

  /// Outlined, medium-emphasis button using the theme's secondary color.
  secondary,
}

/// A themed, reusable kiosk button (Requirement 10.6).
///
/// Supports a [KioskButtonVariant] (filled `primary` / outlined `secondary`),
/// an optional [icon], an [isLoading] state that swaps the label for a spinner
/// and blocks taps, and an explicit [isEnabled] flag. The button is only
/// interactive when it is enabled, not loading, and an [onPressed] callback is
/// provided. All colors are derived from the active [ThemeData] so the control
/// re-themes with the active organization.
///
/// Exposed under both [KioskButton] and the [CommonButton] alias.
class KioskButton extends StatelessWidget {
  const KioskButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KioskButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.expand = false,
  });

  /// Text rendered on the button.
  final String label;

  /// Tap handler. When null (or [isEnabled] is false, or [isLoading] is true)
  /// the button is non-interactive.
  final VoidCallback? onPressed;

  /// Filled (`primary`) or outlined (`secondary`) treatment.
  final KioskButtonVariant variant;

  /// While true, the label is replaced by a spinner and taps are blocked.
  final bool isLoading;

  /// Explicit enable flag; when false the button renders disabled.
  final bool isEnabled;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  /// When true, the button stretches to fill the available horizontal space.
  final bool expand;

  /// Whether the button currently reacts to taps.
  bool get _isInteractive => isEnabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final VoidCallback? handler = _isInteractive ? onPressed : null;

    final Widget child = _buildChild(scheme);
    final Widget button = variant == KioskButtonVariant.primary
        ? _buildPrimary(scheme, handler, child)
        : _buildSecondary(scheme, handler, child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildPrimary(
    ColorScheme scheme,
    VoidCallback? handler,
    Widget child,
  ) {
    return ElevatedButton(
      onPressed: handler,
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.primary.withValues(alpha: 0.38),
        disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.70),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }

  Widget _buildSecondary(
    ColorScheme scheme,
    VoidCallback? handler,
    Widget child,
  ) {
    return OutlinedButton(
      onPressed: handler,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.secondary,
        disabledForegroundColor: scheme.secondary.withValues(alpha: 0.38),
        side: BorderSide(
          color: _isInteractive
              ? scheme.secondary
              : scheme.secondary.withValues(alpha: 0.38),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }

  Widget _buildChild(ColorScheme scheme) {
    if (isLoading) {
      final Color spinnerColor = variant == KioskButtonVariant.primary
          ? scheme.onPrimary
          : scheme.secondary;
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    }

    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

/// Alias for [KioskButton], matching the "CommonButton" name used in the
/// centralized-architecture requirement (Requirement 10.6).
typedef CommonButton = KioskButton;
