import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String THEME_MODE_KEY = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  
  SharedPreferences? prefs;

  ThemeController({this.prefs});

  void setPrefs(SharedPreferences newPrefs) {
    prefs = newPrefs;
  }

  @override
  void onInit() {
    super.onInit();
    loadThemePreferences();
  }

  Future<void> loadThemePreferences() async {
    if (prefs == null) return;

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

    Get.changeThemeMode(themeMode.value);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);

    if (prefs == null) return;

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
}
