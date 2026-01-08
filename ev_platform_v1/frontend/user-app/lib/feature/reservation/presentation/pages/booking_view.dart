import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/home/domain/models/charging_station.dart';
import 'package:user_app/feature/reservation/presentation/controllers/reservation_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

class BookingView extends StatefulWidget {
  final ChargingStation station;
  const BookingView({super.key, required this.station});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isAllDay = false;
  int? selectedConnectorId;

  @override
  void initState() {
    super.initState();
    // Auto-select first connector if available
    if (widget.station.connectors.isNotEmpty) {
      selectedConnectorId = widget.station.connectors.first.connectorId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Create event",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Info
            Text(
              widget.station.name ?? "Unknown Station",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.station.location?.address ?? "Unknown Location",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Connector Selection
            if (widget.station.connectors.isNotEmpty) ...[
               Text(
                 "Select Connector",
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w500,
                 ),
               ),
               const SizedBox(height: 12),
               Wrap(
                 spacing: 12,
                 runSpacing: 12,
                 children: widget.station.connectors.map((c) {
                    final isSelected = selectedConnectorId == c.connectorId;
                    return ChoiceChip(
                      label: Text(
                        "${c.type ?? 'Unknown'} (ID: ${c.connectorId})",
                        style: TextStyle(
                           color: isSelected ? Colors.black : Colors.white,
                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedConnectorId = c.connectorId;
                          });
                        }
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.white10,
                        ),
                      ),
                    );
                 }).toList(),
               ),
               const SizedBox(height: 32),
            ],

            // Start Date/Time Display
            Text(
              "Starts",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      "${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedDate.year}",
                      style: GoogleFonts.poppins(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        selectedTime.format(context),
                        style: GoogleFonts.poppins(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Embedded Calendar
            Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.black,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),

            const SizedBox(height: 40),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() {
                 // Try to find controller, if not found, create a temporary one (unlikely if flow is correct)
                 final controller = Get.isRegistered<ReservationController>() 
                    ? Get.find<ReservationController>() 
                    : Get.put(ReservationController());

                 if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                 }
                 
                 return ElevatedButton(
                  onPressed: () {
                    if (selectedConnectorId == null) {
                       Get.snackbar("Error", "Please select a connector", backgroundColor: Colors.red, colorText: Colors.white);
                       return;
                    }
                    
                    controller.createReservation(
                        widget.station.chargerId, 
                        selectedConnectorId!, 
                        15 // Default 15 mins expiry
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Confirm Reservation",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
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
