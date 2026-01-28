import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_app/app/modules/support/domain/models/support_ticket.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:user_app/core/theme/app_colors.dart';
import '../controllers/support_controller.dart';
import 'create_ticket_sheet.dart';
import 'ticket_chat_view.dart';

class SupportView extends GetView<SupportController> {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(const CreateTicketSheet(), isScrollControlled: true);
        },
        label: Text(
          'New Ticket',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
           return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 5,
            itemBuilder: (context, index) => _buildShimmerItem(context),
          );
        }

        if (controller.tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent, size: 80, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No support tickets yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Need help? Create a new ticket below.',
                  style: GoogleFonts.poppins(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTickets(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: controller.tickets.length,
            itemBuilder: (context, index) {
              final ticket = controller.tickets[index];
              return _buildTicketCard(context, ticket);
            },
          ),
        );
      }),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOpen = ticket.status.toLowerCase() == 'open';
    
    return GestureDetector(
      onTap: () {
        Get.to(() => TicketChatView(ticketId: ticket.ticketId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOpen 
                    ? AppColors.success.withOpacity(0.1) 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(ticket.createdAt).toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isOpen ? AppColors.success : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(ticket.createdAt),
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 12, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${ticket.category} • #${ticket.ticketId}",
                          style: GoogleFonts.poppins(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
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
            
            const SizedBox(width: 8),

            // Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ticket.responses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 12, color: theme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          "${ticket.responses.length}",
                          style: GoogleFonts.poppins(
                            color: theme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildStatusChip(context, ticket.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'open':
        color = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.1);
        break;
      case 'closed':
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        break;
      default:
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ShimmerBox(
              width: 50,
              height: 60,
              borderRadius: 16,
              baseColor: isDark ? Colors.white10 : Colors.grey[200],
              highlightColor: isDark ? Colors.white24 : Colors.grey[100],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: 120,
                    height: 16,
                    baseColor: isDark ? Colors.white10 : Colors.grey[200],
                    highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    baseColor: isDark ? Colors.white10 : Colors.grey[200],
                    highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ShimmerBox(width: 50, height: 20, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}
