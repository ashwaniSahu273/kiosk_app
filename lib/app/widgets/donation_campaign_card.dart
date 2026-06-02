import 'package:flutter/material.dart';

import '../core/data/models/models.dart';
import 'kiosk_button.dart';

/// A donation campaign card matching the donation-list design: hero image,
/// tag chip, title, description, funding progress, and Share / Donate actions.
class DonationCampaignCard extends StatelessWidget {
  const DonationCampaignCard({
    super.key,
    required this.category,
    required this.onDonate,
    this.onShare,
    this.compact = false,
  });

  final DonationCategory category;
  final VoidCallback onDonate;
  final VoidCallback? onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double progress = category.fundingProgress;

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
            _CampaignHero(category: category, compact: compact),
            Padding(
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
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.displayDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
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
                        Text(
                          'Raised ${category.formattedRaised} • Goal ${category.formattedGoal}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: compact ? 10 : 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: compact
                            ? _CompactButton.secondary(
                                label: 'Share',
                                icon: Icons.share_rounded,
                                onPressed: onShare ?? () {},
                              )
                            : KioskButton(
                                label: 'Share',
                                icon: Icons.share_rounded,
                                variant: KioskButtonVariant.secondary,
                                onPressed: onShare ?? () {},
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: compact
                            ? _CompactButton.primary(
                                label: 'Donate',
                                icon: Icons.volunteer_activism_rounded,
                                onPressed: onDonate,
                              )
                            : KioskButton(
                                label: 'Donate',
                                icon: Icons.volunteer_activism_rounded,
                                onPressed: onDonate,
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
}

class _CompactButton extends StatelessWidget {
  const _CompactButton._({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  factory _CompactButton.primary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      _CompactButton._(
        label: label,
        icon: icon,
        onPressed: onPressed,
        isPrimary: true,
      );

  factory _CompactButton.secondary({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      _CompactButton._(
        label: label,
        icon: icon,
        onPressed: onPressed,
        isPrimary: false,
      );

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(12);

    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }
}

class _CampaignHero extends StatelessWidget {
  const _CampaignHero({required this.category, required this.compact});

  final DonationCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> gradient = _heroGradient(category.id, scheme);

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
                  _heroIcon(category.id),
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
                    Icons.favorite_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.tagLabel,
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

  static List<Color> _heroGradient(String id, ColorScheme scheme) {
    if (id.contains('zakat')) {
      return <Color>[const Color(0xFF1B5E20), const Color(0xFF43A047)];
    }
    if (id.contains('sadaqah') || id.contains('general')) {
      return <Color>[const Color(0xFFC62828), const Color(0xFFE53935)];
    }
    if (id.contains('maintenance') || id.contains('building')) {
      return <Color>[const Color(0xFF4E342E), const Color(0xFF8D6E63)];
    }
    return <Color>[scheme.primary, scheme.secondary];
  }

  static IconData _heroIcon(String id) {
    if (id.contains('zakat')) {
      return Icons.mosque_rounded;
    }
    if (id.contains('sadaqah') || id.contains('general')) {
      return Icons.volunteer_activism_rounded;
    }
    if (id.contains('maintenance') || id.contains('building')) {
      return Icons.home_work_rounded;
    }
    return Icons.favorite_rounded;
  }
}
