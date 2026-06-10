import 'package:flutter/material.dart';

import '../../../core/data/models/models.dart';
import '../../../widgets/widgets.dart';

class EventDetailPanel extends StatelessWidget {
  const EventDetailPanel({
    super.key,
    required this.event,
    required this.onBack,
  });

  final Event event;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SectionCard(
      title: 'Event Details',
      icon: Icons.event_rounded,
      expandChild: true,
      action: KioskButton(
        label: 'All events',
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
                imageUrl: event.imageUrl,
                height: 220,
                gradientColors: CampaignVisuals.programGradient(event.id, scheme),
                fallbackIcon: CampaignVisuals.programIcon(event.id),
                badge: CampaignTagBadge(
                  label: 'Upcoming Event',
                  icon: Icons.event_available_rounded,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              event.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.displayDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              title: 'Date',
              subtitle: event.displayDate,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.schedule_rounded,
              title: 'Time',
              subtitle: event.displayTime,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: event.displayLocation,
              scheme: scheme,
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
