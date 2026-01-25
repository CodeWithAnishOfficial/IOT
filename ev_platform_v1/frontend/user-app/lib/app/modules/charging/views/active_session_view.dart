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

  const ChargingView({
    super.key,
    required this.controller,
  });

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
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBottomBarVisible.value) _isBottomBarVisible.value = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
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
                  color: AppColors.success.withOpacity(0.2), // Green glow for charging
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
                padding: const EdgeInsets.fromLTRB(20.0, 80.0, 20.0, 100.0), // Added padding for fixed header and bottom bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header removed from here
                    
                    // Top Stats Row (Connector, Power, ID)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTopStatItem(Icons.electrical_services, "CCS 2", "Connector"),
                        _buildTopStatItem(Icons.flash_on, "120 kW", "Max Speed"),
                        _buildTopStatItem(Icons.ev_station, "ID: 402", "Station"),
                      ],
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
                                      Icon(Icons.battery_charging_full, color: AppColors.success, size: 20),
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
                                  Obx(() => Text(
                                    "${widget.controller.soc.value.toInt()}%",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 48,
                                      shadows: [
                                        BoxShadow(
                                          color: AppColors.success.withOpacity(0.5),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(height: 10),
                                  
                                  // Visual Battery Bars (Animated)
                                  _AnimatedBatteryBars(controller: widget.controller),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                         Row(
                                           children: [
                                              Icon(Icons.timelapse, size: 16, color: Colors.white60),
                                              const SizedBox(width: 6),
                                              Text("Status", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                                           ],
                                         ),
                                         const SizedBox(height: 8),
                                         Obx(() => Text(
                                           widget.controller.status.value,
                                           style: GoogleFonts.poppins(
                                             color: AppColors.success,
                                             fontWeight: FontWeight.bold,
                                             fontSize: 16,
                                           ),
                                           maxLines: 1,
                                           overflow: TextOverflow.ellipsis,
                                         )),
                                         const SizedBox(height: 4),
                                         if(widget.controller.status.value == "Charging")
                                          _BlinkingDot()
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                         Row(
                                           children: [
                                              Icon(Icons.bolt, size: 16, color: Colors.white60),
                                              const SizedBox(width: 6),
                                              Text("Energy", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                                           ],
                                         ),
                                         const SizedBox(height: 8),
                                         Obx(() => Text(
                                           "${widget.controller.energyDelivered.value.toStringAsFixed(1)} kWh",
                                           style: GoogleFonts.orbitron(
                                             color: Colors.white,
                                             fontWeight: FontWeight.bold,
                                             fontSize: 16, 
                                           ),
                                         )),
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
                             isCurrency: true
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: _buildBottomInfoCard(
                             "Current Power", 
                             widget.controller.currentPower, 
                             "kW", 
                             Icons.flash_on
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
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating Swipe to Stop (Bottom)
          Obx(() => AnimatedPositioned(
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
          )),
        ],
      ),
    );
  }

  Widget _buildGlassyCard({required Widget child, EdgeInsetsGeometry? padding}) {
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
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              )
            ]
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
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomInfoCard(String label, RxDouble valueObx, String unit, IconData icon, {bool isCurrency = false}) {
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
               Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
               const SizedBox(height: 4),
               Obx(() => Text(
                 isCurrency 
                   ? "$unit${valueObx.value.toStringAsFixed(2)}"
                   : "${valueObx.value.toStringAsFixed(2)} $unit",
                 style: GoogleFonts.orbitron(
                   color: Colors.white,
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                 ),
               )),
             ],
           )
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

class _AnimatedBatteryBarsState extends State<_AnimatedBatteryBars> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(10, (index) {
        return Expanded(
          child: Obx(() {
            final soc = widget.controller.soc.value;
            final isActive = index < (soc / 10);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.success 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive 
                  ? [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 4)]
                  : null
              ),
            );
          }),
        );
      }),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.success, blurRadius: 6)
          ]
        ),
      ),
    );
  }
}
