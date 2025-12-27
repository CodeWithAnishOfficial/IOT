import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/utils/theme/theme_controller.dart';
import 'package:user_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts at Login screen when not logged in', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Initialize services
    Get.testMode = true;
    
    // Initialize ThemeController
    final themeController = ThemeController(prefs: prefs);
    Get.put(themeController);
    
    // Initialize SessionController
    Get.put(SessionController(), permanent: true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuanEV());
    await tester.pumpAndSettle();

    // Verify that the login screen is present
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
  });
}
