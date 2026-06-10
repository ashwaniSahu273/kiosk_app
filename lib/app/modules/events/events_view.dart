import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../widgets/widgets.dart';
import '../home/section_state.dart';
import 'events_controller.dart';
import 'widgets/event_detail_panel.dart';

class EventsView extends GetView<EventsController> {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.events,
      child: Obx(() {
        final Event? detail = controller.detailEvent.value;

        if (detail != null) {
          return EventDetailPanel(
            event: detail,
            onBack: controller.clearDetail,
          );
        }
        return _EventsList(controller: controller);
      }),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Upcoming Events',
      icon: Icons.event_rounded,
      expandChild: true,
      child: Obx(() {
        final SectionState<List<Event>> state = controller.events.value;

        if (state is SectionLoading<List<Event>>) {
          return const SingleChildScrollView(
            child: ShimmerLoader(shape: ShimmerShape.eventsList),
          );
        }
        if (state is SectionEmpty<List<Event>>) {
          return const _EventsEmptyState();
        }
        if (state is SectionError<List<Event>>) {
          return _EventsErrorState(
            message: state.message,
            onRetry: controller.load,
          );
        }
        if (state is SectionLoaded<List<Event>>) {
          return _EventsLoaded(
            events: state.data,
            onOpenDetail: controller.openEventDetail,
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

class _EventsLoaded extends StatelessWidget {
  const _EventsLoaded({
    required this.events,
    required this.onOpenDetail,
  });

  final List<Event> events;
  final ValueChanged<Event> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return CampaignListCanvas(
      child: KioskTwoColumnCardGrid(
        itemCount: events.length,
        itemBuilder: (BuildContext context, int index) {
          final Event event = events[index];
          return _EventCard(
            event: event,
            onTap: () => onOpenDetail(event),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

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
          onTap: onTap,
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
                    height: 120,
                    gradientColors:
                        CampaignVisuals.programGradient(event.id, scheme),
                    fallbackIcon: CampaignVisuals.programIcon(event.id),
                    badge: CampaignTagBadge(
                      label: 'Event',
                      icon: Icons.event_available_rounded,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
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
                      const SizedBox(height: 8),
                      _MetaRow(
                        icon: Icons.calendar_month_outlined,
                        text: event.displayDate,
                        scheme: scheme,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.schedule_rounded,
                        text: event.displayTime,
                        scheme: scheme,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        text: event.displayLocation,
                        scheme: scheme,
                      ),
                    ],
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.scheme,
  });

  final IconData icon;
  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: scheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsEmptyState extends StatelessWidget {
  const _EventsEmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No events available.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsErrorState extends StatelessWidget {
  const _EventsErrorState({required this.message, required this.onRetry});

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
