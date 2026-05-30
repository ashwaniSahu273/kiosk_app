import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/models/models.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/widgets.dart';

/// Renders the loaded Donation Categories section (Requirements 8.1, 8.3).
///
/// Each [DonationCategory] is shown with its name and a Donate control.
/// Selecting Donate navigates to the donation entry point for *that* category,
/// passing the category as the route argument so the destination screen
/// (Task 16) can render the donation flow for the selected category
/// (Req 8.2 — `Get.toNamed(AppRoutes.donate, arguments: category)`).
///
/// This widget renders the *non-empty* list only; the empty-state — which
/// shows a disabled, grayed-out Donate control (Req 8.3) — is handled by the
/// Home view.
class DonationsSection extends StatelessWidget {
  const DonationsSection({
    super.key,
    required this.categories,
    this.onDonate,
  });

  /// The active organization's donation categories to display (non-empty).
  final List<DonationCategory> categories;

  /// Optional override for the Donate action; defaults to navigating to the
  /// donation entry point for the selected category.
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
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final DonationCategory category in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                KioskButton(
                  label: 'Donate',
                  icon: Icons.volunteer_activism_rounded,
                  variant: KioskButtonVariant.secondary,
                  onPressed: () => _donate(category),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
