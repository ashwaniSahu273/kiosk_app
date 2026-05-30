import 'package:flutter/material.dart';

/// Documented default color roles for the kiosk theme
/// (Requirements 4.5, 4.7, 11.3).
///
/// When a [BrandingProfile] omits a color, [ThemeEngine] substitutes the
/// matching value defined here. The palette mirrors the `palos-new` reference
/// app so an organization that supplies no colors still renders with a
/// coherent, on-brand default theme.
///
/// Every role is exposed both as an ARGB [int] (`*Value`, convenient for
/// comparing against the nullable `int?` fields on a `BrandingProfile`) and as
/// a ready-to-use [Color].
class KioskColors {
  const KioskColors._();

  // ---- Documented default color roles (ARGB values) ----

  /// Primary brand color (palos-new green).
  static const int primaryValue = 0xFF2E7D32;

  /// Secondary brand color.
  static const int secondaryValue = 0xFF58BA47;

  /// Accent color used for tertiary emphasis.
  static const int accentValue = 0xFF81C784;

  /// Scaffold (page) background color.
  static const int scaffoldBackgroundValue = 0xFFF5F7FA;

  /// Surface color for cards and elevated containers.
  static const int surfaceValue = 0xFFFFFFFF;

  /// Error color.
  static const int errorValue = 0xFFC62828;

  /// Text/icon color rendered on top of the primary color.
  static const int onPrimaryValue = 0xFFFFFFFF;

  /// Text/icon color rendered on top of surfaces and the scaffold background.
  ///
  /// Not a brand-overridable role; provided so [ThemeEngine] can build a
  /// complete [ColorScheme] with legible default text.
  static const int onSurfaceValue = 0xFF1A1C1E;

  // ---- Documented default color roles (Color) ----

  /// Primary brand color (palos-new green).
  static const Color primary = Color(primaryValue);

  /// Secondary brand color.
  static const Color secondary = Color(secondaryValue);

  /// Accent color used for tertiary emphasis.
  static const Color accent = Color(accentValue);

  /// Scaffold (page) background color.
  static const Color scaffoldBackground = Color(scaffoldBackgroundValue);

  /// Surface color for cards and elevated containers.
  static const Color surface = Color(surfaceValue);

  /// Error color.
  static const Color error = Color(errorValue);

  /// Text/icon color rendered on top of the primary color.
  static const Color onPrimary = Color(onPrimaryValue);

  /// Text/icon color rendered on top of surfaces and the scaffold background.
  static const Color onSurface = Color(onSurfaceValue);
}
