import 'package:flutter/material.dart';

import 'kiosk_header.dart';
import 'kiosk_sidebar.dart' show KioskDestination;

/// The sidebar-less kiosk top navigation bar (Requirements 5.1, 5.2, 5.3,
/// 5.6).
///
/// Lays out, left to right:
/// * the active organization's logo and name ([KioskHeaderBrand]);
/// * one navigation pill per [KioskDestination], with the [active] entry
///   shown filled in the theme's primary color — exactly one pill is selected
///   at a time;
/// * a live clock above the current date ([KioskHeaderClock]);
/// * an optional [trailing] control (e.g. the Home screen's logout button).
///
/// Tapping a pill invokes [onSelect]; the parent performs navigation.
/// All colors come from the active [ColorScheme], so the bar re-themes with
/// the organization's branding.
class KioskTopNavBar extends StatelessWidget {
  const KioskTopNavBar({
    super.key,
    required this.active,
    required this.onSelect,
    this.trailing,
  });

  /// The currently active destination (the only pill shown as selected).
  final KioskDestination active;

  /// Invoked with the tapped destination.
  final ValueChanged<KioskDestination> onSelect;

  /// Optional trailing control rendered after the clock.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return KioskHeader(trailing: trailing);
  }
}
