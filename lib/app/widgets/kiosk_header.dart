import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/data/models/models.dart';
import '../core/services/organization_context.dart';
import '../core/services/theme_engine.dart';

/// The active organization's logo and display name (Requirement 4.3).
///
/// The logo is resolved through [ThemeEngine.resolveLogo], falling back to the
/// bundled placeholder via [ThemeEngine.reportLogoLoadFailure] if the resolved
/// image fails to load. Branding is pulled reactively from the
/// [OrganizationContext], so the brand block re-renders when a different
/// organization becomes active.
class KioskHeaderBrand extends StatelessWidget {
  const KioskHeaderBrand({
    super.key,
    this.organizationContext,
    this.themeEngine,
    this.logoSize = 56,
  });

  /// Injectable [OrganizationContext]; defaults to the registered singleton.
  final OrganizationContext? organizationContext;

  /// Injectable [ThemeEngine]; defaults to the registered singleton.
  final ThemeEngine? themeEngine;

  /// Logo height/width in logical pixels.
  final double logoSize;

  OrganizationContext get _orgContext =>
      organizationContext ?? Get.find<OrganizationContext>();

  ThemeEngine get _themeEngine => themeEngine ?? Get.find<ThemeEngine>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Obx(() {
      final BrandingProfile? branding = _orgContext.branding;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildLogo(branding),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              branding?.displayName ?? '',
              style: (theme.textTheme.headlineSmall ?? const TextStyle())
                  .copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLogo(BrandingProfile? branding) {
    final ThemeEngine engine = _themeEngine;

    final ImageProvider provider = branding == null
        ? engine.defaultLogo
        : engine.resolveLogo(branding);

    return SizedBox(
      height: logoSize,
      width: logoSize,
      child: Image(
        image: provider,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          // The resolved logo failed to load: surface a configuration warning
          // and fall back to the guaranteed bundled placeholder (4.8).
          final ImageProvider fallback = branding == null
              ? engine.defaultLogo
              : engine.reportLogoLoadFailure(branding);
          return Image(image: fallback, fit: BoxFit.contain);
        },
      ),
    );
  }
}

/// A live clock above the current calendar date (Requirements 5.1, 5.2).
///
/// Refreshed every second via an internal [Timer] created in
/// [State.initState] and cancelled in [State.dispose]; tabular figures keep
/// the layout from jittering as digits change.
class KioskHeaderClock extends StatefulWidget {
  const KioskHeaderClock({super.key, this.clock});

  /// Injectable clock for the current time; defaults to [DateTime.now].
  final DateTime Function()? clock;

  @override
  State<KioskHeaderClock> createState() => _KioskHeaderClockState();
}

class _KioskHeaderClockState extends State<KioskHeaderClock> {
  /// Ticks the live clock. A 1-second period keeps the displayed time current
  /// and comfortably satisfies the "at least every 60 seconds" rule (5.2).
  static const Duration _tick = Duration(seconds: 1);

  Timer? _timer;
  late DateTime _now;

  DateTime Function() get _clock => widget.clock ?? DateTime.now;

  @override
  void initState() {
    super.initState();
    _now = _clock();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = _clock());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final TextStyle clockStyle =
        (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final TextStyle dateStyle = theme.textTheme.titleMedium ??
        const TextStyle(fontWeight: FontWeight.w500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(formatTime(_now), style: clockStyle),
        const SizedBox(height: 2),
        Text(formatDate(_now), style: dateStyle),
      ],
    );
  }

  /// Formats [time] as a 12-hour clock, e.g. "9:05 AM".
  static String formatTime(DateTime time) {
    final int hour24 = time.hour;
    final String period = hour24 < 12 ? 'AM' : 'PM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  /// Formats [date] as e.g. "Monday, January 1, 2025".
  static String formatDate(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, '
        '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

/// The kiosk Home_Screen header (Requirements 4.3, 5.1, 5.2).
///
/// A thin composition of [KioskHeaderBrand] and [KioskHeaderClock] kept for
/// backward compatibility; new layouts compose the two pieces directly (see
/// `KioskTopNavBar`).
class KioskHeader extends StatelessWidget {
  const KioskHeader({
    super.key,
    this.organizationContext,
    this.themeEngine,
    this.clock,
  });

  /// Injectable [OrganizationContext]; defaults to the registered singleton.
  final OrganizationContext? organizationContext;

  /// Injectable [ThemeEngine]; defaults to the registered singleton.
  final ThemeEngine? themeEngine;

  /// Injectable clock for the current time; defaults to [DateTime.now].
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: KioskHeaderBrand(
              organizationContext: organizationContext,
              themeEngine: themeEngine,
            ),
          ),
          const SizedBox(width: 16),
          KioskHeaderClock(clock: clock),
        ],
      ),
    );
  }
}
