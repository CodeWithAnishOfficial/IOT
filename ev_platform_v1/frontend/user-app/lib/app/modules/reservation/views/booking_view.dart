import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/reservation/controllers/reservation_controller.dart';
import 'package:user_app/core/theme/app_colors.dart';

class BookingView extends StatefulWidget {
  final Charger station;
  final int? preSelectedConnectorId; // Add this parameter

  const BookingView({super.key, required this.station, this.preSelectedConnectorId});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedConnectorId;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedConnectorId != null) {
      selectedConnectorId = widget.preSelectedConnectorId;
    } else if (widget.station.connectors.isNotEmpty) {
      selectedConnectorId = widget.station.connectors.first.connectorId;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme values
    final theme = Theme.of(context);
    final backgroundColor = const Color(0xFFF5F5F5); // Light grey background
    final cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Header Background (Dark)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Create Event",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.station.name ?? "EV Station",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.station.location?.address ?? "Unknown Location",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connector Section
                  Text(
                    "Select Connector",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140, // Increased height
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.station.connectors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16), // Increased spacing
                      itemBuilder: (context, index) {
                        final connector = widget.station.connectors[index];
                        final isSelected = selectedConnectorId == connector.connectorId;
                        
                        return GestureDetector(
                          onTap: () {
                            if (connector.connectorId != null) {
                              setState(() {
                                selectedConnectorId = connector.connectorId;
                              });
                            }
                          },
                          child: AnimatedContainer( // Animated for smooth transition
                            duration: const Duration(milliseconds: 200),
                            width: 120, // Increased width
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : cardColor,
                              borderRadius: BorderRadius.circular(20), // More rounded
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey[200]!,
                                width: 2, // Thicker border
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ] : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ev_station,
                                  color: isSelected ? Colors.white : Colors.black54,
                                  size: 32, // Larger icon
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  connector.type ?? "Type 2",
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 14, // Larger text
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${connector.maxPowerKw} kW",
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Date & Time Section
                  Text(
                    "Schedule",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Date Picker Row
                        InkWell(
                          onTap: () async {
                             final picked = await showDatePicker(
                               context: context,
                               initialDate: selectedDate,
                               firstDate: DateTime.now(),
                               lastDate: DateTime.now().add(const Duration(days: 365)),
                               builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                               },
                             );
                             if (picked != null) {
                               setState(() => selectedDate = picked);
                             }
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12), // Increased padding
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.calendar_today, color: Colors.black87),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Date",
                                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    "${selectedDate.day} ${_getMonth(selectedDate.month)}, ${selectedDate.year}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24), // Replaced Divider with Spacing
                        
                        // Time Picker Row
                        InkWell(
                          onTap: _pickTime,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12), // Increased padding
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.access_time, color: Colors.black87),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Start Time",
                                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    selectedTime.format(context),
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          
          // 3. Bottom Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Obx(() {
               final controller = Get.isRegistered<ReservationController>() 
                  ? Get.find<ReservationController>() 
                  : Get.put(ReservationController());

               return SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   onPressed: controller.isLoading.value ? null : () {
                      if (selectedConnectorId == null) {
                         Get.snackbar("Error", "Please select a connector", backgroundColor: Colors.orange, colorText: Colors.white);
                         return;
                      }
                      
                      controller.createReservation(
                          widget.station.chargerId, 
                          selectedConnectorId!, 
                          15 // Default 15 mins expiry
                      );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30),
                     ),
                     elevation: 5,
                     shadowColor: Colors.black.withOpacity(0.3),
                   ),
                   child: controller.isLoading.value 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                         "Confirm Reservation",
                         style: GoogleFonts.poppins(
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                           color: Colors.white,
                         ),
                       ),
                 ),
               );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  String _getMonth(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
}
