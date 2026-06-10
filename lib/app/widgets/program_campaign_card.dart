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

    if (compact) {
      return _CompactProgramCampaignCard(
        program: program,
        onRegister: onRegister,
        onTap: onTap,
      );
    }

    final Widget body = Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: CampaignCardActions.share(
                  compact: false,
                  onPressed: onShare ?? () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampaignCardActions.register(
                  compact: false,
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
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _ProgramHero(program: program, compact: false, scheme: scheme),
        Expanded(child: body),
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

class _CompactProgramCampaignCard extends StatelessWidget {
  const _CompactProgramCampaignCard({
    required this.program,
    required this.onRegister,
    this.onTap,
  });

  final Program program;
  final VoidCallback onRegister;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color titleColor = scheme.onSurface;
    final Color mutedColor = scheme.onSurface.withValues(alpha: 0.66);
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
          _CompactProgramImage(program: program),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  program.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  program.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    _CompactMeta(
                      icon: Icons.calendar_month_outlined,
                      label: _programCadence(program),
                    ),
                    const SizedBox(width: 14),
                    _CompactMeta(
                      icon: Icons.monetization_on_outlined,
                      label: _programPrice(program),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onRegister,
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
                    child: const Text('Register'),
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

  static String _programCadence(Program program) {
    final String text = '${program.name} ${program.displayDescription}'
        .toLowerCase();
    if (text.contains('weekly')) {
      return 'Weekly';
    }
    if (text.contains('ongoing')) {
      return 'Ongoing';
    }
    return 'One-Time Event';
  }

  static String _programPrice(Program program) {
    final RegExpMatch? match = RegExp(
      r'\$\s?\d+(?:\.\d+)?',
    ).firstMatch(program.displayDescription);
    if (match != null) {
      return match.group(0)!.replaceAll(' ', '');
    }
    if (program.name.toLowerCase().contains('fitness')) {
      return r'$120';
    }
    return r'$20';
  }
}

class _CompactProgramImage extends StatelessWidget {
  const _CompactProgramImage({required this.program});

  final Program program;

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
            colors: CampaignVisuals.programGradient(program.id, scheme),
          ),
        ),
        child: Icon(
          CampaignVisuals.programIcon(program.id),
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
        child: program.imageUrl == null || program.imageUrl!.isEmpty
            ? fallback()
            : Image.network(
                program.imageUrl!,
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
