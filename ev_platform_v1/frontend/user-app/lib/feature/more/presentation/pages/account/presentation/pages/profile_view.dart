import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';
import 'package:user_app/routes/app_routes.dart';
import 'package:user_app/utils/theme/themes.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        // Fallback for null user to allow UI development/preview
        final username = user?.username ?? 'Anishkumar a';
        final phone = user?.phoneNo ?? '+91 8870208686';
        final email = user?.emailId ?? 'anishkumarak8686@gmail.com';

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Area with Back Button and Graphics
                SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      // Back Button
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ),

                      // Right Side Graphic (ID Card Style)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SizedBox(
                          width: 180,
                          height: 160,
                          child: Stack(
                            children: [
                              // Green Blob Background
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 40,
                                top: 10,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              
                              // The ID Card
                              Positioned(
                                right: 20,
                                top: 40,
                                child: Container(
                                  width: 140,
                                  height: 90,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white24,
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(height: 6, width: 60, color: Colors.white12),
                                            const SizedBox(height: 6),
                                            Container(height: 6, width: 40, color: Colors.white12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(thickness: 1, height: 1, color: Colors.white12),

                // 3. Simple List Items
                _buildSimpleListItem(
                  title: "Corporate profile",
                  onTap: () {},
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Divider(height: 1, color: Colors.white12),
                ),
                _buildSimpleListItem(
                  title: "Favourite Locations",
                  onTap: () {},
                ),
                
                const SizedBox(height: 16),
                const Divider(thickness: 1, height: 1, color: Colors.white12),
                const SizedBox(height: 16),

                // 4. Safety & Privacy Section
                _buildSectionItem(
                  icon: Icons.security,
                  title: "Safety & Privacy",
                  subtitle: "Manage account security and privacy",
                  onTap: () {},
                ),
                
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4, bottom: 12),
                  child: Column(
                    children: [
                      _buildSubListItem(title: "Emergency contacts", onTap: () {}),
                      _buildSubListItem(title: "Location", onTap: () {}),
                      _buildSubListItem(title: "Data and Privacy", onTap: () {}),
                    ],
                  ),
                ),

                const Divider(thickness: 1, height: 1, color: Colors.white12),
                const SizedBox(height: 16),

                // 5. Ride Settings
                _buildSectionItem(
                  icon: Icons.settings_outlined,
                  title: "Ride Settings",
                  subtitle: "Set or edit your ride preference",
                  onTap: () {},
                ),
                
                // Logout Option (Added for functionality)
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: controller.logout,
                    child: Text(
                      "Logout",
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSimpleListItem({required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
      onTap: onTap,
    );
  }

  Widget _buildSubListItem({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 24),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
