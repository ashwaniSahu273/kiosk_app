import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../routes/app_routes.dart';
import '../auth/auth_service.dart';
import '../../widgets/widgets.dart';
import 'home_controller.dart';
import 'next_prayer_resolver.dart';
import 'section_state.dart';
import 'widgets/widgets.dart';

/// The full landscape Home_Screen (Requirements 5.1, 12.3, 12.4, 13.1, 13.3),
/// matching the reference design 1:1.
///
/// Layout (sidebar-less; shared [KioskDestinationScaffold] top navigation;
/// the content area below the bar scrolls vertically):
///   ┌────────────────────────────────────────────────────────────────────┐
///   │  KioskTopNavBar (logo · nav pills · clock · logout)                │
///   ├──────────────────────────────────────────────┬─────────────────────┤
///   │  Next Prayer hero (countdown + upcoming +    │  Scan to Donate     │
///   │  today's prayer-time tiles, next highlighted)│                     │
///   ├──────────────────────────────────────────────┴─────────────────────┤
///   │  Donation Categories (horizontal campaign cards)                   │
///   ├────────────────────────────────────────────────────────────────────┤
///   │  Available Programs (horizontal campaign cards)                    │
///   └────────────────────────────────────────────────────────────────────┘
///
/// Each section sits at a comfortable fixed height inside a single
/// [SingleChildScrollView], so the page scrolls smoothly and nothing ever
/// overflows regardless of how much content an organization configures.
///
/// Each section renders from its own [SectionState] (Requirements 13.1, 13.3):
/// * [SectionLoading] → [ShimmerLoader] with the matching [ShimmerShape];
/// * [SectionLoaded]  → the section's content widget;
/// * [SectionEmpty]   → a per-section empty-state message (disabled Donate
///   control for empty donations, Req 8.3);
/// * [SectionError]   → an error message and a Retry control.
///
/// State transitions cross-fade through an [AnimatedSwitcher] so shimmer
/// placeholders dissolve smoothly into content.
///
/// Requirement 12.3/12.4 gating: while
/// [HomeController.hasUnresolvedRequiredError] is true, the content grid is
/// hidden and a full-screen "content could not be loaded" state lists every
/// errored section with its own Retry control. When false, the grid shows.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Clears the session and active organization, then returns to login
  /// (Requirement 1.9).
  Future<void> _logout() async {
    await Get.find<AuthService>().logout();
    await Get.offAllNamed<void>(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.home,
      trailing: _LogoutControl(onLogout: _logout),
      child: Obx(() {
        // Reading the gate registers all four section states, so this
        // rebuilds whenever any section resolves.
        if (controller.hasUnresolvedRequiredError) {
          return _FullScreenErrorState(controller: controller);
        }
        return _HomeContentGrid(controller: controller);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout control
// ---------------------------------------------------------------------------

/// A logout control rendered in the top navigation bar (Requirement 1.9).
class _LogoutControl extends StatelessWidget {
  const _LogoutControl({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return KioskButton(
      label: 'Log out',
      icon: Icons.logout_rounded,
      variant: KioskButtonVariant.secondary,
      onPressed: () => onLogout(),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen error state (Req 12.3, 12.4)
// ---------------------------------------------------------------------------

/// Shown while any required Home section has an unresolved loading error.
///
/// Hides the content grid and lists every errored section with its own Retry
/// control (Requirements 12.3, 12.4).
class _FullScreenErrorState extends StatelessWidget {
  const _FullScreenErrorState({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Content could not be loaded',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please retry the sections below. Every section must load '
              'before the home screen is shown.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Per-section retry controls (only errored sections render a row).
            _SectionRetryRow(
              label: 'Next Prayer',
              state: controller.prayerSchedule.value,
              onRetry: () =>
                  controller.retrySection(HomeSection.prayerSchedule),
            ),
            _SectionRetryRow(
              label: 'Available Programs',
              state: controller.programs.value,
              onRetry: () => controller.retrySection(HomeSection.programs),
            ),
            _SectionRetryRow(
              label: 'Donation Categories',
              state: controller.donations.value,
              onRetry: () => controller.retrySection(HomeSection.donations),
            ),
            _SectionRetryRow(
              label: 'Scan to Donate',
              state: controller.qr.value,
              onRetry: () => controller.retrySection(HomeSection.qr),
            ),
            _SectionRetryRow(
              label: 'Upcoming Events',
              state: controller.events.value,
              onRetry: () => controller.retrySection(HomeSection.events),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row showing an errored section's message and a Retry button. Only
/// rendered when [state] is a [SectionError].
class _SectionRetryRow extends StatelessWidget {
  const _SectionRetryRow({
    required this.label,
    required this.state,
    required this.onRetry,
  });

  final String label;
  final SectionState<dynamic> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SectionState<dynamic> current = state;
    if (current is! SectionError<dynamic>) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    current.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            KioskButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main scrollable content (reference-image layout)
// ---------------------------------------------------------------------------

/// The scrollable Home content shown when every required section is resolved.
///
/// Row 1: Next Prayer hero dashboard (countdown + upcoming prayers + today's
///        prayer-time tiles, next prayer highlighted) with the Scan-to-Donate
///        QR card beside it.
/// Row 2: Donation Categories — horizontally scrolling campaign cards.
/// Row 3: Available Programs — horizontally scrolling campaign cards.
///
/// Every section gets a comfortable fixed height inside one vertical
/// [SingleChildScrollView], so the page scrolls smoothly and never overflows.
class _HomeContentGrid extends StatelessWidget {
  const _HomeContentGrid({required this.controller});

  final HomeController controller;

  static const double _spacing = 12;
  static const double _featuredHeight = 186;
  static const double _heroHeight = 300;
  static const double _donationHeight = 220;
  static const double _eventsHeight = 220;
  static const double _footerHeight = 56;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ---- Row 1: next prayer dashboard + scan-to-donate actions ----
          SizedBox(
            height: _heroHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: _PrayerSectionContent(controller: controller)),
                const SizedBox(width: _spacing),
                SizedBox(
                  width: 360,
                  child: _ScanDonatePanel(controller: controller),
                ),
              ],
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 2: featured program cards ----
          SizedBox(
            height: _featuredHeight,
            child: _HomeSectionFrame(
              title: 'Featured Programs',
              icon: Icons.star_rounded,
              actionLabel: 'View All Programs',
              onAction: () => Get.toNamed<void>(AppRoutes.programs),
              child: _FeaturedCampaignsContent(controller: controller),
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 3: donation campaign cards ----
          SizedBox(
            height: _donationHeight,
            child: _HomeSectionFrame(
              title: 'Donation Campaigns',
              icon: Icons.volunteer_activism_rounded,
              actionLabel: 'View All Campaigns',
              onAction: () => Get.toNamed<void>(AppRoutes.donate),
              child: _DonationsContent(controller: controller),
            ),
          ),
          const SizedBox(height: _spacing),

          // ---- Row 4: upcoming events ----
          SizedBox(
            height: _eventsHeight,
            child: _HomeSectionFrame(
              title: 'Upcoming Events',
              icon: Icons.calendar_month_rounded,
              actionLabel: 'View All Events',
              onAction: () => Get.toNamed<void>(AppRoutes.events),
              child: _EventsContent(controller: controller),
            ),
          ),
          const SizedBox(height: _spacing),

          const SizedBox(height: _footerHeight, child: _HomeFooter()),
        ],
      ),
    );
  }
}

class _HomeSectionFrame extends StatelessWidget {
  const _HomeSectionFrame({
    required this.title,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 32,
          child: Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: scheme.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(actionLabel!),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _ScanDonatePanel extends StatelessWidget {
  const _ScanDonatePanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Support Our Community',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.76),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Quick Actions',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: <Widget>[
              _QuickActionTile(
                icon: Icons.volunteer_activism_outlined,
                label: 'Give\nDonation',
                onTap: () => Get.toNamed<void>(AppRoutes.donate),
              ),
              _QuickActionTile(
                icon: Icons.schedule_rounded,
                label: 'Prayer\nTimes',
                onTap: () => Get.toNamed<void>(AppRoutes.prayers),
              ),
              _QuickActionTile(
                icon: Icons.calendar_month_outlined,
                label: 'Programs\n& Events',
                onTap: () => Get.toNamed<void>(AppRoutes.programs),
              ),
              _QuickActionTile(
                icon: Icons.mosque_outlined,
                label: 'Masjid\nInfo',
                onTap: () => Get.toNamed<void>(AppRoutes.home),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(10);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: scheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
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

class _DonationsContent extends StatelessWidget {
  const _DonationsContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<DonationCategory>> state =
          controller.donations.value;

      Widget body;
      if (state is SectionLoading<List<DonationCategory>>) {
        body = const ShimmerLoader(shape: ShimmerShape.donationCategories);
      } else if (state is SectionLoaded<List<DonationCategory>>) {
        body = DonationsSection(categories: state.data);
      } else if (state is SectionError<List<DonationCategory>>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.donations),
        );
      } else {
        body = const _EmptyState(message: 'No donation campaigns available.');
      }

      return _animatedState(state: state, child: body);
    });
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Powered by',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.verified_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'MOHID',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _FooterText(
              'v20.7.25   |   www.mohid.net   |   1-844-827-5387',
              scheme: scheme,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  _PaymentBadge(label: 'VISA', color: Colors.blue.shade700),
                  _PaymentBadge(label: 'MC', color: Colors.red.shade600),
                  _PaymentBadge(label: 'AMEX', color: Colors.blue.shade500),
                  _PaymentBadge(label: 'DISC', color: scheme.onSurface),
                  _PaymentBadge(label: 'Pay', color: scheme.onSurface),
                  _PaymentBadge(label: 'G Pay', color: Colors.blue.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText(this.text, {required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.70),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeaturedCampaignsContent extends StatelessWidget {
  const _FeaturedCampaignsContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<Program>> programsState =
          controller.programs.value;
      final SectionState<List<DonationCategory>> donationsState =
          controller.donations.value;

      if (programsState is SectionLoading<List<Program>> ||
          donationsState is SectionLoading<List<DonationCategory>>) {
        return const _FeaturedCampaignsSkeleton();
      }

      if (programsState is SectionError<List<Program>>) {
        return _ErrorState(
          message: programsState.message,
          onRetry: () => controller.retrySection(HomeSection.programs),
        );
      }
      if (donationsState is SectionError<List<DonationCategory>>) {
        return _ErrorState(
          message: donationsState.message,
          onRetry: () => controller.retrySection(HomeSection.donations),
        );
      }

      final List<Widget> cards = <Widget>[];
      if (programsState is SectionLoaded<List<Program>>) {
        for (final Program program in programsState.data.take(3)) {
          cards.add(
            ProgramCampaignCard(
              program: program,
              compact: true,
              onTap: () =>
                  Get.toNamed<void>(AppRoutes.programs, arguments: program),
              onRegister: () =>
                  Get.toNamed<void>(AppRoutes.programs, arguments: program),
            ),
          );
        }
      }
      if (donationsState is SectionLoaded<List<DonationCategory>>) {
        for (final DonationCategory category in donationsState.data.take(2)) {
          cards.add(
            DonationCampaignCard(
              category: category,
              compact: true,
              onTap: () =>
                  Get.toNamed<void>(AppRoutes.donate, arguments: category),
              onDonate: () =>
                  Get.toNamed<void>(AppRoutes.donate, arguments: category),
            ),
          );
        }
      }

      if (cards.isEmpty) {
        return const _EmptyState(message: 'No featured programs available.');
      }

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(width: 342, child: cards[index]);
        },
      );
    });
  }
}

class _FeaturedCampaignsSkeleton extends StatelessWidget {
  const _FeaturedCampaignsSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        for (int i = 0; i < 4; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.14),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 92,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _SkeletonLine(widthFactor: 0.80, scheme: scheme),
                          const SizedBox(height: 9),
                          _SkeletonLine(widthFactor: 0.62, scheme: scheme),
                          const SizedBox(height: 18),
                          _SkeletonLine(widthFactor: 0.96, scheme: scheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.scheme});

  final double widthFactor;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: scheme.outline.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-section content (state → shimmer / content / empty / error)
// ---------------------------------------------------------------------------

/// Cross-fades between section states (shimmer → content/empty/error) so
/// state changes feel smooth instead of popping (200 ms, matching the app's
/// route fade).
Widget _animatedState({
  required SectionState<dynamic> state,
  required Widget child,
}) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: KeyedSubtree(key: ValueKey<Type>(state.runtimeType), child: child),
  );
}

/// Next Prayer section: the hero dashboard with the day's prayer list, the
/// resolved next prayer, and its live countdown (Requirements 6.1, 6.3, 6.5,
/// 13.1, 13.3).
class _PrayerSectionContent extends StatelessWidget {
  const _PrayerSectionContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<PrayerSchedule> state =
          controller.prayerSchedule.value;
      // Observe the live clock + resolved next prayer so the countdown ticks.
      final NextPrayerResult? next = controller.nextPrayer.value;
      controller.now.value;
      final bool hasCountdown = controller.hasCountdown;
      final String countdownLabel = controller.countdownLabel;
      final SectionState<String> qrState = controller.qr.value;
      final String? donationUrl = qrState is SectionLoaded<String>
          ? qrState.data
          : null;

      Widget body;
      if (state is SectionLoading<PrayerSchedule>) {
        body = const ShimmerLoader(shape: ShimmerShape.nextPrayer);
      } else if (state is SectionLoaded<PrayerSchedule>) {
        body = NextPrayerCard(
          fillHeight: true,
          schedule: state.data,
          next: next,
          hasCountdown: hasCountdown,
          countdownLabel: countdownLabel,
          now: controller.now.value,
          donationUrl: donationUrl,
        );
      } else if (state is SectionEmpty<PrayerSchedule>) {
        body = const _EmptyState(message: 'No prayer schedule available.');
      } else if (state is SectionError<PrayerSchedule>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.prayerSchedule),
        );
      } else {
        body = const SizedBox.shrink();
      }

      return _animatedState(state: state, child: body);
    });
  }
}

/// A centered empty-state message.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.inbox_rounded,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsContent extends StatelessWidget {
  const _EventsContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SectionState<List<Event>> state = controller.events.value;

      Widget body;
      if (state is SectionLoading<List<Event>>) {
        body = const ShimmerLoader(shape: ShimmerShape.eventsList);
      } else if (state is SectionLoaded<List<Event>>) {
        body = EventsSection(events: state.data);
      } else if (state is SectionError<List<Event>>) {
        body = _ErrorState(
          message: state.message,
          onRetry: () => controller.retrySection(HomeSection.events),
        );
      } else {
        body = const _EmptyState(message: 'No upcoming events.');
      }

      return _animatedState(state: state, child: body);
    });
  }
}

/// A centered error message with a Retry control (Requirement 13.4).
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
          Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 14),
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
