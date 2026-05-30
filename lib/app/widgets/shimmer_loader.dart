import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../core/data/models/models.dart';
import '../core/services/theme_engine.dart';

/// The Home_Screen section a [ShimmerLoader] is standing in for (Requirement
/// 13.2).
///
/// Each variant drives a skeleton layout whose shape approximates the real
/// section's content, so the placeholder reads as "this is where the Next
/// Prayer card / Programs list / Donation categories / Scan-to-Donate QR will
/// appear" while that section's organization content loads.
enum ShimmerShape {
  /// A large countdown block above a row of prayer-time chips.
  nextPrayer,

  /// Several stacked rows, each a program name bar with a trailing button block.
  programsList,

  /// A wrapped set of category chips paired with donate-button blocks.
  donationCategories,

  /// A large square QR placeholder above a short caption bar.
  qrCard,
}

/// The single, app-wide animated shimmer loading placeholder (Requirement
/// 13.6).
///
/// This is the **only** shimmer placeholder in the kiosk app: no feature module
/// should implement its own. It wraps a per-[shape] skeleton in
/// [Shimmer.fromColors] so the placeholder animates continuously until it is
/// replaced (13.5), and it derives its base/highlight colors from the active
/// organization's [ThemeData] via [ThemeEngine.shimmerColorsFor] so every
/// shimmer reflects the current tenant's branding (13.7).
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    required this.shape,
    this.themeEngine,
  });

  /// Which section layout this placeholder approximates (13.2).
  final ShimmerShape shape;

  /// Injectable [ThemeEngine]; defaults to the registered singleton. Allows the
  /// shimmer colors to be derived without a `Get` lookup in tests.
  final ThemeEngine? themeEngine;

  ThemeEngine get _themeEngine => themeEngine ?? Get.find<ThemeEngine>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ShimmerColors colors = _themeEngine.shimmerColorsFor(theme);

    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      // A non-stopping period keeps the sweep animating until the loader is
      // removed from the tree when content resolves (13.5).
      period: const Duration(milliseconds: 1400),
      child: _buildSkeleton(),
    );
  }

  /// Builds the opaque skeleton blocks for [shape]. [Shimmer.fromColors] paints
  /// its base/highlight gradient over these opaque shapes, so the block color
  /// itself is only a mask and is intentionally a flat neutral.
  Widget _buildSkeleton() {
    switch (shape) {
      case ShimmerShape.nextPrayer:
        return const _NextPrayerSkeleton();
      case ShimmerShape.programsList:
        return const _ProgramsListSkeleton();
      case ShimmerShape.donationCategories:
        return const _DonationCategoriesSkeleton();
      case ShimmerShape.qrCard:
        return const _QrCardSkeleton();
    }
  }
}

/// The flat color painted into every skeleton block. The shimmer gradient is
/// drawn over it, so only its opacity/shape matter, not its hue.
const Color _kBlock = Color(0xFFFFFFFF);

/// A single rounded skeleton block.
class _Block extends StatelessWidget {
  const _Block({
    this.width,
    this.height,
    this.radius = 8,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kBlock,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Next Prayer: a big countdown block above a row of prayer-time chips
/// (mirrors [NextPrayerCard]).
class _NextPrayerSkeleton extends StatelessWidget {
  const _NextPrayerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Upcoming prayer name.
        const Align(
          alignment: Alignment.centerLeft,
          child: _Block(width: 160, height: 20),
        ),
        const SizedBox(height: 16),
        // Large countdown block.
        const _Block(height: 96, radius: 16),
        const SizedBox(height: 20),
        // Row of prayer-time chips.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            5,
            (_) => const _Block(width: 56, height: 64, radius: 12),
          ),
        ),
      ],
    );
  }
}

/// Available Programs: several rows, each a name bar + a register-button block
/// (mirrors [ProgramsSection]).
class _ProgramsListSkeleton extends StatelessWidget {
  const _ProgramsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(4, (int index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 16),
          child: Row(
            children: const <Widget>[
              Expanded(child: _Block(height: 18)),
              SizedBox(width: 16),
              _Block(width: 96, height: 36, radius: 10),
            ],
          ),
        );
      }),
    );
  }
}

/// Donation Categories: a wrapped set of category chips, each paired with a
/// donate-button block (mirrors [DonationsSection]).
class _DonationCategoriesSkeleton extends StatelessWidget {
  const _DonationCategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List<Widget>.generate(4, (_) {
        return SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const <Widget>[
              _Block(height: 18),
              SizedBox(height: 12),
              _Block(height: 40, radius: 10),
            ],
          ),
        );
      }),
    );
  }
}

/// Scan-to-Donate: a large square QR placeholder above a caption bar
/// (mirrors [ScanToDonateCard]).
class _QrCardSkeleton extends StatelessWidget {
  const _QrCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const <Widget>[
        _Block(width: 180, height: 180, radius: 16),
        SizedBox(height: 16),
        _Block(width: 140, height: 16),
      ],
    );
  }
}
