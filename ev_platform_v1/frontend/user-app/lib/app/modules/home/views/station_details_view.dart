import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/home/widgets/swipe_button.dart';
import 'package:user_app/core/theme/app_colors.dart';

class StationDetailsView extends StatefulWidget {
  final Charger station;
  final HomeController controller;

  const StationDetailsView({
    super.key,
    required this.station,
    required this.controller,
  });

  @override
  State<StationDetailsView> createState() => _StationDetailsViewState();
}

class _StationDetailsViewState extends State<StationDetailsView> {
  StreamSubscription? _polylineSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _sourceLocSub;
  Set<Polyline> _polylines = {};
  LatLng? _currentLoc;
  LatLng? _sourceLoc;
  bool _isMapInteracting = false; // State to track map interaction

  @override
  void initState() {
    super.initState();
    // Initialize initial state
    _polylines = widget.controller.stationPolylines.toSet();

    if (widget.controller.currentLocation.value != null) {
      _currentLoc = LatLng(
        widget.controller.currentLocation.value!.latitude,
        widget.controller.currentLocation.value!.longitude,
      );
    }

    if (widget.controller.sourceLatLng.value != null) {
      _sourceLoc = widget.controller.sourceLatLng.value;
    }

    // Listen for changes
    _polylineSub = widget.controller.stationPolylines.listen((polylines) {
      if (mounted) {
        setState(() {
          _polylines = polylines.toSet();
        });
      }
    });

    _locationSub = widget.controller.currentLocation.listen((position) {
      if (mounted) {
        setState(() {
          if (position != null) {
            _currentLoc = LatLng(position.latitude, position.longitude);
          } else {
            _currentLoc = null;
          }
        });
      }
    });

    _sourceLocSub = widget.controller.sourceLatLng.listen((latLng) {
      if (mounted) {
        setState(() {
          _sourceLoc = latLng;
        });
      }
    });
  }

  @override
  void dispose() {
    _polylineSub?.cancel();
    _locationSub?.cancel();
    _sourceLocSub?.cancel();
    widget.controller.clearRoute(); // Clear polylines on exit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double defaultTop = screenHeight * 0.40;
    final double collapsedTop = screenHeight - 140; // Only show part of header

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                screenHeight, // Full height to allow map to be visible when sheet collapses
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.station.location?.lat ?? 0,
                  widget.station.location?.lng ?? 0,
                ),
                zoom: 13,
              ),
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              mapToolbarEnabled: false,
              padding: EdgeInsets.only(
                bottom: _isMapInteracting ? 140 : screenHeight * 0.60,
              ), // Adjust attribution
              markers: {
                Marker(
                  markerId: MarkerId(widget.station.chargerId),
                  position: LatLng(
                    widget.station.location?.lat ?? 0,
                    widget.station.location?.lng ?? 0,
                  ),
                  icon: widget.controller.getMarkerIcon(widget.station),
                ),
                if (_currentLoc != null)
                  Marker(
                    markerId: const MarkerId("current"),
                    position: _currentLoc!,
                    icon: widget.controller.getSourceIcon(),
                  ),
                if (_sourceLoc != null &&
                    (_currentLoc == null ||
                        (_sourceLoc!.latitude != _currentLoc!.latitude ||
                            _sourceLoc!.longitude != _currentLoc!.longitude)))
                  Marker(
                    markerId: const MarkerId("route_start"),
                    position: _sourceLoc!,
                    icon: widget.controller.getSourceIcon(),
                    infoWindow: const InfoWindow(title: "Start"),
                  ),
              },
              polylines: _polylines,
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
              onMapCreated: (mapController) async {
                // Calculate route when map is created
                final bounds = await widget.controller.prepareRoute(
                  widget.station,
                );
                if (bounds != null) {
                  try {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 50),
                    );
                  } catch (e) {
                    debugPrint("Error animating local map: $e");
                  }
                }
              },
            ),
          ),

          // 2. Top Action Bar (Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isMapInteracting ? 0.0 : 1.0, // Hide on interaction
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Get.back(),
                  ),
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.favorite_border,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(icon: Icons.more_horiz, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Content (Draggable/Fixed Sheet)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: _isMapInteracting ? collapsedTop : defaultTop,
            left: 0,
            right: 0,
            height:
                screenHeight -
                defaultTop +
                50, // Ensure enough height to cover bottom area + buffer
            child: _buildBottomContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
        // Main Card Layout
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white, // Bottom part white
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Dark Header Section
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary, // Dark Navy/Black
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                      bottom: Radius.circular(30),
                    ),
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
                          // Battery % Mock
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.battery_charging_full,
                                  color: Colors.blueAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "14.4%",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildDarkInfoItem(
                            "${widget.station.distance?.toStringAsFixed(1) ?? '--'} km",
                            "Distance",
                          ),
                          const SizedBox(width: 24),
                          _buildDarkInfoItem(
                            "25 Mins",
                            "Avg. Time",
                          ), // Mock time
                        ],
                      ),
                    ],
                  ),
                ),

                // White Body Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent, // Background of parent is white
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                              // Address Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.station.location?.address ??
                                            "Address Not Available",
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
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
                                  Expanded(
                                    child: _buildStatCard(
                                      Icons.bolt,
                                      "Super charge",
                                      "${widget.station.maxPowerKw} KW",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      Icons.local_parking,
                                      "Parking",
                                      "Free parking",
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              Text(
                                "Connectors",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Connector Selection List
                              SizedBox(
                                height: 90,
                                child: widget.station.connectors.isEmpty
                                    ? Center(
                                        child: Text(
                                          "No connectors available",
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            widget.station.connectors.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final connector =
                                              widget.station.connectors[index];
                                          return Obx(() {
                                            final isSelected = widget
                                                .controller
                                                .selectedConnectorIds
                                                .contains(
                                                  connector.connectorId
                                                      .toString(),
                                                );
                                            return GestureDetector(
                                              onTap: () {
                                                if (connector.connectorId !=
                                                    null) {
                                                  widget.controller
                                                      .selectConnector(
                                                        connector.connectorId
                                                            .toString(),
                                                      );
                                                }
                                              },
                                              child: Container(
                                                width: 100,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : Colors.grey[300]!,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.electrical_services,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black54,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      connector.type ??
                                                          "Type 2",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      "${connector.maxPowerKw} kW",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: isSelected
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                            fontSize: 10,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "₹${widget.station.costPerUnit ?? '0.0'}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            "/kwh",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: SwipeButton(
                                      onSwipe: () {
                                        widget.controller.initiateCharging();
                                      },
                                      text: "Swipe to Start",
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      icon: Icons.bolt,
                                      height: 60,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.bottom +
                                        20,
                                  ),
                                ],
                              ),
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
        ),

        // Floating Car Image
        Positioned(
          top: 70, // Adjust overlap
          right: -20, // Off-screen right slightly
          height: 140,
          child: Image.asset(
            "assets/images/station_detaile_ev_station_img.png",
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const SizedBox.shrink(), // Hide if error
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
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
