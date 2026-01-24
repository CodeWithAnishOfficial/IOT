import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/support/domain/models/support_ticket.dart';
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
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
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
        label: const Text(
          'New Ticket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
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
                Icon(Icons.support_agent, size: 80, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No support tickets yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Need help? Create a new ticket below.',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTickets(),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 80,
              top: 16,
              left: 16,
              right: 16,
            ),
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
    
    return Card(
      elevation: 2,
      color: theme.cardColor,
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
                  _buildStatusChip(context, ticket.status),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: theme.iconTheme.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.category,
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.responses.length} msg',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: theme.disabledColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
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
