class SupportTicket {
  final String ticketId;
  final String subject;
  final String description;
  final String status;
  final String category;
  final List<TicketResponse> responses;
  final DateTime createdAt;

  SupportTicket({
    required this.ticketId,
    required this.subject,
    required this.description,
    required this.status,
    required this.category,
    required this.responses,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketId: json['ticket_id'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      category: json['category'],
      responses: (json['responses'] as List?)
              ?.map((e) => TicketResponse.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TicketResponse {
  final String sender;
  final String message;
  final DateTime timestamp;

  TicketResponse({
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      sender: json['sender'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
