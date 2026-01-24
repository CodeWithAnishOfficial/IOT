import 'package:get/get.dart';
import 'package:user_app/app/routes/app_routes.dart';

import 'package:user_app/app/modules/splash/views/splash_view.dart';
import 'package:user_app/app/modules/auth/views/login_view.dart';
import 'package:user_app/app/modules/auth/views/register_view.dart';
import 'package:user_app/app/modules/dashboard/views/dashboard_view.dart';
import 'package:user_app/core/views/no_internet_screen.dart';

// Remaining features
import 'package:user_app/app/modules/profile/views/profile_view.dart';
import 'package:user_app/app/modules/wallet/views/wallet_view.dart';
import 'package:user_app/app/modules/vehicles/views/vehicles_view.dart';
import 'package:user_app/app/modules/session_history/views/session_view.dart';
import 'package:user_app/app/modules/support/views/support_view.dart';
import 'package:user_app/app/modules/reservation/views/reservation_view.dart';

// Controllers
import 'package:user_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:user_app/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:user_app/app/modules/vehicles/controllers/vehicles_controller.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';
import 'package:user_app/app/modules/support/controllers/support_controller.dart';


class AppPages {
  static const INITIAL = Routes.INITIAL;

  static final routes = [
    GetPage(
      name: Routes.INITIAL,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.HOME, // Dashboard is the main home
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => HomeController()); // Dashboard uses HomeView which needs HomeController
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => HomeController());
      }),
    ),
    GetPage(
      name: Routes.NO_INTERNET,
      page: () => const NoInternetScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.WALLET,
      page: () => const WalletView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WalletController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.MY_VEHICLES,
      page: () => const VehiclesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => VehiclesController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.CHARGING_SESSIONS,
      page: () => const SessionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SessionHistoryController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.SUPPORT,
      page: () => const SupportView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SupportController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.RESERVATIONS,
      page: () => const ReservationView(),
      // ReservationController?
      transition: Transition.rightToLeft,
    ),
  ];
}
