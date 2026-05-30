import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography for the kiosk, built on the Poppins typeface
/// (Requirement 4, Requirement 10.5).
///
/// [ThemeEngine] uses [textTheme] to populate the per-organization
/// [ThemeData], so all kiosk screens share one font family while still
/// adopting each organization's colors. Color is intentionally left unset on
/// these base styles; the framework merges the theme's `onSurface`/`onPrimary`
/// colors when the styles are applied.
class KioskTextStyles {
  const KioskTextStyles._();

  /// Poppins applied across the entire Material [TextTheme].
  ///
  /// Built from [ThemeData.fallback]'s text theme so every text role
  /// (display, headline, title, body, label) is present and sized sensibly for
  /// a large landscape kiosk viewport.
  static TextTheme get textTheme {
    final TextTheme base = Typography.material2021(
      platform: TargetPlatform.android,
    ).black;
    return GoogleFonts.poppinsTextTheme(base);
  }

  /// Poppins [TextStyle] for the large clock shown in the kiosk header.
  static TextStyle get clock => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      );

  /// Poppins [TextStyle] for the organization display name in the header.
  static TextStyle get orgTitle => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      );

  /// Poppins [TextStyle] for section headers (e.g. "Available Programs").
  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      );
}
