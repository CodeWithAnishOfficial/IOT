import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBottomBarVisible.value) _isBottomBarVisible.value = false;
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isBottomBarVisible.value) _isBottomBarVisible.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Main Content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacing for Fixed Header
                    const SizedBox(height: 80),
                    
                    // Top Stats Row
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTopStatItem(context, Icons.electrical_services, widget.controller.connectorTypeLabel.value, "Connector"),
                          _buildTopStatItem(context, Icons.flash_on, widget.controller.maxPowerLabel.value, "Max Speed"),
                          _buildTopStatItem(context, Icons.ev_station, widget.controller.stationIdLabel.value, "Station"),
                        ],
                      )),
                    ),

                    const SizedBox(height: 40),

                    // Hero Car Image
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
                            child: _buildInfoCard(
                              context,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.battery_charging_full, color: AppColors.success, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Battery",
                                        style: GoogleFonts.poppins(
                                          color: theme.textTheme.bodyMedium?.color,
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
                                        color: theme.textTheme.titleLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                  child: _buildInfoCard(
                                    context,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.timelapse, size: 16, color: theme.disabledColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Status",
                                              style: GoogleFonts.poppins(
                                                color: theme.disabledColor,
                                                fontSize: 12,
                                              ),
                                            ),
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
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (widget.controller.status.value == "Charging")
                                          _ThreeBlinkingDots(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Bottom Right: Energy
                                Expanded(
                                  child: _buildInfoCard(
                                    context,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.bolt, size: 16, color: theme.disabledColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Energy",
                                              style: GoogleFonts.poppins(
                                                color: theme.disabledColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Obx(() => Text(
                                            "${widget.controller.energyDelivered.value.toStringAsFixed(1)} kWh",
                                            style: GoogleFonts.orbitron(
                                              color: theme.textTheme.titleLarge?.color,
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
                            context,
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
                            context,
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

          // 3. Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                 onPressed: () => Get.back(),
                 icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color),
              ),
              title: Text(
                "Active Session",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
          ),

          // 4. Swipe Button
          Obx(() => AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _isBottomBarVisible.value ? 30 : -100,
              left: 20,
              right: 20,
              child: SwipeButton(
                onSwipe: widget.controller.stopCharging,
                text: "Swipe to Stop Charging",
                backgroundColor: AppColors.error,
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

  Widget _buildInfoCard(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTopStatItem(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.success, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: theme.textTheme.bodySmall?.color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBottomInfoCard(
    BuildContext context,
    String label,
    RxDouble valueObx,
    String unit,
    IconData icon, {
    bool isCurrency = false,
  }) {
    final theme = Theme.of(context);
    return _buildInfoCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(color: theme.textTheme.bodySmall?.color, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                  isCurrency
                      ? "$unit${valueObx.value.toStringAsFixed(2)}"
                      : "${valueObx.value.toStringAsFixed(2)} $unit",
                  style: GoogleFonts.orbitron(
                    color: theme.textTheme.titleLarge?.color,
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

class _AnimatedBatteryBarsState extends State<_AnimatedBatteryBars> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<int> _chargingAnimation;
  Worker? _statusWorker;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _chargingAnimation = IntTween(begin: 0, end: 10).animate(_animController);

    if (widget.controller.status.value == "Charging") {
      _animController.repeat();
    }

    _statusWorker = ever(widget.controller.status, (status) {
      if (status == "Charging") {
        _animController.repeat();
      } else {
        _animController.stop();
        _animController.reset();
      }
    });
  }

  @override
  void dispose() {
    _statusWorker?.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color _getBarColor(int index) {
    if (index < 2) return AppColors.error;
    if (index < 5) return Colors.orange;
    if (index < 8) return Colors.yellow[700]!; // Darker yellow for visibility on white
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) {
            return Expanded(
              child: Obx(() {
                final soc = widget.controller.soc.value;
                bool isActive;
                if (widget.controller.status.value == "Charging") {
                  final animValue = _chargingAnimation.value;
                  if (soc <= 0) {
                    isActive = index <= animValue;
                  } else {
                    final maxActiveIndex = (soc / 10).ceil();
                    isActive = index < maxActiveIndex && index <= animValue;
                  }
                } else {
                  final maxActiveIndex = (soc / 10).ceil();
                  isActive = index < maxActiveIndex;
                }

                final color = _getBarColor(index);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive ? color : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(6),
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

class _ThreeBlinkingDotsState extends State<_ThreeBlinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
            final opacity = (1.0 - ((_controller.value - (index * 0.2)).abs())).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
