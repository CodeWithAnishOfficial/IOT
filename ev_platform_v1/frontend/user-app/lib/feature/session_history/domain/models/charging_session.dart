class ChargingSession {
  final String sessionId;
  final int? transactionId;
  final String chargerId;
  final int connectorId;
  final String userId;
  final DateTime startTime;
  final DateTime? stopTime;
  final double meterStart;
  final double? meterStop;
  final double totalEnergy;
  final double cost;
  final String status;

  ChargingSession({
    required this.sessionId,
    this.transactionId,
    required this.chargerId,
    required this.connectorId,
    required this.userId,
    required this.startTime,
    this.stopTime,
    required this.meterStart,
    this.meterStop,
    required this.totalEnergy,
    required this.cost,
    required this.status,
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      sessionId: json['session_id'],
      transactionId: json['transaction_id'],
      chargerId: json['charger_id'],
      connectorId: json['connector_id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      stopTime: json['stop_time'] != null ? DateTime.parse(json['stop_time']) : null,
      meterStart: (json['meter_start'] as num?)?.toDouble() ?? 0.0,
      meterStop: (json['meter_stop'] as num?)?.toDouble(),
      totalEnergy: (json['total_energy'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      status: json['status'],
    );
  }
}
