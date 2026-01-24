import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primaryColor, width: 2),
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quan EV',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
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
                      color: theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'We are dedicated to building the future of sustainable transportation. Our platform connects EV drivers with reliable charging stations, ensuring a seamless and eco-friendly journey for everyone.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
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
                      color: theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(context, [
                    _buildMenuItem(context, Icons.description_outlined, 'Terms of Service'),
                    _buildDivider(context),
                    _buildMenuItem(context, Icons.privacy_tip_outlined, 'Privacy Policy'),
                    _buildDivider(context),
                    _buildMenuItem(context, Icons.cookie_outlined, 'Cookie Policy'),
                  ]),

                  const SizedBox(height: 32),
                  Text(
                    'CONNECT WITH US',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(context, [
                    _buildMenuItem(context, Icons.language, 'Website'),
                    _buildDivider(context),
                    _buildMenuItem(context, Icons.facebook, 'Facebook'),
                    _buildDivider(context),
                    _buildMenuItem(context, Icons.link, 'Twitter'), // Using generic link icon for X/Twitter
                    _buildDivider(context),
                    _buildMenuItem(context, Icons.camera_alt_outlined, 'Instagram'),
                  ]),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      '© 2024 Quan EV Inc.\nAll rights reserved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.disabledColor,
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

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: theme.disabledColor, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 56,
    );
  }
}
