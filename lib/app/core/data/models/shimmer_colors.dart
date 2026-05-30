import 'package:flutter/material.dart';

/// The base and highlight colors used by the shared `ShimmerLoader`
/// (Requirements 13.6, 13.7).
///
/// Derived deterministically from the active organization's [ThemeData] by
/// `ThemeEngine.shimmerColorsFor`, so every shimmer placeholder reflects the
/// current tenant's branding without each feature module computing its own
/// colors.
@immutable
class ShimmerColors {
  const ShimmerColors({
    required this.base,
    required this.highlight,
  });

  /// The resting/background color of the shimmer placeholder blocks.
  final Color base;

  /// The brighter sweep color that animates across the [base].
  final Color highlight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShimmerColors &&
            runtimeType == other.runtimeType &&
            base == other.base &&
            highlight == other.highlight;
  }

  @override
  int get hashCode => Object.hash(base, highlight);

  @override
  String toString() => 'ShimmerColors(base: $base, highlight: $highlight)';
}
