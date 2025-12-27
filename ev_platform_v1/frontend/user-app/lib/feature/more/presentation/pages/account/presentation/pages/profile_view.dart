import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';
import 'package:user_app/routes/app_routes.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        if (user == null) {
          return const Center(child: Text('Profile not loaded'));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.username ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                user.emailId,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            if (user.phoneNo != null)
              Center(
                child: Text(
                  user.phoneNo!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 32),

            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('My Vehicles'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed(Routes.MY_VEHICLES),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Charging Sessions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed(Routes.CHARGING_SESSIONS),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed(Routes.SUPPORT),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: controller.logout,
            ),
          ],
        );
      }),
    );
  }

  void _showEditDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'Edit Profile',
      content: Column(
        children: [
          TextField(
            controller: controller.nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      onConfirm: controller.updateProfile,
    );
  }
}
