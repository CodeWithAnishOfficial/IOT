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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Require Hybrid Composition for Google Maps on Android to prevent crashes/glitches
  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
  }

  // Notification Service
  NotificationService notificationService = NotificationService();
  Get.put(notificationService, permanent: true);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await notificationService.init();
      await notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  });

  // Theme Controller
  final themeController = ThemeController(prefs: prefs);
  Get.put(themeController);
  try {
    await themeController.loadThemePreferences();
  } catch (e) {
    themeController.changeThemeMode(ThemeMode.light);
  }

  // Controllers
  try {
      Get.put(SessionController(), permanent: true);
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
  } catch (e) {
      debugPrint('Error lazy putting controllers: $e');
  }

  runApp(const QuanEV());
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
     
     return Obx(() => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: GetMaterialApp(
            title: 'QuanEV',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode.value,
            initialRoute: '/',
            navigatorObservers: [
              SnackbarCloseObserver(),
            ],
            getPages: [
              GetPage(
                name: '/', 
                page: () => const SplashScreen(),
                transition: Transition.fadeIn,
              ),
              GetPage(
                name: '/login', 
                page: () => const LoginView(),
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
                page: () => const HomeView(),
                transition: Transition.fadeIn,
                transitionDuration: const Duration(milliseconds: 500),
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
            ],
          ),
        ));
  }
}
