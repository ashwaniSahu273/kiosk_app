import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The severity of a user-facing transient message. Each severity maps to a
/// distinct visual treatment (color + icon) in the single shared snackbar.
enum NotificationSeverity {
  /// A successful, confirming outcome (green).
  success,

  /// A failure or error the user should notice (red).
  error,

  /// Neutral, informational feedback (blue).
  info,

  /// A non-fatal configuration/operational warning (amber).
  warning,
}

/// Centralized entry point for **every** user-facing transient message
/// (Requirement 10.3).
///
/// All messages are routed through one private [_show] that builds the single
/// shared snackbar, styled from the active organization's [ThemeData]. This is
/// the **only** place in the app that creates a snackbar: no feature module may
/// call `Get.snackbar` / `Get.rawSnackbar` / `ScaffoldMessenger` directly, so a
/// change to the kiosk's notification look-and-feel happens in exactly one
/// place.
///
/// Registered as a long-lived [GetxService] singleton. The four severity
/// methods ([success], [error], [info], [warning]) are thin wrappers over
/// [_show]; the [warning] method's `void Function(String)` shape deliberately
/// matches `ThemeEngine.onConfigWarning`, so the bootstrap can wire
/// configuration warnings straight into this service
/// (`themeEngine.onConfigWarning = notificationService.warning`).
class NotificationService extends GetxService {
  NotificationService();

  /// How long the shared snackbar stays on screen before auto-dismissing.
  static const Duration _displayDuration = Duration(seconds: 4);

  /// How long the show/hide transition animates.
  static const Duration _animationDuration = Duration(milliseconds: 300);

  /// Displays a success message (Requirement 10.3).
  void success(String message) =>
      _show(severity: NotificationSeverity.success, message: message);

  /// Displays an error message (Requirement 10.3).
  void error(String message) =>
      _show(severity: NotificationSeverity.error, message: message);

  /// Displays an informational message (Requirement 10.3).
  void info(String message) =>
      _show(severity: NotificationSeverity.info, message: message);

  /// Displays a configuration/operational warning (Requirements 10.3, 4.8,
  /// 11.4).
  ///
  /// The signature matches `ThemeEngine.onConfigWarning` so it can be wired in
  /// as the engine's warning sink during bootstrap.
  void warning(String message) =>
      _show(severity: NotificationSeverity.warning, message: message);

  /// Builds and presents the single shared snackbar for [message], styled per
  /// [severity] and derived from the active theme.
  ///
  /// Any snackbar already on screen is dismissed first, guaranteeing that at
  /// most one shared snackbar is ever visible at a time.
  void _show({
    required NotificationSeverity severity,
    required String message,
  }) {
    final ThemeData theme = _activeTheme();
    final _SeverityStyle style = _styleFor(severity, theme);
    final Color foreground = _readableForeground(style.background);

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      messageText: Text(
        message,
        style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(style.icon, color: foreground),
      backgroundColor: style.background,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      snackPosition: SnackPosition.BOTTOM,
      duration: _displayDuration,
      animationDuration: _animationDuration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      shouldIconPulse: false,
    );
  }

  /// Resolves the [ThemeData] used to style the snackbar.
  ///
  /// Uses the active organization's theme that drives `GetMaterialApp.theme`,
  /// exposed by GetX as [Get.theme]. GetX resolves this from the nearest
  /// [Theme] in the widget tree and falls back to [ThemeData.fallback] when no
  /// context is available, so styling never throws even if no tenant theme has
  /// been applied yet.
  ThemeData _activeTheme() => Get.theme;

  /// Maps a [severity] to its background color and icon.
  ///
  /// Each severity is visually distinct. The error background is taken from the
  /// active theme's [ColorScheme.error] (theme-derived where reasonable); the
  /// success/info/warning roles use stable semantic colors so they stay
  /// recognizable across every tenant's palette.
  _SeverityStyle _styleFor(NotificationSeverity severity, ThemeData theme) {
    switch (severity) {
      case NotificationSeverity.success:
        return const _SeverityStyle(
          background: Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case NotificationSeverity.error:
        return _SeverityStyle(
          background: theme.colorScheme.error,
          icon: Icons.error_rounded,
        );
      case NotificationSeverity.info:
        return const _SeverityStyle(
          background: Color(0xFF1565C0),
          icon: Icons.info_rounded,
        );
      case NotificationSeverity.warning:
        return const _SeverityStyle(
          background: Color(0xFFF9A825),
          icon: Icons.warning_amber_rounded,
        );
    }
  }

  /// Returns black or white, whichever contrasts better against [background],
  /// so the message and icon remain legible on any severity color.
  Color _readableForeground(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

/// The visual treatment (background color + leading icon) for one
/// [NotificationSeverity].
@immutable
class _SeverityStyle {
  const _SeverityStyle({required this.background, required this.icon});

  /// Background color of the shared snackbar for this severity.
  final Color background;

  /// Leading icon shown in the shared snackbar for this severity.
  final IconData icon;
}
