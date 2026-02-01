class Charger {
  final String chargerId;
  final String? name;
  final Location? location;
  final String status;
  final double maxPowerKw;
  final String? tariffId;
  final String? siteId;
  final String? vendor;
  final String? modelName;
  final double? distance;
  final double? costPerUnit;
  final List<Connector> connectors;
  final List<String> images;
  final List<String> facilities;

  Charger({
    required this.chargerId,
    this.name,
    this.location,
    required this.status,
    required this.maxPowerKw,
    this.tariffId,
    this.siteId,
    this.vendor,
    this.modelName,
    this.distance,
    this.costPerUnit,
    required this.connectors,
    this.images = const [],
    this.facilities = const [],
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    var connectors = (json['connectors'] as List?)
              ?.map((e) => Connector.fromJson(e))
              .toList() ??
          [];

    // Logic to derive status from connectors if provided, matching WebSocket logic
    String backendStatus = json['status']?.toString() ?? 'offline';
    String derivedStatus = backendStatus;

    // Only derive from connectors if the station is not explicitly offline
    if (backendStatus.toLowerCase() != 'offline' && connectors.isNotEmpty) {
       bool anyAvailable = connectors.any(
          (c) => c.status.toLowerCase() == 'available' || c.status.toLowerCase() == 'preparing'
       );
       bool allFaulted = connectors.every(
          (c) => c.status.toLowerCase() == 'faulted' || c.status.toLowerCase() == 'unavailable' || c.status.toLowerCase() == 'offline'
       );
       
       if (anyAvailable) {
          derivedStatus = 'online';
       } else if (allFaulted) {
          derivedStatus = 'offline';
       } else {
          // If not available and not all faulted, assume busy/charging
          derivedStatus = 'busy';
       }
    }

    return Charger(
      chargerId: json['charger_id']?.toString() ?? '',
      name: json['name']?.toString(),
      location: json['location'] != null
          ? (json['location'] is Map<String, dynamic>
              ? Location.fromJson(json['location'])
              : null)
          : null,
      status: derivedStatus,
      maxPowerKw: (json['max_power_kw'] as num?)?.toDouble() ?? 0.0,
      tariffId: json['tariff_id'] is Map ? null : json['tariff_id']?.toString(),
      siteId: json['site_id'] is Map ? null : json['site_id']?.toString(),
      vendor: json['vendor'] is Map ? null : json['vendor']?.toString(),
      modelName: json['modelName']?.toString(),
      distance: (json['distance'] as num?)?.toDouble(),
      costPerUnit: _parsePrice(json['cost_per_unit']) ?? _parsePrice(json['price_per_kwh']),
      connectors: connectors,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      facilities: (json['facilities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static double? _parsePrice(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
       return double.tryParse(val);
    }
    return null;
  }

  Charger copyWith({
    String? status,
    List<Connector>? connectors,
    double? costPerUnit,
  }) {
    return Charger(
      chargerId: this.chargerId,
      name: this.name,
      location: this.location,
      status: status ?? this.status,
      maxPowerKw: this.maxPowerKw,
      tariffId: this.tariffId,
      siteId: this.siteId,
      vendor: this.vendor,
      modelName: this.modelName,
      distance: this.distance,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      connectors: connectors ?? this.connectors,
      images: this.images,
      facilities: this.facilities,
    );
  }
}

class Location {
  final double lat;
  final double lng;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  Location({
    required this.lat,
    required this.lng,
    this.address,
    this.city,
    this.state,
    this.zipCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] is Map ? null : json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: json['zip_code']?.toString(),
    );
  }
}

class Connector {
  final int? connectorId;
  final String status;
  final String? type;
  final double maxPowerKw;

  Connector({
    this.connectorId,
    required this.status,
    this.type,
    required this.maxPowerKw,
  });

  factory Connector.fromJson(Map<String, dynamic> json) {
    return Connector(
      connectorId: json['connector_id'] as int?,
      status: json['status'] ?? 'Unknown',
      type: json['type'],
      maxPowerKw: (json['max_power_kw'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Connector copyWith({String? status}) {
    return Connector(
      connectorId: this.connectorId,
      status: status ?? this.status,
      type: this.type,
      maxPowerKw: this.maxPowerKw,
    );
  }
}
