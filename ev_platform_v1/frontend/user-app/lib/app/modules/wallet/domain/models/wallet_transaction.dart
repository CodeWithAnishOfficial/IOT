class PaymentTransaction {
  final int paymentId;
  final double amount;
  final String transactionId;
  final String method;
  final bool status;
  final DateTime date;

  PaymentTransaction({
    required this.paymentId,
    required this.amount,
    required this.transactionId,
    required this.method,
    required this.status,
    required this.date,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      paymentId: json['payment_id'] ?? 0,
      amount: (json['recharge_amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transaction_id'] ?? '',
      method: json['payment_method'] ?? 'Unknown',
      status: json['status'] ?? false,
      date: json['recharged_date'] != null 
          ? DateTime.parse(json['recharged_date']) 
          : DateTime.now(),
    );
  }
}
