import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                          icon: Icon(Icons.arrow_back, color: textColor),
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
                                    color: AppColors.primary.withOpacity(0.2),
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
                                    color: AppColors.primary.withOpacity(0.1),
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
                                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
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
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: const Icon(Icons.person, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(height: 6, width: 60, color: AppColors.gray300),
                                            const SizedBox(height: 6),
                                            Container(height: 6, width: 40, color: AppColors.gray300),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            username,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditProfileSheet(context),
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subTextColor,
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
                Divider(thickness: 1, height: 1, color: isDark ? Colors.white12 : Colors.black12),

                // 3. Simple List Items
                _buildSimpleListItem(
                  title: "Corporate profile",
                  textColor: textColor,
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                ),
                _buildSimpleListItem(
                  title: "Favourite Locations",
                  textColor: textColor,
                  onTap: () {},
                ),
                
                const SizedBox(height: 16),
                Divider(thickness: 1, height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),

                // 4. Safety & Privacy Section
                _buildSectionItem(
                  icon: Icons.security,
                  title: "Safety & Privacy",
                  subtitle: "Manage account security and privacy",
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {},
                ),
                
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4, bottom: 12),
                  child: Column(
                    children: [
                      _buildSubListItem(title: "Emergency contacts", textColor: textColor, onTap: () {}),
                      _buildSubListItem(title: "Location", textColor: textColor, onTap: () {}),
                      _buildSubListItem(title: "Data and Privacy", textColor: textColor, onTap: () {}),
                    ],
                  ),
                ),

                Divider(thickness: 1, height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),

                // 5. Ride Settings
                _buildSectionItem(
                  icon: Icons.settings_outlined,
                  title: "Ride Settings",
                  subtitle: "Set or edit your ride preference",
                  textColor: textColor,
                  subTextColor: subTextColor,
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

  Widget _buildSimpleListItem({required String title, required Color textColor, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSubListItem({required String title, required Color textColor, required VoidCallback onTap}) {
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
                  color: textColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
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
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: textColor),
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
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller.nameController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.phoneController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
