import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';

class SavedTripsView extends StatefulWidget {
  const SavedTripsView({super.key});

  @override
  State<SavedTripsView> createState() => _SavedTripsViewState();
}

class _SavedTripsViewState extends State<SavedTripsView> {
  final HomeController controller = Get.find<HomeController>();
  final ScrollController _scrollController = ScrollController();
  
  DashboardController? _dashboardController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<DashboardController>()) {
      _dashboardController = Get.find<DashboardController>();
    }
    
    // Fetch trips when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSavedTrips();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow content behind nav/status bar
      backgroundColor: Colors.black, // Deep black for glassy pop
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.3),
                  backgroundBlendMode: BlendMode.screen,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withOpacity(0.2),
                  backgroundBlendMode: BlendMode.screen,
                ),
              ),
            ),
          ),

          // Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (_dashboardController != null) {
                if (notification.direction == ScrollDirection.reverse) {
                  // Scrolling Down -> Hide Nav
                  if (_dashboardController!.isNavBarVisible.value) {
                    _dashboardController!.isNavBarVisible.value = false;
                  }
                } else if (notification.direction == ScrollDirection.forward) {
                  // Scrolling Up -> Show Nav
                  if (!_dashboardController!.isNavBarVisible.value) {
                    _dashboardController!.isNavBarVisible.value = true;
                  }
                }
              }
              return true;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Glassy App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 120.0,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        title: Text(
                          "Saved Trips",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Container(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Get.back(),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 20),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

                // Content List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: Obx(() {
                    if (controller.savedTrips.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              Icon(Icons.map_outlined, color: Colors.white.withOpacity(0.3), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                "No saved trips yet",
                                style: GoogleFonts.poppins(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final trip = controller.savedTrips[index];
                          return _buildGlassyTripCard(context, trip);
                        },
                        childCount: controller.savedTrips.length,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyTripCard(BuildContext context, dynamic trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card Header / Gradient Cover
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.4),
                        Colors.purpleAccent.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pattern Overlay (Optional)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PatternPainter(),
                        ),
                      ),
                      // Trip Name & Date
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Buttons (Top Right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Row(
                          children: [
                             _buildCircleAction(
                               icon: Icons.play_arrow_rounded, 
                               color: AppColors.success, 
                               onTap: () => controller.loadSavedTrip(trip)
                             ),
                             const SizedBox(width: 8),
                             _buildCircleAction(
                               icon: Icons.delete_outline_rounded, 
                               color: AppColors.error, 
                               onTap: () => _confirmDelete(context, trip.id)
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildLocationRow(Icons.my_location_rounded, "Start", trip.source.address, Colors.blue),
                      
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 24,
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.withOpacity(0.5), Colors.red.withOpacity(0.5)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      _buildLocationRow(Icons.location_on_rounded, "Destination", trip.destination.address, Colors.red),
                      
                      if (trip.stops.isNotEmpty) ...[
                         const SizedBox(height: 16),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.05),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(Icons.add_location_alt_rounded, color: Colors.orange, size: 16),
                               const SizedBox(width: 8),
                               Text(
                                 "${trip.stops.length} Stops",
                                 style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                               ),
                             ],
                           ),
                         ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: accentColor, size: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String tripId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.9),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Delete Trip?",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This action cannot be undone.",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            controller.deleteSavedTrip(tripId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Simple texture painter for the card header
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    const step = 20.0;
    for (double i = 0; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(i, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

