import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';
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
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.dividerColor.withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Ticket Header Info
          Obx(() {
            final ticket = controller.tickets.firstWhereOrNull(
              (t) => t.ticketId == widget.ticketId,
            );
            
            if (controller.isLoading.value) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: cardColor,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 20, width: 200),
                    SizedBox(height: 8),
                    ShimmerBox(height: 16, width: 100),
                  ],
                ),
              );
            }
            
            if (ticket == null) return const SizedBox();

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(context, ticket.status),
                      const SizedBox(width: 12),
                      Text(
                        '#${ticket.ticketId}',
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
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
              if (controller.isLoading.value) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final isRight = index % 2 == 0;
                    return Align(
                      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ShimmerBox(
                          height: 60,
                          width: Get.width * 0.6,
                          borderRadius: 16,
                        ),
                      ),
                    );
                  },
                );
              }

              final ticket = controller.tickets.firstWhereOrNull(
                (t) => t.ticketId == widget.ticketId,
              );
              
              if (ticket == null) {
                return Center(
                  child: Text(
                    'Ticket not found',
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                );
              }

              final messages = ticket.responses;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.sender == 'user';
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.primaryColor
                            : (isDark ? const Color(0xFF333333) : Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isMe
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                        boxShadow: isMe ? null : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.message,
                            style: GoogleFonts.poppins(
                              color: isMe ? Colors.white : textColor,
                              fontSize: 14,
                              fontWeight: isMe
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(msg.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : textColor.withOpacity(0.5),
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
            padding: const EdgeInsets.all(20),
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
                    style: GoogleFonts.poppins(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
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

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
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

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }
}
