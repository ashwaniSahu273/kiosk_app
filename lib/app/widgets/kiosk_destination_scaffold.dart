import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import 'kiosk_header.dart';
import 'kiosk_sidebar.dart';
import 'kiosk_sidebar_scan_footer.dart';

/// Shared landscape scaffold for the kiosk destination screens — Donate,
/// Prayers, and Programs (Requirements 5.3, 5.5, 5.6).
///
/// Lays out the [KioskSidebar] (with [active] shown as the only selected
/// destination) beside a [KioskHeader] and the destination's [child] content,
/// reusing the same framing as the Home_Screen so every destination is themed
/// consistently with the active organization's branding.
///
/// Sidebar navigation (Requirement 5.5 — completes within 1s via instant GetX
/// named navigation):
/// * selecting the already-active destination is a no-op;
/// * selecting Home pops back to the Home_Screen that sits beneath the
///   destination stack;
/// * selecting another destination replaces the current destination route
///   (via `Get.offNamed`) so destinations never stack on top of one another.
class KioskDestinationScaffold extends StatelessWidget {
  const KioskDestinationScaffold({
    super.key,
    required this.active,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  /// The destination this screen represents; rendered as the sole selected
  /// sidebar entry (Requirement 5.6).
  final KioskDestination active;

  /// The destination's content area.
  final Widget child;

  /// Inner padding applied around [child].
  final EdgeInsetsGeometry padding;

  void _select(KioskDestination destination) {
    if (destination == active) {
      return; // Already here; no navigation needed.
    }
    switch (destination) {
      case KioskDestination.home:
        // Pop back to the Home_Screen sitting at the base of the stack rather
        // than pushing a second Home instance.
        Get.until((Route<dynamic> route) =>
            route.settings.name == AppRoutes.home || route.isFirst);
        return;
      case KioskDestination.donate:
        Get.offNamed<void>(AppRoutes.donate);
        return;
      case KioskDestination.prayers:
        Get.offNamed<void>(AppRoutes.prayers);
        return;
      case KioskDestination.programs:
        Get.offNamed<void>(AppRoutes.programs);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ---- Left sidebar (this destination selected) ----
            KioskSidebar(
              active: active,
              onSelect: _select,
              footer: const KioskSidebarScanFooter(),
            ),

            // ---- Right: header + content ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const KioskHeader(),
                  Expanded(
                    child: Padding(
                      padding: padding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
