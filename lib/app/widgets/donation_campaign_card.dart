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

    if (compact) {
      return _CompactDonationCampaignCard(
        category: category,
        onDonate: onDonate,
        onTap: onTap,
      );
    }

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

class _CompactDonationCampaignCard extends StatelessWidget {
  const _CompactDonationCampaignCard({
    required this.category,
    required this.onDonate,
    this.onTap,
  });

  final DonationCategory category;
  final VoidCallback onDonate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(8);

    final Widget card = Container(
      height: 112,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _CompactDonationImage(category: category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  category.displayDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                const Row(
                  children: <Widget>[
                    _CompactMeta(
                      icon: Icons.calendar_month_outlined,
                      label: 'Ongoing',
                    ),
                    SizedBox(width: 14),
                    _CompactMeta(
                      icon: Icons.monetization_on_outlined,
                      label: 'Any Amount',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onDonate,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      foregroundColor: scheme.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: radius),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Donate'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

class _CompactDonationImage extends StatelessWidget {
  const _CompactDonationImage({required this.category});

  final DonationCategory category;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(6);

    Widget fallback() {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: CampaignVisuals.donationGradient(category.id, scheme),
          ),
        ),
        child: Icon(
          CampaignVisuals.donationIcon(category.id),
          color: Colors.white.withValues(alpha: 0.75),
          size: 38,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: 92,
        height: 96,
        child: category.imageUrl == null || category.imageUrl!.isEmpty
            ? fallback()
            : Image.network(
                category.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: scheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.76),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
