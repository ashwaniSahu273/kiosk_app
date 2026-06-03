import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../prayer_format.dart';
import '../prayers_controller.dart';
import 'friday_prayer_card.dart';
import 'monthly_prayer_table.dart';
import 'prayer_date_chip.dart';
import 'salah_timings_card.dart';
import 'upcoming_prayer_card.dart';

/// Loaded prayer-times content for the active tab.
class PrayerTimesBody extends StatelessWidget {
  const PrayerTimesBody({super.key, required this.controller});

  final PrayersController controller;

  Future<void> _pickDay(BuildContext context) async {
    final DateTime initial = controller.selectedDay.value;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      controller.setSelectedDay(picked);
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final DateTime initial = controller.selectedMonth.value;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select month',
    );
    if (picked != null) {
      controller.setSelectedMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.now.value;
      controller.activeTab.value;
      controller.displayPrayers;
      controller.monthlyDays;
      final PrayerTimesTab tab = controller.activeTab.value;

      return switch (tab) {
        PrayerTimesTab.today => _TodayTab(controller: controller),
        PrayerTimesTab.daily => _DailyTab(
            controller: controller,
            onPickDate: () => _pickDay(context),
          ),
        PrayerTimesTab.monthly => _MonthlyTab(
            controller: controller,
            onPickMonth: () => _pickMonth(context),
          ),
      };
    });
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.controller});

  final PrayersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.now.value;
      final bool showUpcoming = controller.hasCountdown;

      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: <Widget>[
          Center(
            child: PrayerDateChip(label: formatLongDate(controller.now.value)),
          ),
          const SizedBox(height: 16),
          if (showUpcoming) ...<Widget>[
            UpcomingPrayerCard(
              prayerName: controller.upcomingPrayerName,
              athanTime: controller.upcomingAthanTime,
              countdown: controller.countdownHms,
              isNextDay: controller.nextPrayer.value?.isNextDay ?? false,
            ),
            const SizedBox(height: 16),
          ],
          SalahTimingsCard(
            prayers: controller.displayPrayers,
            highlightIndex: controller.highlightedPrayerIndex,
          ),
          if (controller.showFridayCard) ...<Widget>[
            const SizedBox(height: 16),
            FridayPrayerCard(events: controller.fridayEvents),
          ],
        ],
      );
    });
  }
}

class _DailyTab extends StatelessWidget {
  const _DailyTab({required this.controller, required this.onPickDate});

  final PrayersController controller;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: <Widget>[
          PrayerDayNavigator(
            date: controller.selectedDay.value,
            onPrevious: () => controller.shiftSelectedDay(-1),
            onNext: () => controller.shiftSelectedDay(1),
            onPickDate: onPickDate,
          ),
          const SizedBox(height: 16),
          SalahTimingsCard(
            prayers: controller.displayPrayers,
            highlightIndex: controller.highlightedPrayerIndex,
          ),
        ],
      );
    });
  }
}

class _MonthlyTab extends StatelessWidget {
  const _MonthlyTab({required this.controller, required this.onPickMonth});

  final PrayersController controller;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrayerMonthNavigator(
            month: controller.selectedMonth.value,
            onPrevious: () => controller.shiftSelectedMonth(-1),
            onNext: () => controller.shiftSelectedMonth(1),
            onPickMonth: onPickMonth,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: MonthlyPrayerTable(
              days: controller.monthlyDays,
              today: controller.now.value,
            ),
          ),
        ],
      );
    });
  }
}
