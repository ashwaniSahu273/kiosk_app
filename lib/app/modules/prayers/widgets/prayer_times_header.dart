import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../prayers_controller.dart';

/// Green header with title and Today's / Daily / Monthly tabs.
class PrayerTimesHeader extends StatelessWidget {
  const PrayerTimesHeader({super.key, required this.controller});

  final PrayersController controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.lerp(scheme.primary, scheme.secondary, 0.45) ??
                scheme.secondary,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Prayer Times',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final PrayerTimesTab active = controller.activeTab.value;
              return Row(
                children: PrayerTimesTab.values.map((PrayerTimesTab tab) {
                  final bool selected = tab == active;
                  final String label = switch (tab) {
                    PrayerTimesTab.today => "Today's",
                    PrayerTimesTab.daily => 'Daily',
                    PrayerTimesTab.monthly => 'Monthly',
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectTab(tab),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: <Widget>[
                            Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 3,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
