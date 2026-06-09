import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders the Scan_To_Donate_QR card (Requirements 9.1, 9.2).
///
/// When a non-empty [donationUrl] is provided, the card renders a real QR code
/// (via [QrImageView]) encoding exactly that URL, plus a short caption inviting
/// the visitor to scan and donate from their phone (Req 9.1).
///
/// When [donationUrl] is null or blank, the card displays an unavailable-state
/// message and renders no QR code (Req 9.2). The Home view routes the empty QR
/// section state to its own empty-state, but this widget also handles a
/// null/blank URL defensively so it is correct in isolation.
class ScanToDonateCard extends StatelessWidget {
  const ScanToDonateCard({
    super.key,
    required this.donationUrl,
    this.size = 140,
    this.showUrl = true,
    this.showCaption = true,
  });

  /// The active organization's donation URL to encode, or null/blank when no
  /// donation URL is configured.
  final String? donationUrl;

  /// The side length of the rendered QR code in logical pixels.
  final double size;

  /// Whether to show the URL text under the caption (use false for sidebar).
  final bool showUrl;

  /// Whether to show the default scan caption below the QR code.
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final String? url = donationUrl;
    if (url == null || url.trim().isEmpty) {
      return const _QrUnavailable();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String trimmed = url.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // White quiet-zone backing keeps the QR scannable regardless of the
        // active organization's surface color.
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: QrImageView(
            data: trimmed,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            // Use a dark foreground for reliable scanning contrast.
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF000000),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF000000),
            ),
          ),
        ),
        if (showCaption) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Scan to donate',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
        if (showUrl) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// The unavailable state shown when no donation URL is configured (Req 9.2).
/// Renders an explanatory message and no QR code.
class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.qr_code_2_rounded,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan-to-Donate is unavailable.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
