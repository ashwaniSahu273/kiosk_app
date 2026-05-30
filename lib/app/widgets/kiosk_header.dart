import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/data/models/models.dart';
import '../core/services/organization_context.dart';
import '../core/services/theme_engine.dart';

/// The kiosk Home_Screen header (Requirements 4.3, 5.1, 5.2).
///
/// Shows the active organization's logo (resolved through
/// [ThemeEngine.resolveLogo], falling back to the bundled placeholder via
/// [ThemeEngine.reportLogoLoadFailure] if the resolved image fails to load),
/// the organization display name, the current calendar date, and a live clock
/// that is refreshed at least once every 60 seconds.
///
/// Branding is pulled reactively from the [OrganizationContext], so the header
/// re-renders when a different organization becomes active. The internal clock
/// [Timer] is created in [State.initState] and cancelled in [State.dispose].
class KioskHeader extends StatefulWidget {
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
  State<KioskHeader> createState() => _KioskHeaderState();
}

class _KioskHeaderState extends State<KioskHeader> {
  /// Ticks the live clock. A 1-second period keeps the displayed time current
  /// and comfortably satisfies the "at least every 60 seconds" rule (5.2).
  static const Duration _tick = Duration(seconds: 1);

  Timer? _timer;
  late DateTime _now;

  DateTime Function() get _clock => widget.clock ?? DateTime.now;

  OrganizationContext get _orgContext =>
      widget.organizationContext ?? Get.find<OrganizationContext>();

  ThemeEngine get _themeEngine =>
      widget.themeEngine ?? Get.find<ThemeEngine>();

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
    final ColorScheme scheme = theme.colorScheme;

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
      child: Obx(() {
        final BrandingProfile? branding = _orgContext.branding;
        return Row(
          children: <Widget>[
            _buildLogo(branding),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                branding?.displayName ?? '',
                style: (theme.textTheme.headlineSmall ?? const TextStyle())
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            _buildDateTime(theme),
          ],
        );
      }),
    );
  }

  Widget _buildLogo(BrandingProfile? branding) {
    const double logoSize = 56;
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

  Widget _buildDateTime(ThemeData theme) {
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
        Text(_formatTime(_now), style: clockStyle),
        const SizedBox(height: 2),
        Text(_formatDate(_now), style: dateStyle),
      ],
    );
  }

  /// Formats [time] as a 12-hour clock, e.g. "9:05 AM".
  static String _formatTime(DateTime time) {
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
  static String _formatDate(DateTime date) {
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
