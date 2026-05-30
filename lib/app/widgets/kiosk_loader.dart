import 'package:flutter/material.dart';

/// A centered, themed loading indicator (Requirement 10.6).
///
/// Renders a [CircularProgressIndicator] tinted with the active theme's primary
/// color, with an optional [message] beneath it. Used wherever the kiosk needs
/// a simple "working" indicator (as opposed to the section-shaped
/// `ShimmerLoader`).
class KioskLoader extends StatelessWidget {
  const KioskLoader({
    super.key,
    this.message,
    this.size = 40,
    this.strokeWidth = 4,
  });

  /// Optional label rendered below the spinner.
  final String? message;

  /// Diameter of the spinner in logical pixels.
  final double size;

  /// Stroke width of the spinner arc.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}
