class WalletTransaction {
  final String transactionId;
  final double amount;
  final String type;
  final String source;
  final String status;
  final DateTime createdAt;

  WalletTransaction({
    required this.transactionId,
    required this.amount,
    required this.type,
    required this.source,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      transactionId: json['transaction_id'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'],
      source: json['source'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
