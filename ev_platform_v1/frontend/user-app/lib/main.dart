import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/View/NoInternetScreen.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/core/services/notification_service.dart';
import 'package:user_app/core/splash_screen.dart';
import 'package:user_app/feature/auth/presentation/controllers/auth_controller.dart';
import 'package:user_app/feature/auth/presentation/pages/login_view.dart';
import 'package:user_app/feature/auth/presentation/pages/register_view.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/home/presentation/pages/home_view.dart';
import 'package:user_app/feature/dashboard/presentation/pages/dashboard_view.dart';
import 'package:user_app/feature/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:user_app/feature/reservation/presentation/pages/reservation_view.dart';
import 'package:user_app/utils/theme/themes.dart';
import 'package:user_app/utils/theme/theme_controller.dart';
import 'package:user_app/core/controllers/connectivity_controller.dart';
import 'package:flutter/services.dart';
import 'package:user_app/utils/widgets/snackbar/safe_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/feature/more/presentation/pages/manage/presentation/pages/vehicle/presentation/controllers/vehicles_controller.dart';
import 'package:user_app/feature/wallet/presentation/controllers/wallet_controller.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';
import 'package:user_app/feature/session_history/presentation/controllers/session_history_controller.dart';
import 'package:user_app/feature/more/presentation/pages/help&support/presentation/controllers/support_controller.dart';
import 'package:user_app/feature/more/presentation/pages/help&support/presentation/pages/support_view.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/pages/profile_view.dart';
import 'package:user_app/feature/more/presentation/pages/manage/presentation/pages/vehicle/presentation/pages/vehicles_view.dart';
import 'package:user_app/feature/wallet/presentation/pages/wallet_view.dart';
import 'package:user_app/feature/session_history/presentation/pages/session_view.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting main initialization...');

  // Require Hybrid Composition for Google Maps on Android to prevent crashes/glitches
  try {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  } catch (e) {
    debugPrint('Error initializing Maps: $e');
  }

  // Don't await this to prevent startup hangs
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => debugPrint('Orientation set'));

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize ThemeController immediately with defaults so runApp works
  final themeController = ThemeController(prefs: null);
  Get.put(themeController);

  // Notification Service - Init instance but don't wait for internal init
  NotificationService notificationService = NotificationService();
  Get.put(notificationService, permanent: true);

  // Start the app immediately to prevent black screen
  runApp(const QuanEV());

  // Perform heavy initialization in the background
  _initServices(themeController, notificationService);
}

Future<void> _initServices(
    ThemeController themeController, NotificationService notificationService) async {
  SharedPreferences? prefs;
  try {
    debugPrint('Initializing SharedPreferences in background...');
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
  }

  // Update ThemeController with loaded prefs
  if (prefs != null) {
    themeController.setPrefs(prefs);
    await themeController.loadThemePreferences();
  }

  // Init Notification Service internals
  try {
    await notificationService.init();
    notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
  }

  // Session Controller
  try {
    // Pass prefs to SessionController to avoid double initialization
    Get.put(SessionController(sharedPreferences: prefs), permanent: true);
  } catch (e) {
    debugPrint('Error putting SessionController: $e');
  }

  try {
    Get.put(ConnectivityController());
  } catch (e) {
    debugPrint('Error putting ConnectivityController: $e');
  }

  try {
    Get.put(AuthController());
  } catch (e) {
    debugPrint('Error putting AuthController: $e');
  }

  try {
    // Lazy put others
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => VehiclesController(), fenix: true);
    Get.lazyPut(() => WalletController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => SessionHistoryController(), fenix: true);
    Get.lazyPut(() => SupportController(), fenix: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
  } catch (e) {
    debugPrint('Error lazy putting controllers: $e');
  }
}

class SnackbarCloseObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    SafeSnackbar.closeAll();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    SafeSnackbar.closeAll();
    super.didPop(route, previousRoute);
  }
}

class QuanEV extends StatelessWidget {
  const QuanEV({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: GetMaterialApp(
          title: 'QuanEV',
          debugShowCheckedModeBanner: false,
          // Global Background Builder
          builder: (context, child) {
            return Stack(
              children: [
                // 0. Fallback Black Background (in case image fails)
                Positioned.fill(
                  child: Container(color: const Color(0xFF111111)),
                ),
                // 1. Global Background Image
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/ChargingPage_bg.png",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("Background image failed to load: $error");
                      return const SizedBox(); // Fallback to black container
                    },
                  ),
                ),
                // 2. Global Dark Overlay (to ensure readability if needed)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF111111).withOpacity(
                      0.85,
                    ), // High opacity to mimic deep black theme but keep texture
                  ),
                ),
                // 3. App Content
                if (child != null) child,
              ],
            );
          },
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode.value,
          initialRoute: '/',
          navigatorObservers: [SnackbarCloseObserver()],
          getPages: [
            GetPage(
              name: '/',
              page: () => const SplashScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/login',
              page: () => const LoginView(),
              binding: BindingsBuilder(() {
                Get.lazyPut<AuthController>(() => AuthController());
              }),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: '/register',
              page: () => const RegisterView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/home',
              page: () => const DashboardView(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: '/dashboard', // Alias
              page: () => const DashboardView(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/noInternet',
              page: () => const NoInternetScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/profile',
              page: () => const ProfileView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/wallet',
              page: () => const WalletView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/my-vehicles',
              page: () => const VehiclesView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/charging-sessions',
              page: () => const SessionView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/support',
              page: () => const SupportView(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/reservations',
              page: () => const ReservationView(),
              transition: Transition.rightToLeft,
            ),
          ],
        ),
      ),
    );
  }
}
