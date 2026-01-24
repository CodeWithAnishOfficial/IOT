class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String modelName;
  final int year;
  final String? vin;
  final String? plateNo;
  final String connectorType;
  final bool isDefault;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.modelName,
    required this.year,
    this.vin,
    this.plateNo,
    required this.connectorType,
    required this.isDefault,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      make: json['make'] ?? '',
      modelName: json['modelName'] ?? '',
      year: json['year'] ?? 0,
      vin: json['vin'],
      plateNo: json['plate_no'],
      connectorType: json['connector_type'] ?? 'Type2',
      isDefault: json['is_default'] ?? false,
    );
  }
}
