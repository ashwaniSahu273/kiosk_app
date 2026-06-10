import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../widgets/widgets.dart';
import '../home/section_state.dart';
import 'donate_controller.dart';
import 'widgets/donation_detail_panel.dart';

/// The organization-scoped Donate destination screen (Requirement 8.2).
///
/// Reachable two ways, both themed consistently with the Home_Screen via the
/// shared [KioskDestinationScaffold]:
/// * from a Home "Donate" control — `Get.arguments` carries the selected
///   [DonationCategory] and the screen opens that category's donation entry
///   point directly;
/// * from the sidebar — no argument; the screen lists every donation category
///   for the active organization, each with a Donate action that opens the
///   donation entry point for that category.
///
/// The content swaps between the list and the donation panel based on the
/// controller's [DonateController.selectedCategory]; a failed/empty load shows
/// the matching error+retry / empty-state.
class DonateView extends GetView<DonateController> {
  const DonateView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.donate,
      child: Obx(() {
        final DonationCategory? selected = controller.selectedCategory.value;
        final DonationCategory? detail = controller.detailCategory.value;

        if (selected != null) {
          return _DonationPanel(
            category: selected,
            onCancel: controller.clearSelection,
            onDonate: controller.confirmDonation,
            backLabel: detail != null ? 'Back' : 'All campaigns',
          );
        }
        if (detail != null) {
          return DonationDetailPanel(
            category: detail,
            onBack: controller.clearDetail,
            onDonate: controller.startDonation,
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link for ${detail.name} copied.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        }
        return _DonationCategoriesList(controller: controller);
      }),
    );
  }
}

/// The full donation-categories list (sidebar entry point). Maps the
/// controller's [SectionState] to loading / loaded / empty / error views
/// (Requirements 8.1, 8.3).
class _DonationCategoriesList extends StatelessWidget {
  const _DonationCategoriesList({required this.controller});

  final DonateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<DonationCategory>> state =
          controller.categories.value;

      final int count = state is SectionLoaded<List<DonationCategory>>
          ? state.data.length
          : 0;

      Widget body;
      if (state is SectionLoading<List<DonationCategory>>) {
        body = const SingleChildScrollView(
          child: ShimmerLoader(shape: ShimmerShape.donationCategories),
        );
      } else if (state is SectionEmpty<List<DonationCategory>>) {
        body = const _DonationsEmptyState();
      } else if (state is SectionError<List<DonationCategory>>) {
        body = _DonationsErrorState(
          message: state.message,
          onRetry: controller.load,
        );
      } else if (state is SectionLoaded<List<DonationCategory>>) {
        body = _DonationsLoaded(
          categories: state.data,
          onOpenDetail: controller.openCategoryDetail,
          onDonate: controller.startDonation,
        );
      } else {
        body = const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          KioskScreenHeader(
            title: 'Donation Campaigns',
            icon: Icons.volunteer_activism_rounded,
            subtitle: 'Support the causes that matter to our community'
                '${count > 0 ? '  •  $count ${count == 1 ? 'campaign' : 'campaigns'}' : ''}',
          ),
          const SizedBox(height: 14),
          Expanded(child: body),
        ],
      );
    });
  }
}

/// The loaded, non-empty campaigns list with Share / Donate campaign cards
/// (Requirements 8.1, 8.2).
class _DonationsLoaded extends StatelessWidget {
  const _DonationsLoaded({
    required this.categories,
    required this.onOpenDetail,
    required this.onDonate,
  });

  final List<DonationCategory> categories;
  final ValueChanged<DonationCategory> onOpenDetail;
  final ValueChanged<DonationCategory> onDonate;

  @override
  Widget build(BuildContext context) {
    return CampaignListCanvas(
      child: KioskTwoColumnCardGrid(
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
        final DonationCategory category = categories[index];
        return DonationCampaignCard(
          category: category,
          onTap: () => onOpenDetail(category),
          onDonate: () => onDonate(category),
          onShare: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share link for ${category.name} copied.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
        },
      ),
    );
  }
}

/// Empty-state for the donation categories list. Surfaces a disabled,
/// grayed-out Donate control that is visible but non-interactive
/// (Requirement 8.3).
class _DonationsEmptyState extends StatelessWidget {
  const _DonationsEmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.volunteer_activism_outlined,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No donation categories available.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          const KioskButton(
            label: 'Donate',
            icon: Icons.volunteer_activism_rounded,
            variant: KioskButtonVariant.secondary,
            isEnabled: false,
          ),
        ],
      ),
    );
  }
}

/// Error-state for the donation categories list with a Retry control
/// (Requirement 3.6).
class _DonationsErrorState extends StatelessWidget {
  const _DonationsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 16),
          KioskButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// The donation entry point for a selected category (Requirement 8.2).
///
/// A themed donation panel: the category name, a set of preset amount buttons,
/// and a Donate confirm that records the donation via the [NotificationService]
/// (wired through the controller).
class _DonationPanel extends StatefulWidget {
  const _DonationPanel({
    required this.category,
    required this.onCancel,
    required this.onDonate,
    required this.backLabel,
  });

  final DonationCategory category;
  final VoidCallback onCancel;
  final ValueChanged<int> onDonate;
  final String backLabel;

  @override
  State<_DonationPanel> createState() => _DonationPanelState();
}

class _DonationPanelState extends State<_DonationPanel> {
  int _selectedAmount = DonateController.presetAmounts.first;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SectionCard(
      title: 'Donate',
      icon: Icons.volunteer_activism_rounded,
      expandChild: true,
      action: KioskButton(
        label: widget.backLabel,
        icon: Icons.arrow_back_rounded,
        variant: KioskButtonVariant.secondary,
        onPressed: widget.onCancel,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.category.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an amount to donate to this fund.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final int amount in DonateController.presetAmounts)
                  _AmountChip(
                    amount: amount,
                    isSelected: amount == _selectedAmount,
                    onTap: () => setState(() => _selectedAmount = amount),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            KioskButton(
              label: 'Donate \$$_selectedAmount',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () => widget.onDonate(_selectedAmount),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable preset donation amount.
class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Material(
      color: isSelected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.40),
              width: 1.5,
            ),
          ),
          child: Text(
            '\$$amount',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
