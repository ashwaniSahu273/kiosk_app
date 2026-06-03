import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../../../widgets/widgets.dart';

/// Full program details shown before registration.
class ProgramDetailPanel extends StatelessWidget {
  const ProgramDetailPanel({
    super.key,
    required this.program,
    required this.onBack,
    required this.onRegister,
    required this.onShare,
  });

  final Program program;
  final VoidCallback onBack;
  final VoidCallback onRegister;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SectionCard(
      title: 'Program Details',
      icon: Icons.event_rounded,
      expandChild: true,
      action: KioskButton(
        label: 'All programs',
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
                imageUrl: program.imageUrl,
                height: 220,
                gradientColors:
                    CampaignVisuals.programGradient(program.id, scheme),
                fallbackIcon: CampaignVisuals.programIcon(program.id),
                badge: CampaignTagBadge(
                  label: CampaignVisuals.programTag(program.id),
                  icon: Icons.event_available_rounded,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              program.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              program.displayDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _InfoTile(
              icon: Icons.schedule_rounded,
              title: 'Schedule',
              subtitle: 'Sessions posted weekly — register to receive updates.',
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'On-site at the masjid community hall.',
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.groups_rounded,
              title: 'Who can join',
              subtitle: 'Open to community members; some programs are age-specific.',
              scheme: scheme,
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
                  child: CampaignCardActions.register(
                    compact: false,
                    onPressed: onRegister,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scheme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      height: 1.35,
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
