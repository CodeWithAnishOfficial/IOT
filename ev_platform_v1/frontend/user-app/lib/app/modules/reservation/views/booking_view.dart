import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/reservation/controllers/reservation_controller.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

class BookingView extends StatefulWidget {
  final Charger station;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Create event",
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleLarge?.color,
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
                color: theme.textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.station.location?.address ?? "Unknown Location",
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Connector Selection
            if (widget.station.connectors.isNotEmpty) ...[
               Text(
                 "Select Connector",
                 style: GoogleFonts.poppins(
                   color: theme.textTheme.titleMedium?.color,
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
                           color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
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
                      selectedColor: theme.primaryColor,
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? theme.primaryColor : theme.dividerColor,
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
                color: theme.textTheme.titleMedium?.color,
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
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      "${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedDate.year}",
                      style: GoogleFonts.poppins(color: theme.textTheme.bodyMedium?.color),
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
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        selectedTime.format(context),
                        style: GoogleFonts.poppins(color: theme.textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Embedded Calendar
            CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
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
                    return Center(child: CircularProgressIndicator(color: theme.primaryColor));
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
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Confirm Reservation",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
