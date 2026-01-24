class User {
  final int userId;
  final String? username;
  final String emailId;
  final String? phoneNo;
  final int roleId;
  final double walletBal;
  final String? rfidTag;
  final bool status;

  User({
    required this.userId,
    this.username,
    required this.emailId,
    this.phoneNo,
    required this.roleId,
    required this.walletBal,
    this.rfidTag,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      emailId: json['email_id'],
      phoneNo: json['phone_no'],
      roleId: json['role_id'],
      walletBal: (json['wallet_bal'] as num?)?.toDouble() ?? 0.0,
      rfidTag: json['rfid_tag'],
      status: json['status'] ?? true,
    );
  }
}
