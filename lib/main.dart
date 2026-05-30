import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/config/app_constants.dart';
import 'app/core/data/demo_data_source.dart';
import 'app/core/data/kiosk_repository.dart';
import 'app/core/data/models/models.dart';
import 'app/core/network/api_client.dart';
import 'app/core/notifications/notification_service.dart';
import 'app/core/services/organization_context.dart';
import 'app/core/services/storage_service.dart';
import 'app/core/services/theme_engine.dart';
import 'app/modules/auth/auth_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

/// Application entry point and bootstrap (Requirements 2.1, 2.2, 4.2, 10.5,
/// 10.7).
///
/// Bootstrap sequence:
/// 1. Initialize the Flutter binding.
/// 2. Force landscape orientation and full-screen immersive mode for the
///    wall-mounted kiosk.
/// 3. Register the permanent core-service singletons in dependency order and
///    wire their cross-cutting collaborators (theme warnings -> notifications,
///    organization theme builder -> theme engine, network auth context ->
///    auth service).
/// 4. Restore any persisted session and decide the initial route: Home when a
///    complete session is restored (organization activated + theme built),
///    otherwise Login (Requirements 2.1, 2.2).
/// 5. Run the [KioskApp], whose `GetMaterialApp.theme` is driven by the
///    observable organization theme so the whole tree re-themes when the
///    organization changes (Requirement 4.2).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureKioskDisplay();

  await _registerCoreServices();

  // Restore a persisted session; route to Home only when a complete session
  // was restored (org activated + theme built), otherwise to Login
  // (Requirements 2.1, 2.2).
  final AuthService authService = Get.find<AuthService>();
  final bool restored = await authService.restoreSession();
  final String initialRoute = restored ? AppRoutes.home : AppRoutes.login;

  runApp(KioskApp(initialRoute: initialRoute));
}

/// Forces landscape orientation and full-screen immersive mode so the kiosk
/// fills a wall-mounted touchscreen with no system chrome.
Future<void> _configureKioskDisplay() async {
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

/// Registers the permanent core-service singletons in dependency order and
/// wires their cross-service collaborators.
///
/// Order matters: [StorageService] is awaited first (it backs the session and
/// cached branding), then the services that depend on it. The network
/// [ApiClient] is wired last with [AuthService] as its [ApiAuthContext] so it
/// can inject the bearer token / organization id and trigger token refresh.
Future<void> _registerCoreServices() async {
  // 1. Storage (async init) — backs sessions and cached branding.
  final StorageService storageService =
      await Get.putAsync<StorageService>(() => StorageService().init());

  // 2. Notifications — the single shared snackbar entry point.
  final NotificationService notificationService =
      Get.put<NotificationService>(NotificationService(), permanent: true);

  // 3. Theme engine — routes its configuration warnings through notifications.
  final ThemeEngine themeEngine =
      Get.put<ThemeEngine>(ThemeEngine(), permanent: true);
  themeEngine.onConfigWarning = notificationService.warning;

  // 4. Organization context — drives the observable theme via the engine.
  final OrganizationContext organizationContext = Get.put<OrganizationContext>(
    OrganizationContext(storageService: storageService),
    permanent: true,
  );
  organizationContext.setThemeBuilder(themeEngine.buildTheme);

  // 5. Demo data source + repository — back the offline demo.
  final DemoDataSource demoDataSource =
      Get.put<DemoDataSource>(DemoDataSource(), permanent: true);
  final KioskRepository repository = Get.put<KioskRepository>(
    KioskRepository(dataSource: demoDataSource),
    permanent: true,
  );

  // 6. Auth service — coordinates repository + storage + organization context
  //    and implements ApiAuthContext for the network layer.
  final AuthService authService = Get.put<AuthService>(
    AuthService(
      repository: repository,
      storageService: storageService,
      organizationContext: organizationContext,
    ),
    permanent: true,
  );

  // 7. Network client — wired with AuthService as its auth/organization context.
  Get.put<ApiClient>(
    ApiClient(authContext: authService),
    permanent: true,
  );
}

/// Root widget. Drives `GetMaterialApp.theme` from the observable organization
/// theme so the entire tree re-themes when the active organization changes,
/// falling back to a documented default theme before any organization is active
/// so no screen ever renders un-themed (Requirement 4.2).
class KioskApp extends StatelessWidget {
  const KioskApp({super.key, required this.initialRoute});

  /// The route the app launches into (Home for a restored session, else Login).
  final String initialRoute;

  /// Documented default theme applied before any organization is active.
  ///
  /// Built from a default [BrandingProfile] (no colors specified) so the
  /// [ThemeEngine] substitutes the documented Palos palette defaults, ensuring
  /// the login screen and any pre-activation frame are fully themed.
  static const BrandingProfile _defaultBranding = BrandingProfile(
    organizationId: 'default',
    displayName: AppConstants.appName,
  );

  @override
  Widget build(BuildContext context) {
    final OrganizationContext organizationContext =
        Get.find<OrganizationContext>();
    final ThemeEngine themeEngine = Get.find<ThemeEngine>();
    final ThemeData defaultTheme = themeEngine.buildTheme(_defaultBranding);

    return Obx(
      () => GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: organizationContext.theme.value ?? defaultTheme,
        initialRoute: initialRoute,
        getPages: AppPages.pages,
      ),
    );
  }
}
