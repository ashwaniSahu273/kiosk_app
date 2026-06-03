import 'package:flutter/material.dart';

import '../core/data/models/models.dart';
import 'campaign_card_actions.dart';
import 'campaign_card_frame.dart';
import 'campaign_card_hero.dart';
import 'campaign_tag_badge.dart';
import 'campaign_visuals.dart';

/// A program card matching the donation-campaign design: gradient hero, tag
/// badge, title, description, and Share / Register actions.
class ProgramCampaignCard extends StatelessWidget {
  const ProgramCampaignCard({
    super.key,
    required this.program,
    required this.onRegister,
    this.onTap,
    this.onShare,
    this.compact = false,
  });

  final Program program;
  final VoidCallback onRegister;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget body = Padding(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            program.name,
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
              program.displayDescription,
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
                  program.displayDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
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
                child: CampaignCardActions.register(
                  compact: compact,
                  onPressed: onRegister,
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
        _ProgramHero(program: program, compact: compact, scheme: scheme),
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

class _ProgramHero extends StatelessWidget {
  const _ProgramHero({
    required this.program,
    required this.compact,
    required this.scheme,
  });

  final Program program;
  final bool compact;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return CampaignCardHero(
      imageUrl: program.imageUrl,
      height: compact ? 88 : 160,
      gradientColors: CampaignVisuals.programGradient(program.id, scheme),
      fallbackIcon: CampaignVisuals.programIcon(program.id),
      badge: CampaignTagBadge(
        label: CampaignVisuals.programTag(program.id),
        icon: Icons.event_available_rounded,
      ),
    );
  }
}
