import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class TicketChatView extends StatefulWidget {
  final String ticketId;

  const TicketChatView({super.key, required this.ticketId});

  @override
  State<TicketChatView> createState() => _TicketChatViewState();
}

class _TicketChatViewState extends State<TicketChatView> {
  final SupportController controller = Get.find<SupportController>();
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200];
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: theme.textTheme.titleLarge?.copyWith(color: textColor),
        ),
        centerTitle: true,
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // Ticket Header Info
          Obx(() {
            final ticket = controller.tickets.firstWhereOrNull(
              (t) => t.ticketId == widget.ticketId,
            );
            if (ticket == null) return const SizedBox();

            return Container(
              padding: const EdgeInsets.all(16),
              color: cardColor,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(ticket.status),
                      const SizedBox(width: 8),
                      Text(
                        '#${ticket.ticketId}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Chat Messages
          Expanded(
            child: Obx(() {
              final ticket = controller.tickets.firstWhereOrNull(
                (t) => t.ticketId == widget.ticketId,
              );
              if (ticket == null) {
                return Center(
                  child: Text(
                    'Ticket not found',
                    style: TextStyle(color: textColor),
                  ),
                );
              }

              final messages = ticket.responses;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.sender == 'user';
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.primaryColor
                            : (isDark ? const Color(0xFF333333) : Colors.grey[300]),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMe
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: isMe
                              ? Radius.zero
                              : const Radius.circular(12),
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: isMe ? theme.colorScheme.onPrimary : textColor,
                              fontWeight: isMe
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(msg.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      if (messageController.text.trim().isNotEmpty) {
                        controller.replyToTicket(
                          widget.ticketId,
                          messageController.text,
                        );
                        messageController.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }
}
