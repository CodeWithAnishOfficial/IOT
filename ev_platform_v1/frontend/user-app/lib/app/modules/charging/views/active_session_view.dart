import 'dart:ui'; // Added for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Added for ScrollDirection
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/charging/controllers/charging_controller.dart';
import 'package:user_app/app/modules/home/widgets/swipe_button.dart';
import 'package:user_app/core/theme/app_colors.dart';

class ChargingView extends StatefulWidget {
  final ChargingController controller;

  const ChargingView({super.key, required this.controller});

  @override
  State<ChargingView> createState() => _ChargingViewState();
}

class _ChargingViewState extends State<ChargingView> {
  late ScrollController _scrollController;
  final RxBool _isBottomBarVisible = true.obs;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isBottomBarVisible.value) _isBottomBarVisible.value = false;
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomBarVisible.value) _isBottomBarVisible.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Mode Background
      body: Stack(
        children: [
          // 1. Ambient Background Effects
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
                  color: AppColors.success.withOpacity(
                    0.2,
                  ), // Green glow for charging
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
                  color: Colors.blueAccent.withOpacity(0.2),
                  backgroundBlendMode: BlendMode.screen,
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20.0,
                  0, // Removed top padding from here to control it better
                  20.0,
                  80.0,
                ), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacing for Fixed Header
                    const SizedBox(height: 80), 
                    
                    // Top Stats Row (Connector, Power, ID)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0), // Added top padding for stats
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTopStatItem(
                            Icons.electrical_services,
                            "CCS 2",
                            "Connector",
                          ),
                          _buildTopStatItem(
                            Icons.flash_on,
                            "120 kW",
                            "Max Speed",
                          ),
                          _buildTopStatItem(
                            Icons.ev_station,
                            "ID: 402",
                            "Station",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Hero Car Image (Centered)
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/ev-car-charging-screen-img.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Bento Grid Layout
                    SizedBox(
                      height: 220,
                      child: Row(
                        children: [
                          // Large Battery Card (Left)
                          Expanded(
                            flex: 3,
                            child: _buildGlassyCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.battery_charging_full,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Battery",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Obx(
                                    () => Text(
                                      "${widget.controller.soc.value.toInt()}%",
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                        shadows: [
                                          BoxShadow(
                                            color: AppColors.success
                                                .withOpacity(0.5),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Visual Battery Bars (Animated)
                                  _AnimatedBatteryBars(
                                    controller: widget.controller,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Right Column Cards
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                // Top Right: Status
                                Expanded(
                                  child: _buildGlassyCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timelapse,
                                              size: 16,
                                              color: Colors.white60,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Status",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(
                                          () => Text(
                                            widget.controller.status.value,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (widget.controller.status.value ==
                                            "Charging")
                                          _ThreeBlinkingDots(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Bottom Right: Energy
                                Expanded(
                                  child: _buildGlassyCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.bolt,
                                              size: 16,
                                              color: Colors.white60,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Energy",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(
                                          () => Text(
                                            "${widget.controller.energyDelivered.value.toStringAsFixed(1)} kWh",
                                            style: GoogleFonts.orbitron(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Additional Info Row (Cost & Power)
                    Row(
                      children: [
                        Expanded(
                          child: _buildBottomInfoCard(
                            "Current Cost",
                            widget.controller.currentCost,
                            "₹",
                            Icons.currency_rupee,
                            isCurrency: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBottomInfoCard(
                            "Current Power",
                            widget.controller.currentPower,
                            "kW",
                            Icons.flash_on,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // 3. Fixed Header (App Bar like Home Page)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Active Session",
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating Swipe to Stop (Bottom)
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _isBottomBarVisible.value ? 30 : -100,
              left: 20,
              right: 20,
              child: SwipeButton(
                onSwipe: widget.controller.stopCharging,
                text: "Swipe to Stop Charging",
                backgroundColor: AppColors.error.withOpacity(0.8),
                foregroundColor: Colors.white,
                icon: Icons.power_settings_new_rounded,
                height: 64,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTopStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
            ],
          ),
          child: Icon(icon, color: AppColors.success, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBottomInfoCard(
    String label,
    RxDouble valueObx,
    String unit,
    IconData icon, {
    bool isCurrency = false,
  }) {
    return _buildGlassyCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  isCurrency
                      ? "$unit${valueObx.value.toStringAsFixed(2)}"
                      : "${valueObx.value.toStringAsFixed(2)} $unit",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedBatteryBars extends StatefulWidget {
  final ChargingController controller;
  const _AnimatedBatteryBars({required this.controller});

  @override
  State<_AnimatedBatteryBars> createState() => _AnimatedBatteryBarsState();
}

class _AnimatedBatteryBarsState extends State<_AnimatedBatteryBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<int> _chargingAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Slower animation
    );

    _chargingAnimation = IntTween(begin: 0, end: 10).animate(_animController);

    // Start animation if charging
    if (widget.controller.status.value == "Charging") {
      _animController.repeat();
    }

    // Listen to status changes to start/stop animation
    ever(widget.controller.status, (status) {
      if (status == "Charging") {
        _animController.repeat();
      } else {
        _animController.stop();
        _animController
            .reset(); // Show full static when not charging (or just current SOC)
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getBarColor(int index) {
    if (index < 2) return AppColors.error; // Red
    if (index < 5) return Colors.orange;
    if (index < 8) return Colors.yellow;
    return AppColors.success; // Green
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) {
            return Expanded(
              child: Obx(() {
                final soc = widget.controller.soc.value;
                
                // If charging, we animate
                // If soc == 0, we assume indeterminate/starting, so we fill all bars 0-10
                // If soc > 0, we fill up to SOC
                bool isActive;
                if (widget.controller.status.value == "Charging") {
                  final animValue = _chargingAnimation.value;

                  if (soc <= 0) {
                    // Indeterminate animation: fill up 0-10
                    isActive = index <= animValue;
                  } else {
                    // Realistic animation: fill up to SOC
                    final maxActiveIndex = (soc / 10).ceil();
                    isActive = index < maxActiveIndex && index <= animValue;
                  }
                } else {
                  // Not charging, static display
                  final maxActiveIndex = (soc / 10).ceil();
                  isActive = index < maxActiveIndex;
                }

                final color = _getBarColor(index);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 50, // Significantly increased height again
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      6,
                    ), // Rounded pill shape
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }
}

class _ThreeBlinkingDots extends StatefulWidget {
  @override
  State<_ThreeBlinkingDots> createState() => _ThreeBlinkingDotsState();
}

class _ThreeBlinkingDotsState extends State<_ThreeBlinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final opacity = _getOpacity(index);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(opacity),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(opacity * 0.5),
                    blurRadius: 4,
                  )
                ],
              ),
            );
          }),
        );
      },
    );
  }

  double _getOpacity(int index) {
    final value = _controller.value * 3; // 0 to 3
    // Sequential blinking: 0, 1, 2
    if (value >= index && value < index + 1) {
      return 1.0;
    }
    return 0.2;
  }
}
