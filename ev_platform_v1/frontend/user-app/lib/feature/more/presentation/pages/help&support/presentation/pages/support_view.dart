import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';
import 'create_ticket_sheet.dart';
import 'ticket_chat_view.dart';
import '../../domain/models/support_ticket.dart';

class SupportView extends GetView<SupportController> {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            const CreateTicketSheet(),
            isScrollControlled: true,
          );
        },
        label: const Text('New Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.black, // Primary usually implies black text on neon/lime
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent, size: 80, color: Colors.grey[800]),
                const SizedBox(height: 16),
                const Text(
                  'No support tickets yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Need help? Create a new ticket below.',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTickets(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
            itemCount: controller.tickets.length,
            itemBuilder: (context, index) {
              final ticket = controller.tickets[index];
              return _buildTicketCard(ticket, cardColor);
            },
          ),
        );
      }),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, Color cardColor) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.to(() => TicketChatView(ticketId: ticket.ticketId));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(ticket.status),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    ticket.category,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.responses.length} msg',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;
    
    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.greenAccent[400]!;
        bgColor = Colors.green.withOpacity(0.1);
        break;
      case 'closed':
        color = Colors.grey[400]!;
        bgColor = Colors.grey.withOpacity(0.1);
        break;
      default:
        color = Colors.orangeAccent[400]!;
        bgColor = Colors.orange.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
