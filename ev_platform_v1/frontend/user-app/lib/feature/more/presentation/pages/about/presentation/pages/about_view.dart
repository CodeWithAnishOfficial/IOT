import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: backgroundColor,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Get.theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Get.theme.primaryColor, width: 2),
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quan EV',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABOUT US',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Get.theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'We are dedicated to building the future of sustainable transportation. Our platform connects EV drivers with reliable charging stations, ensuring a seamless and eco-friendly journey for everyone.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'LEGAL & PRIVACY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Get.theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(cardColor, [
                    _buildMenuItem(Icons.description_outlined, 'Terms of Service'),
                    _buildDivider(),
                    _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Policy'),
                    _buildDivider(),
                    _buildMenuItem(Icons.cookie_outlined, 'Cookie Policy'),
                  ]),

                  const SizedBox(height: 32),
                  Text(
                    'CONNECT WITH US',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Get.theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(cardColor, [
                    _buildMenuItem(Icons.language, 'Website'),
                    _buildDivider(),
                    _buildMenuItem(Icons.facebook, 'Facebook'),
                    _buildDivider(),
                    _buildMenuItem(Icons.link, 'Twitter'), // Using generic link icon for X/Twitter
                    _buildDivider(),
                    _buildMenuItem(Icons.camera_alt_outlined, 'Instagram'),
                  ]),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      '© 2024 Quan EV Inc.\nAll rights reserved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 56,
    );
  }
}
