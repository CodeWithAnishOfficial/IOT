import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/charging/controllers/charging_controller.dart';

class BillSummaryView extends StatelessWidget {
  final ChargingController controller;

  const BillSummaryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Charging Summary',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Success Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
                border: Border.all(color: theme.primaryColor, width: 2),
              ),
              child: Icon(
                Icons.check_rounded,
                color: theme.primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              '₹${controller.currentCost.value.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.displayMedium?.color,
              ),
            ),
            Text(
              'Total Cost',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            
            const SizedBox(height: 48),

            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() { 
                final data = controller.finalSessionData;
                return Column(
                  children: [
                    _buildRow(context, 'Energy Delivered', '${controller.energyDelivered.value.toStringAsFixed(2)} kWh'),
                    const Divider(height: 24),
                    
                    if (data['start_time'] != null)
                      _buildRow(context, 'Start Time', _formatTime(data['start_time'])),
                    if (data['stop_time'] != null) ...[
                      const SizedBox(height: 12),
                      _buildRow(context, 'Stop Time', _formatTime(data['stop_time'])),
                    ],
                    const Divider(height: 24),

                    _buildRow(context, 'Duration', controller.durationString.value),
                    const Divider(height: 24),
                    
                    // Fee Breakdown
                    if (_hasValue(data['unit_price']))
                       _buildRow(context, 'Rate', '₹${data['unit_price']}/kWh'),
                       
                    if (_hasValue(data['parking_fee'])) ...[
                       const SizedBox(height: 12),
                       _buildRow(context, 'Parking Fee', '₹${data['parking_fee']}'),
                    ],
                    if (_hasValue(data['service_fee'])) ...[
                       const SizedBox(height: 12),
                       _buildRow(context, 'Service Fee', '₹${data['service_fee']}'),
                    ],
                    if (_hasValue(data['gst_amount'])) ...[
                       const SizedBox(height: 12),
                       _buildRow(context, 'GST', '₹${data['gst_amount']}'),
                    ],
                     
                    const Divider(height: 24),
                    _buildRow(context, 'Station ID', 'CH001'), 
                  ],
                );
              }),
            ),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.downloadInvoice,
                    icon: Icon(Icons.download, color: theme.iconTheme.color),
                    label: Text(
                      'Invoice',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.offAllNamed('/home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleMedium?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '--:--';
    try {
        // Handle MongoDB $date object or string
        String iso = dateStr.toString();
        if (dateStr is Map && dateStr['\$date'] != null) {
            iso = dateStr['\$date'];
        }
        final dt = DateTime.parse(iso).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
    } catch (e) {
        return '--:--';
    }
  }
  
  bool _hasValue(dynamic val) {
      if (val == null) return false;
      final v = double.tryParse(val.toString());
      return v != null && v > 0;
  }
}
