import 'package:flutter/material.dart';

import '../core/data/models/models.dart';
import 'campaign_card_actions.dart';

/// A program card matching the donation-campaign design: gradient hero, tag
/// badge, title, description, and Share / Register actions.
class ProgramCampaignCard extends StatelessWidget {
  const ProgramCampaignCard({
    super.key,
    required this.program,
    required this.onRegister,
    this.onShare,
    this.compact = false,
  });

  final Program program;
  final VoidCallback onRegister;
  final VoidCallback? onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ProgramHero(program: program, compact: compact),
            Padding(
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
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayDescription(program),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }

  static String _displayDescription(Program program) =>
      'Register for ${program.name} and join the next available session.';
}

class _ProgramHero extends StatelessWidget {
  const _ProgramHero({required this.program, required this.compact});

  final Program program;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> gradient = _heroGradient(program.id, scheme);

    return SizedBox(
      height: compact ? 88 : 160,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  _heroIcon(program.id),
                  size: compact ? 48 : 72,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.event_available_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _tagLabel(program.id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _tagLabel(String id) {
    if (id.contains('quran')) {
      return 'Quran';
    }
    if (id.contains('youth')) {
      return 'Youth';
    }
    if (id.contains('sisters')) {
      return 'Sisters';
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return 'New Muslim';
    }
    return 'Programs';
  }

  static List<Color> _heroGradient(String id, ColorScheme scheme) {
    if (id.contains('quran')) {
      return <Color>[const Color(0xFF1B5E20), const Color(0xFF43A047)];
    }
    if (id.contains('youth')) {
      return <Color>[const Color(0xFF0D47A1), const Color(0xFF42A5F5)];
    }
    if (id.contains('sisters')) {
      return <Color>[const Color(0xFF4A148C), const Color(0xFFAB47BC)];
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return <Color>[const Color(0xFF00695C), const Color(0xFF26A69A)];
    }
    return <Color>[scheme.primary, scheme.secondary];
  }

  static IconData _heroIcon(String id) {
    if (id.contains('quran')) {
      return Icons.menu_book_rounded;
    }
    if (id.contains('youth')) {
      return Icons.groups_rounded;
    }
    if (id.contains('sisters')) {
      return Icons.school_rounded;
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return Icons.handshake_rounded;
    }
    return Icons.event_rounded;
  }
}
