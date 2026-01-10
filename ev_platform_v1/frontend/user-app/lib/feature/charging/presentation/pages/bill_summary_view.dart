import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/feature/charging/presentation/controllers/charging_controller.dart';

class BillSummaryView extends StatelessWidget {
  final ChargingController controller;

  const BillSummaryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Charging Summary',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                color: const Color(0xFFCCFF00).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFCCFF00), width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFFCCFF00),
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              '₹${controller.currentCost.value.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Total Cost',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 48),

            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Obx(() { 
                final data = controller.finalSessionData;
                return Column(
                  children: [
                    _buildRow('Energy Delivered', '${controller.energyDelivered.value.toStringAsFixed(2)} kWh'),
                    const Divider(color: Colors.white12, height: 24),
                    
                    if (data['start_time'] != null)
                      _buildRow('Start Time', _formatTime(data['start_time'])),
                    if (data['stop_time'] != null) ...[
                      const SizedBox(height: 12),
                      _buildRow('Stop Time', _formatTime(data['stop_time'])),
                    ],
                    const Divider(color: Colors.white12, height: 24),

                    _buildRow('Duration', controller.durationString.value),
                    const Divider(color: Colors.white12, height: 24),
                    
                    // Fee Breakdown
                    if (_hasValue(data['unit_price']))
                       _buildRow('Rate', '₹${data['unit_price']}/kWh'),
                       
                    if (_hasValue(data['parking_fee'])) ...[
                       const SizedBox(height: 12),
                       _buildRow('Parking Fee', '₹${data['parking_fee']}'),
                    ],
                    if (_hasValue(data['service_fee'])) ...[
                       const SizedBox(height: 12),
                       _buildRow('Service Fee', '₹${data['service_fee']}'),
                    ],
                    if (_hasValue(data['gst_amount'])) ...[
                       const SizedBox(height: 12),
                       _buildRow('GST', '₹${data['gst_amount']}'),
                    ],
                     
                    const Divider(color: Colors.white12, height: 24),
                    _buildRow('Station ID', 'CH001'), 
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
                    icon: const Icon(Icons.download),
                    label: const Text('Invoice'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
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
                      backgroundColor: const Color(0xFFCCFF00),
                      foregroundColor: Colors.black,
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

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
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
