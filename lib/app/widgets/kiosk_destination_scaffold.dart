import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import 'kiosk_sidebar.dart' show KioskDestination;
import 'kiosk_top_nav_bar.dart';

/// Shared landscape scaffold for every kiosk screen — Home, Donate, Prayers,
/// and Programs (Requirements 5.1, 5.3, 5.5, 5.6).
///
/// Lays out the [KioskTopNavBar] (with [active] shown as the only selected
/// destination) above the screen's [child] content, so every screen is themed
/// consistently with the active organization's branding and shares the same
/// sidebar-less top navigation.
///
/// Navigation (Requirement 5.5 — completes within 1s via instant GetX named
/// navigation):
/// * selecting the already-active destination is a no-op;
/// * selecting Home pops back to the Home_Screen that sits at the base of the
///   stack;
/// * selecting a destination from Home pushes it on top of Home (Home stays
///   at the stack base);
/// * selecting another destination from a destination replaces the current
///   route (via `Get.offNamed`) so destinations never stack on one another.
class KioskDestinationScaffold extends StatelessWidget {
  const KioskDestinationScaffold({
    super.key,
    required this.active,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.trailing,
  });

  /// The destination this screen represents; rendered as the sole selected
  /// navigation pill (Requirement 5.6).
  final KioskDestination active;

  /// The screen's content area.
  final Widget child;

  /// Inner padding applied around [child].
  final EdgeInsetsGeometry padding;

  /// Optional trailing control shown at the right edge of the top bar
  /// (e.g. the Home screen's logout button, Requirement 1.9).
  final Widget? trailing;

  void _select(KioskDestination destination) {
    if (destination == active) {
      return; // Already here; no navigation needed.
    }
    if (destination == KioskDestination.home) {
      // Pop back to the Home_Screen sitting at the base of the stack rather
      // than pushing a second Home instance.
      Get.until((Route<dynamic> route) =>
          route.settings.name == AppRoutes.home || route.isFirst);
      return;
    }

    final String route = switch (destination) {
      KioskDestination.home => AppRoutes.home,
      KioskDestination.donate => AppRoutes.donate,
      KioskDestination.prayers => AppRoutes.prayers,
      KioskDestination.programs => AppRoutes.programs,
    };

    if (active == KioskDestination.home) {
      // From Home, push the destination on top so Home stays at the base.
      Get.toNamed<void>(route);
    } else {
      // Destination → destination: replace so they never stack.
      Get.offNamed<void>(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ---- Top navigation bar (this destination selected) ----
            KioskTopNavBar(
              active: active,
              onSelect: _select,
              trailing: trailing,
            ),

            // ---- Content fills the remaining height ----
            Expanded(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
