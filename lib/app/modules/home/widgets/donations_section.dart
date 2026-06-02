import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/models/models.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/widgets.dart';

/// Renders the loaded Donation Categories section (Requirements 8.1, 8.3).
///
/// Each [DonationCategory] is shown as a horizontal campaign card with Share and
/// Donate actions. Selecting Donate navigates to the donation entry point for
/// that category (Req 8.2).
class DonationsSection extends StatelessWidget {
  const DonationsSection({
    super.key,
    required this.categories,
    this.onDonate,
  });

  final List<DonationCategory> categories;
  final void Function(DonationCategory category)? onDonate;

  void _donate(DonationCategory category) {
    if (onDonate != null) {
      onDonate!(category);
      return;
    }
    Get.toNamed<void>(AppRoutes.donate, arguments: category);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (BuildContext context, int index) {
        final DonationCategory category = categories[index];
        return SizedBox(
          width: 280,
          child: DonationCampaignCard(
            category: category,
            compact: true,
            onDonate: () => _donate(category),
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link for ${category.name} copied.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
