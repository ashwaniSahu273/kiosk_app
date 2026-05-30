import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/themes/kiosk_colors.dart';
import '../../config/themes/kiosk_text_styles.dart';
import '../data/models/models.dart';

/// Signature for surfacing a configuration warning raised while building a
/// theme or resolving a logo.
///
/// [ThemeEngine] is intentionally decoupled from the concrete
/// `NotificationService` (a later task): the bootstrap wires
/// `NotificationService.warning` in here, but until then the engine degrades to
/// a no-op. This keeps the theming layer loosely coupled.
typedef ConfigWarningCallback = void Function(String message);

/// Centralized, per-organization theme builder (Requirements 4, 10.5, 11).
///
/// Generalizes a static app theme into a runtime
/// [buildTheme] that produces a [ThemeData] from a tenant's [BrandingProfile].
/// It is *total*: it returns a valid [ThemeData] for **any** profile,
/// substituting the documented default color roles ([KioskColors]) for any
/// color the profile omits (4.5, 11.2, 11.3).
///
/// Registered as a long-lived [GetxService] singleton so the bootstrap, the
/// [OrganizationContext] theme builder, and the shared `ShimmerLoader` share one
/// instance.
class ThemeEngine extends GetxService {
  ThemeEngine({ConfigWarningCallback? onConfigWarning})
      : _onConfigWarning = onConfigWarning;

  /// Bundled placeholder logo, guaranteed to load (Requirement 4.4).
  static const String defaultLogoAsset = 'assets/images/kiosk_default_logo.png';

  /// Optional sink for configuration warnings (4.8, 11.4). Replaceable so the
  /// bootstrap can route warnings to `NotificationService.warning` once that
  /// service exists, without [ThemeEngine] depending on it directly.
  ConfigWarningCallback? _onConfigWarning;

  /// Wires (or replaces) the configuration-warning sink.
  set onConfigWarning(ConfigWarningCallback? callback) =>
      _onConfigWarning = callback;

  /// The bundled default placeholder logo provider, guaranteed to load
  /// (Requirement 4.4). Exposed so the header can fall back to it from an
  /// image `errorBuilder` (see [reportLogoLoadFailure]).
  ImageProvider get defaultLogo => const AssetImage(defaultLogoAsset);

  /// Builds a valid [ThemeData] from [profile] (Requirements 4.1, 4.5, 11.2,
  /// 11.3).
  ///
  /// Every color role uses the profile's value when present and the documented
  /// default ([KioskColors]) otherwise, so the result is always a complete,
  /// coherent theme regardless of which colors the profile supplies. When a
  /// required field is missing (an empty display name), the documented defaults
  /// are still applied and a configuration warning is surfaced (11.4).
  ThemeData buildTheme(BrandingProfile profile) {
    _warnOnMissingRequiredFields(profile);

    final Color primary = _color(profile.primaryColor, KioskColors.primary);
    final Color secondary =
        _color(profile.secondaryColor, KioskColors.secondary);
    final Color accent = _color(profile.accentColor, KioskColors.accent);
    final Color scaffold = _color(
      profile.scaffoldBackgroundColor,
      KioskColors.scaffoldBackground,
    );

    final ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: KioskColors.onPrimary,
      secondary: secondary,
      onSecondary: KioskColors.onPrimary,
      tertiary: accent,
      onTertiary: KioskColors.onPrimary,
      error: KioskColors.error,
      onError: KioskColors.onPrimary,
      surface: KioskColors.surface,
      onSurface: KioskColors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffold,
      textTheme: KioskTextStyles.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: KioskColors.onPrimary,
      ),
    );
  }

  /// Resolves the [ImageProvider] for the organization's logo (Requirements
  /// 4.3, 4.4).
  ///
  /// Returns a [NetworkImage] when [BrandingProfile.logoRef] is an http(s) URL,
  /// an [AssetImage] when it is a bundled asset path, and the guaranteed
  /// bundled placeholder ([defaultLogo]) when the profile omits the logo
  /// reference. A *load* failure of the resolved provider is reported by the
  /// rendering widget via [reportLogoLoadFailure] (4.8).
  ImageProvider resolveLogo(BrandingProfile profile) {
    final String? ref = profile.logoRef;
    if (ref == null || ref.trim().isEmpty) {
      return defaultLogo;
    }
    if (_isNetworkRef(ref)) {
      return NetworkImage(ref);
    }
    return AssetImage(ref);
  }

  /// Reports that the active profile's logo failed to load and returns the
  /// guaranteed placeholder to render in its place (Requirement 4.8).
  ///
  /// Intended to be called from an image `errorBuilder` so the kiosk both
  /// recovers visually (placeholder) and surfaces a configuration warning.
  ImageProvider reportLogoLoadFailure(BrandingProfile profile) {
    _warn(
      'Logo for "${profile.displayName}" (org ${profile.organizationId}) '
      'failed to load; using the default placeholder logo.',
    );
    return defaultLogo;
  }

  /// Derives the shimmer placeholder's base and highlight colors from [theme]
  /// (Requirements 13.6, 13.7).
  ///
  /// Deterministic: the base and highlight are fixed blends of the theme's
  /// `onSurface` over its `surface`, so the same theme always yields the same
  /// [ShimmerColors] and every shimmer reflects the active tenant's branding.
  ShimmerColors shimmerColorsFor(ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    final Color base = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.12),
      scheme.surface,
    );
    final Color highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.04),
      scheme.surface,
    );
    return ShimmerColors(base: base, highlight: highlight);
  }

  /// Returns the [Color] for a nullable ARGB [value], or [fallback] when null.
  Color _color(int? value, Color fallback) =>
      value == null ? fallback : Color(value);

  /// Whether [ref] is an absolute http(s) URL (vs. a bundled asset path).
  bool _isNetworkRef(String ref) {
    final Uri? uri = Uri.tryParse(ref);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Surfaces a configuration warning when a required field is missing (11.4).
  void _warnOnMissingRequiredFields(BrandingProfile profile) {
    if (profile.displayName.trim().isEmpty) {
      _warn(
        'Branding profile for org ${profile.organizationId} is missing a '
        'display name; default theme values were applied.',
      );
    }
  }

  /// Emits [message] through the configured warning sink, if any.
  void _warn(String message) => _onConfigWarning?.call(message);
}
