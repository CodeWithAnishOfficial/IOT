import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/app/modules/auth/domain/models/user.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final SessionController _sessionController = Get.find<SessionController>();

  final user = Rxn<User>();
  final isLoading = false.obs;
  
  // Reservation
  final upcomingReservationText = Rxn<String>();

  // Edit Profile Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchUpcomingReservation();
  }

  Future<void> fetchUpcomingReservation() async {
    try {
      final response = await _apiProvider.get('/reservations/upcoming');
      if (response['data'] != null) {
        final expiry = DateTime.parse(response['data']['expiry_date']);
        // Format: "Today 14:00" or "Tom 10:30"
        final now = DateTime.now();
        final isToday = expiry.year == now.year && expiry.month == now.month && expiry.day == now.day;
        final timeStr = "${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}";
        
        upcomingReservationText.value = isToday ? "Today $timeStr" : "${expiry.day}/${expiry.month} $timeStr";
      } else {
        upcomingReservationText.value = null;
      }
    } catch (e) {
      print("Error fetching upcoming reservation: $e");
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.get('/profile/me');
      if (response['data'] != null) {
        user.value = User.fromJson(response['data']);

        // Initialize edit controllers
        nameController.text = user.value?.username ?? '';
        phoneController.text = user.value?.phoneNo ?? '';
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.put('/profile/me', {
        'username': nameController.text,
        'phone_no': phoneController.text,
      });

      if (response['data'] != null) {
        user.value = User.fromJson(response['data']);
        Get.back();
        Get.snackbar('Success', 'Profile updated');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await _sessionController.clearSession();
    Get.offAllNamed('/login');
  }
}
