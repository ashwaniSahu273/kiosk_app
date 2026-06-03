import 'package:flutter/material.dart';

/// Hero banner for program/donation cards with photo + gradient overlay.
class CampaignCardHero extends StatelessWidget {
  const CampaignCardHero({
    super.key,
    this.imageUrl,
    this.imageAsset,
    required this.height,
    required this.gradientColors,
    required this.badge,
    this.fallbackIcon,
  });

  final String? imageUrl;
  final String? imageAsset;
  final double height;
  final List<Color> gradientColors;
  final Widget badge;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _HeroImage(
            imageUrl: imageUrl,
            imageAsset: imageAsset,
            gradientColors: gradientColors,
            fallbackIcon: fallbackIcon,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Positioned(left: 12, top: 12, child: badge),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.imageAsset,
    required this.gradientColors,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final String? imageAsset;
  final List<Color> gradientColors;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: _gradientFallback,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) {
            return child;
          }
          return _GradientBackdrop(
            gradientColors: gradientColors,
            fallbackIcon: fallbackIcon,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          );
        },
        errorBuilder: _gradientFallback,
      );
    }
    return _GradientBackdrop(
      gradientColors: gradientColors,
      fallbackIcon: fallbackIcon,
    );
  }

  Widget _gradientFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return _GradientBackdrop(
      gradientColors: gradientColors,
      fallbackIcon: fallbackIcon,
    );
  }
}

class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({
    required this.gradientColors,
    this.fallbackIcon,
    this.child,
  });

  final List<Color> gradientColors;
  final IconData? fallbackIcon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (fallbackIcon != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  fallbackIcon,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
