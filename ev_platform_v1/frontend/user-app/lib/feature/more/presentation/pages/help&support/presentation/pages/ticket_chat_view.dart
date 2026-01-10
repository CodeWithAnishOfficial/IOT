import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';
import '../../domain/models/support_ticket.dart';

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
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);
    const inputFillColor = Color(0xFF2C2C2C);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Ticket Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Ticket Header Info
          Obx(() {
            final ticket = controller.tickets.firstWhereOrNull((t) => t.ticketId == widget.ticketId);
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(ticket.status),
                      const SizedBox(width: 8),
                      Text(
                        '#${ticket.ticketId}',
                        style: const TextStyle(color: Colors.white70),
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
              final ticket = controller.tickets.firstWhereOrNull((t) => t.ticketId == widget.ticketId);
              if (ticket == null) {
                return const Center(child: Text('Ticket not found', style: TextStyle(color: Colors.white)));
              }
              
              final messages = ticket.responses; 

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.sender == 'user';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Get.theme.primaryColor : const Color(0xFF333333),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: isMe ? Colors.black87 : Colors.white,
                              fontWeight: isMe ? FontWeight.w600 : FontWeight.normal
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(msg.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.black54 : Colors.white60,
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
                  color: Colors.black.withOpacity(0.2),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black87, size: 20),
                    onPressed: () {
                      if (messageController.text.trim().isNotEmpty) {
                        controller.replyToTicket(widget.ticketId, messageController.text);
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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }
}
