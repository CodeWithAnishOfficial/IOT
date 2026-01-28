import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/reservation/views/booking_view.dart';
import 'package:user_app/core/theme/app_colors.dart';

class StationReservationDetailsView extends StatefulWidget {
  final Charger station;
  const StationReservationDetailsView({super.key, required this.station});

  @override
  State<StationReservationDetailsView> createState() => _StationReservationDetailsViewState();
}

class _StationReservationDetailsViewState extends State<StationReservationDetailsView> {
  bool _isMapInteracting = false;
  int? _selectedConnectorId;

  @override
  void initState() {
    super.initState();
    if (widget.station.connectors.isNotEmpty) {
      _selectedConnectorId = widget.station.connectors.first.connectorId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double defaultTop = screenHeight * 0.45; // Increased map area (was 0.40)
    final double collapsedTop = screenHeight - 140;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.station.location?.lat ?? 0.0,
                  widget.station.location?.lng ?? 0.0,
                ),
                zoom: 15,
              ),
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationButtonEnabled: false,
              // Adjusted padding to center marker optically in the top space
              padding: EdgeInsets.only(bottom: _isMapInteracting ? 140 : screenHeight * 0.50),
              markers: {
                Marker(
                  markerId: MarkerId(widget.station.chargerId),
                  position: LatLng(
                    widget.station.location?.lat ?? 0.0,
                    widget.station.location?.lng ?? 0.0,
                  ),
                  icon: Get.isRegistered<HomeController>() 
                      ? Get.find<HomeController>().getMarkerIcon(widget.station)
                      : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
              },
              onCameraMoveStarted: () {
                setState(() {
                  _isMapInteracting = true;
                });
              },
              onCameraIdle: () {
                setState(() {
                  _isMapInteracting = false;
                });
              },
            ),
          ),

          // 2. Top Action Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isMapInteracting ? 0.0 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Get.back(),
                  ),
                  // Optional right actions
                ],
              ),
            ),
          ),

          // 3. Bottom Content (Draggable Sheet Lookalike)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: _isMapInteracting ? collapsedTop : defaultTop,
            left: 0,
            right: 0,
            height: screenHeight - defaultTop,
            child: _buildBottomContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomContent(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Dark Header
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.station.name ?? "EV Station",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "4.8",
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildDarkInfoItem("${widget.station.distance?.toStringAsFixed(1) ?? '--'} km", "Distance"),
                          const SizedBox(width: 24),
                          _buildDarkInfoItem("24/7", "Availability"),
                        ],
                      ),
                    ],
                  ),
                ),

                // White Body
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Overview",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.black54),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.station.location?.address ?? "Address Not Available",
                                        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Stats Grid
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard(Icons.bolt, "Max Power", "${widget.station.maxPowerKw} KW")),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStatCard(Icons.ev_station, "Connectors", "${widget.station.connectors.length}")),
                                ],
                              ),

                              const SizedBox(height: 100), // Spacing for button
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

        // Floating Book Button
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to BookingView
              Get.to(() => BookingView(
                station: widget.station,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Dark Button
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  "Book Now",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Car Image
        Positioned(
          top: 70, // Adjust overlap
          right: -20, // Off-screen right slightly
          height: 140,
          child: Image.asset(
            "assets/images/station_detaile_ev_station_img.png",
            fit: BoxFit.contain,
            errorBuilder: (_,__,___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkInfoItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black87, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
