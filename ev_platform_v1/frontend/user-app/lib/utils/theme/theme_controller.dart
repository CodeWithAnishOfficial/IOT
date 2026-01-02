import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/utils/theme/themes.dart';

class ThemeController extends GetxController {
  // ignore: constant_identifier_names
  static const String THEME_MODE_KEY = 'theme_mode';
  // ignore: constant_identifier_names
  static const String PRIMARY_COLOR_KEY = 'primary_color';

  // Observable variables
  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  final Rx<Color> primaryColor = const Color(0xFFCCFF00).obs;

  // Available theme colors
  final List<Color> availableColors = [
    const Color(0xFFCCFF00), // Neon Lime
    Colors.green,
    Colors.blue,

    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];

  final SharedPreferences? prefs; // Store the SharedPreferences instance

  ThemeController({this.prefs}); // Accept SharedPreferences in constructor

  @override
  void onInit() {
    super.onInit();
    loadThemePreferences();
  }

  // Load saved theme preferences
  Future<void> loadThemePreferences() async {
    if (prefs == null) {
      debugPrint('SharedPreferences not available, using default theme');
      return;
    }

    // Load primary color first so theme is updated before applying theme mode
    final savedColorValue = prefs!.getInt(PRIMARY_COLOR_KEY);
    if (savedColorValue != null) {
      // Find the color in available colors or default to Neon Lime
      final savedColor = availableColors.firstWhere(
        (color) => color.value == savedColorValue,
        orElse: () => const Color(0xFFCCFF00),
      );
      primaryColor.value = savedColor;

      // Update the app theme with the saved color
      updateAppTheme(savedColor);
    }

    // Load theme mode
    final savedThemeMode = prefs!.getString(THEME_MODE_KEY);
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          themeMode.value = ThemeMode.dark;
          break;
        default:
          themeMode.value = ThemeMode.system;
      }
    }

    // Apply the theme
    Get.changeTheme(
      themeMode.value == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
    );
    Get.changeThemeMode(themeMode.value);
  }

  // Change theme mode (light, dark, system)
  Future<void> changeThemeMode(ThemeMode mode) async {
    themeMode.value = mode;

    // Apply the theme
    Get.changeTheme(
      mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    );
    Get.changeThemeMode(mode);

    if (prefs == null) {
      debugPrint('SharedPreferences not available, cannot save theme mode');
      return;
    }

    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }

    await prefs!.setString(THEME_MODE_KEY, modeString);
  }

  // Change primary color
  Future<void> changePrimaryColor(Color color) async {
    primaryColor.value = color;

    // Update the app theme with the new color
    updateAppTheme(color);

    // Apply the theme
    Get.changeTheme(
      themeMode.value == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
    );
    Get.changeThemeMode(themeMode.value);

    if (prefs == null) {
      debugPrint('SharedPreferences not available, cannot save primary color');
      return;
    }

    await prefs!.setInt(PRIMARY_COLOR_KEY, color.value);
  }

  // Update app theme with new primary color
  void updateAppTheme(Color color) {
    // Update light theme
    AppTheme.lightTheme = AppTheme.lightTheme.copyWith(
      primaryColor: color,
      // primaryColorDark: color[800], // Remove specific shade dependence
      colorScheme: ColorScheme.light(
        primary: color,
        // secondary: color.shade200,
        surface: Colors.white,
        background: Colors.grey[50]!,
      ),
    );

    // Update dark theme
    AppTheme.darkTheme = AppTheme.darkTheme.copyWith(
      primaryColor: color,
      // primaryColorDark: color[800],
      colorScheme: ColorScheme.dark(
        primary: color,
        // secondary: color.shade200,
        surface: const Color(0xFF1E1E1E),
        background: const Color(
          0xFF111111,
        ), // Deep Black to match Charging Page
      ),
    );
  }

  // Get current theme data
  ThemeData get currentThemeData {
    if (themeMode.value == ThemeMode.dark) {
      return AppTheme.darkTheme;
    } else if (themeMode.value == ThemeMode.light) {
      return AppTheme.lightTheme;
    } else {
      // For system mode, check the platform brightness
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return platformBrightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
    }
  }
}
