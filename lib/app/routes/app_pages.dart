import 'package:get/get.dart';

import '../core/middleware/auth_middleware.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_view.dart';
import '../modules/donate/donate_binding.dart';
import '../modules/donate/donate_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/prayers/prayers_binding.dart';
import '../modules/prayers/prayers_view.dart';
import '../modules/programs/programs_binding.dart';
import '../modules/programs/programs_view.dart';
import 'app_routes.dart';

/// The GetX routing table for the kiosk app (Requirements 2.3, 10.7).
///
/// The login route is unprotected and uses the [AuthBinding] + [LoginView]. The
/// kiosk destinations (Home, Donate, Prayers, Programs) are protected: each
/// carries an [AuthMiddleware] that redirects to [AppRoutes.login] when no
/// complete session exists (session-existence check only).
///
/// The destinations (Home, Donate, Prayers, Programs) are the full
/// organization-scoped, themed screens. The Donate and Programs routes also
/// accept an optional route argument (a `DonationCategory` / `Program`) passed
/// from the matching Home control to open that item's entry point directly.
class AppPages {
  const AppPages._();

  /// The complete list of routable pages, consumed by
  /// `GetMaterialApp(getPages: AppPages.pages)`.
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.donate,
      page: () => const DonateView(),
      binding: DonateBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.prayers,
      page: () => const PrayersView(),
      binding: PrayersBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.programs,
      page: () => const ProgramsView(),
      binding: ProgramsBinding(),
      middlewares: <GetMiddleware>[AuthMiddleware()],
    ),
  ];
}
