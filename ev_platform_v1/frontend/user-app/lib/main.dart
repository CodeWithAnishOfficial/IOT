import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/bindings/initial_binding.dart';
import 'package:user_app/app/routes/app_pages.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:user_app/core/widgets/snackbar/safe_snackbar.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Google Maps setup
    try {
      if (!kIsWeb) {
        final GoogleMapsFlutterPlatform mapsImplementation =
            GoogleMapsFlutterPlatform.instance;
        if (mapsImplementation is GoogleMapsFlutterAndroid) {
          mapsImplementation.useAndroidViewSurface = true;
        }
      }
    } catch (e) {
      debugPrint('Error initializing Maps: $e');
    }

    // System UI
    SystemChrome.setPreferredOrientations([
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

    // Initialize SharedPreferences early
    final prefs = await SharedPreferences.getInstance();
    Get.put(prefs); // InitialBinding will find it

    runApp(const QuanEV());
  }, (error, stack) {
    // Ignore known Flutter Web Timer/RawKeyboard error
    if (kIsWeb && 
        error.toString().contains("LegacyJavaScriptObject") && 
        error.toString().contains("Timer")) {
      debugPrint("Ignored known Flutter Web Timer error to prevent crash: $error");
      return;
    }
    debugPrint("Uncaught error: $error");
    debugPrint(stack.toString());
  });
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
    return GetMaterialApp(
      title: 'QuanEV',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      builder: (context, child) {
          return child!;
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      navigatorObservers: [SnackbarCloseObserver()],
    );
  }
}
