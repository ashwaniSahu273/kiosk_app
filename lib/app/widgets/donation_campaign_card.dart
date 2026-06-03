import 'package:flutter/material.dart';

import '../core/data/models/models.dart';
import 'campaign_card_actions.dart';
import 'campaign_card_frame.dart';
import 'campaign_card_hero.dart';
import 'campaign_tag_badge.dart';
import 'campaign_visuals.dart';

/// A donation campaign card matching the donation-list design: hero image,
/// tag chip, title, description, funding progress, and Share / Donate actions.
class DonationCampaignCard extends StatelessWidget {
  const DonationCampaignCard({
    super.key,
    required this.category,
    required this.onDonate,
    this.onTap,
    this.onShare,
    this.compact = false,
  });

  final DonationCategory category;
  final VoidCallback onDonate;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double progress = category.fundingProgress;

    final Widget body = Padding(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            category.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (compact)
            Text(
              category.displayDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  category.displayDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (!compact) ...<Widget>[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.outline.withValues(alpha: 0.25),
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Raised ${category.formattedRaised} • Goal ${category.formattedGoal}',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: compact ? 10 : 16),
          Row(
            children: <Widget>[
              Expanded(
                child: CampaignCardActions.share(
                  compact: compact,
                  onPressed: onShare ?? () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampaignCardActions.donate(
                  compact: compact,
                  onPressed: onDonate,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final Widget card = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        _CampaignHero(category: category, compact: compact, scheme: scheme),
        if (compact) body else Expanded(child: body),
      ],
    );

    return CampaignCardFrame(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: onTap == null
            ? card
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: card,
                ),
              ),
      ),
    );
  }
}

class _CampaignHero extends StatelessWidget {
  const _CampaignHero({
    required this.category,
    required this.compact,
    required this.scheme,
  });

  final DonationCategory category;
  final bool compact;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return CampaignCardHero(
      imageUrl: category.imageUrl,
      height: compact ? 88 : 160,
      gradientColors: CampaignVisuals.donationGradient(category.id, scheme),
      fallbackIcon: CampaignVisuals.donationIcon(category.id),
      badge: CampaignTagBadge(
        label: category.tagLabel,
        icon: Icons.favorite_rounded,
      ),
    );
  }
}
