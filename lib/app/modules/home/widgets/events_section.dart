import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/models/models.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/widgets.dart';

class EventsSection extends StatelessWidget {
  const EventsSection({
    super.key,
    required this.events,
  });

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (BuildContext context, int index) {
        final Event event = events[index];
        return SizedBox(
          width: 280,
          child: _EventCampaignCard(event: event),
        );
      },
    );
  }
}

class _EventCampaignCard extends StatelessWidget {
  const _EventCampaignCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(12);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () =>
              Get.toNamed<void>(AppRoutes.events, arguments: event),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CampaignCardHero(
                    imageUrl: event.imageUrl,
                    height: 96,
                    gradientColors:
                        CampaignVisuals.programGradient(event.id, scheme),
                    fallbackIcon: CampaignVisuals.programIcon(event.id),
                    badge: const SizedBox.shrink(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: scheme.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.displayDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: scheme.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.displayTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
