import 'package:flutter/material.dart';

/// Scrollable list laid out as two cards per row (equal-width columns).
class KioskTwoColumnCardGrid extends StatelessWidget {
  const KioskTwoColumnCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final int rowCount = (itemCount + 1) ~/ 2;

    return ListView.builder(
      padding: padding,
      itemCount: rowCount,
      itemBuilder: (BuildContext context, int rowIndex) {
        final int leftIndex = rowIndex * 2;
        final int? rightIndex =
            leftIndex + 1 < itemCount ? leftIndex + 1 : null;

        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex == rowCount - 1 ? 0 : mainAxisSpacing,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: itemBuilder(context, leftIndex),
                ),
                SizedBox(width: crossAxisSpacing),
                Expanded(
                  child: rightIndex == null
                      ? const SizedBox.shrink()
                      : itemBuilder(context, rightIndex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
