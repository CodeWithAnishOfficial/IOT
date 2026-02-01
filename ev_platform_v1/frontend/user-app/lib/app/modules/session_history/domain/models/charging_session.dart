class ChargingSession {
  final String sessionId;
  final int? transactionId;
  final String chargerId;
  final String stationName;
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
    this.stationName = 'Unknown Station',
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
    // Helper to parse dates
    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now(); // Fallback
      if (dateVal is String) return DateTime.parse(dateVal);
      if (dateVal is Map && dateVal['\$date'] != null) {
        return DateTime.parse(dateVal['\$date']);
      }
      return DateTime.now();
    }
    
    DateTime? parseDateNullable(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is String) return DateTime.parse(dateVal);
      if (dateVal is Map && dateVal['\$date'] != null) {
        return DateTime.parse(dateVal['\$date']);
      }
      return null;
    }

    return ChargingSession(
      sessionId: json['session_id'].toString(),
      transactionId: json['transaction_id'],
      chargerId: json['charger_id'] ?? 'Unknown',
      stationName: json['station_name'] ?? 'Unknown Station',
      connectorId: json['connector_id'] ?? 1,
      userId: json['user_id'].toString(),
      startTime: parseDate(json['start_time']),
      stopTime: parseDateNullable(json['stop_time']),
      meterStart: (json['start_meter_value'] as num?)?.toDouble() ?? 0.0,
      meterStop: (json['meter_stop'] as num?)?.toDouble(),
      totalEnergy: (json['unit_consumed'] as num?)?.toDouble() ?? 0.0,
      cost: (json['consumed_amount'] as num?)?.toDouble() ?? 0.0,
      // Use charger_status for the string status (stopping, completed, etc.)
      status: json['charger_status'] ?? 'Unknown',
    );
  }
}
