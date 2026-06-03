import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../../../widgets/widgets.dart';

/// Full donation campaign details shown before the donate flow.
class DonationDetailPanel extends StatelessWidget {
  const DonationDetailPanel({
    super.key,
    required this.category,
    required this.onBack,
    required this.onDonate,
    required this.onShare,
  });

  final DonationCategory category;
  final VoidCallback onBack;
  final VoidCallback onDonate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double progress = category.fundingProgress;

    return SectionCard(
      title: 'Campaign Details',
      icon: Icons.volunteer_activism_rounded,
      expandChild: true,
      action: KioskButton(
        label: 'All campaigns',
        icon: Icons.arrow_back_rounded,
        variant: KioskButtonVariant.secondary,
        onPressed: onBack,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CampaignCardHero(
                imageUrl: category.imageUrl,
                height: 220,
                gradientColors:
                    CampaignVisuals.donationGradient(category.id, scheme),
                fallbackIcon: CampaignVisuals.donationIcon(category.id),
                badge: CampaignTagBadge(
                  label: category.tagLabel,
                  icon: Icons.favorite_rounded,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              category.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.displayDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Funding progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: scheme.outline.withValues(alpha: 0.25),
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  '${(progress * 100).round()}% funded',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Raised ${category.formattedRaised}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Goal ${category.formattedGoal}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: CampaignCardActions.share(
                    compact: false,
                    onPressed: onShare,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampaignCardActions.donate(
                    compact: false,
                    onPressed: onDonate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
