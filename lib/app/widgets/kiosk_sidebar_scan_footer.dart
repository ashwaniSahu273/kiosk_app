import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/organization_context.dart';
import '../modules/home/widgets/scan_to_donate_card.dart';
import 'section_card.dart';

/// Persistent Scan-to-Donate block for the bottom of [KioskSidebar].
///
/// Reads the active organization's donation URL from [OrganizationContext] so it
/// stays visible on every destination screen (Home, Donate, Prayers, Programs),
/// not only on the Home route.
class KioskSidebarScanFooter extends StatelessWidget {
  const KioskSidebarScanFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final OrganizationContext organizationContext =
        Get.find<OrganizationContext>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final String? rawUrl = organizationContext.branding?.donationUrl;
        final String? url =
            rawUrl == null || rawUrl.trim().isEmpty ? null : rawUrl.trim();

        return SectionCard(
          title: 'Scan to Donate',
          icon: Icons.qr_code_rounded,
          padding: const EdgeInsets.all(14),
          expandChild: false,
          child: ScanToDonateCard(
            donationUrl: url,
            size: 180,
            showUrl: false,
          ),
        );
      }),
    );
  }
}
