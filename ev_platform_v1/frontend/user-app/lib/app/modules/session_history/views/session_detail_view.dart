import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';
import 'package:user_app/app/modules/session_history/domain/models/charging_session.dart';
import 'package:user_app/core/theme/app_colors.dart';

class SessionDetailView extends StatelessWidget {
  final ChargingSession session;
  
  const SessionDetailView({
    super.key, 
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    // We can access the controller if needed, or pass it in. 
    // Since it's a detail view likely opened from SessionView, the controller might be active.
    // Ideally we prefer to use Get.find if it's already registered.
    final SessionHistoryController controller = Get.find<SessionHistoryController>();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final duration = session.stopTime != null 
        ? session.stopTime!.difference(session.startTime)
        : DateTime.now().difference(session.startTime);
    final durationStr = "${duration.inMinutes} min";

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
          "Session Details",
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getStatusColor(session.status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(session.status), 
                        color: _getStatusColor(session.status), 
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.status.capitalizeFirst ?? session.status,
                          style: GoogleFonts.poppins(
                            color: _getStatusColor(session.status),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(session.startTime),
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Station ID Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Text(
                    "ID: ${session.chargerId}",
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Connector Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.electrical_services, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CCS 2",
                          style: GoogleFonts.poppins(
                            color: theme.textTheme.titleMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Connector ID: ${session.connectorId}",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Billing Summary Card (White box in design)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Billing Summary",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSummaryRow(theme, "Total Energy", "${session.totalEnergy.toStringAsFixed(2)} kWh"),
                  const SizedBox(height: 16),
                  _buildSummaryRow(theme, "Duration", durationStr),
                  const SizedBox(height: 16),
                  _buildSummaryRow(theme, "Start Time", DateFormat('HH:mm').format(session.startTime)),
                   const SizedBox(height: 16),
                  _buildSummaryRow(theme, "End Time", session.stopTime != null ? DateFormat('HH:mm').format(session.stopTime!) : "-"),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Cost",
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${session.cost.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: AppColors.success,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  Text(
                    "* Rates include all applicable taxes and fees.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Method
            Text(
              "Paid using",
              style: GoogleFonts.poppins(
                color: theme.textTheme.titleMedium?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "App Wallet",
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Note
            Text(
              "Note:",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This session has been completed and billed. If you have any issues with this transaction, please contact support.",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Buttons
             Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => controller.requestInvoice(session.sessionId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: AppColors.success.withOpacity(0.4),
                      ),
                      child: Text(
                        "Download Invoice",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'finished':
        return AppColors.success;
      case 'charging':
      case 'active':
        return Colors.blue;
      case 'failed':
      case 'faulted':
        return Colors.red;
      case 'stopped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
     switch (status.toLowerCase()) {
      case 'completed':
      case 'finished':
        return Icons.check_circle;
      case 'charging':
      case 'active':
        return Icons.bolt;
      case 'failed':
      case 'faulted':
        return Icons.error;
      case 'stopped':
        return Icons.stop_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
