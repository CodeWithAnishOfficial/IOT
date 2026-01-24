import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/controllers/connectivity_controller.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/core/controllers/theme_controller.dart';
import 'package:user_app/core/services/notification_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ConnectivityController(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    
    // Attempt to find SharedPreferences. 
    // Ideally main.dart puts it before running app or concurrently.
    try {
      final prefs = Get.find<SharedPreferences>();
      Get.put(ThemeController(prefs: prefs), permanent: true);
      Get.put(SessionController(sharedPreferences: prefs), permanent: true);
    } catch (e) {
      // If not found, we can try Get.putAsync or rely on late initialization
      print("SharedPreferences not found in InitialBinding: $e");
    }
  }
}
