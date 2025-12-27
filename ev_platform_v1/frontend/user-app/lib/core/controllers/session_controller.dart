import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionController extends GetxController {
  var isLoggedIn = false.obs;
  var userId = 0.obs;
  var username = ''.obs;
  var token = ''.obs;
  var emailId = ''.obs;

  late SharedPreferences prefs;

  SessionController() {
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    loadSession();
  }

  @override
  void onInit() {
    super.onInit();
  }

  // Load session from shared preferences
  Future<void> loadSession() async {
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    userId.value = prefs.getInt('userId') ?? 0;
    username.value = prefs.getString('username') ?? '';
    emailId.value = prefs.getString('emailId') ?? '';
    token.value = prefs.getString('token') ?? '';
  }

  // Save session to shared preferences
  Future<void> saveSession({
    required int userId,
    required String emailId,
    required String token,
    String? username,
  }) async {
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', userId);
    await prefs.setString('emailId', emailId);
    await prefs.setString('token', token);
    if (username != null && username.isNotEmpty) {
      await prefs.setString('username', username);
      this.username.value = username;
    }
    this.userId.value = userId;
    this.emailId.value = emailId;
    this.token.value = token;
    isLoggedIn.value = true;
  }

  // Clear session data
  Future<void> clearSession() async {
    await prefs.clear();
    isLoggedIn.value = false;
    userId.value = 0;
    username.value = '';
    token.value = '';
    emailId.value = '';
  }
}
