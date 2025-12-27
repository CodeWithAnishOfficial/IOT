class ChargingStation {
  final String chargerId;
  final String? name;
  final Location? location;
  final String status;
  final double maxPowerKw;
  final String? tariffId;
  final String? siteId;
  final String? vendor;
  final String? modelName;
  final List<Connector> connectors;

  ChargingStation({
    required this.chargerId,
    this.name,
    this.location,
    required this.status,
    required this.maxPowerKw,
    this.tariffId,
    this.siteId,
    this.vendor,
    this.modelName,
    required this.connectors,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      chargerId: json['charger_id'],
      name: json['name'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      status: json['status'],
      maxPowerKw: (json['max_power_kw'] as num?)?.toDouble() ?? 0.0,
      tariffId: json['tariff_id'],
      siteId: json['site_id'],
      vendor: json['vendor'],
      modelName: json['modelName'],
      connectors: (json['connectors'] as List?)
              ?.map((e) => Connector.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Location {
  final double lat;
  final double lng;
  final String? address;

  Location({required this.lat, required this.lng, this.address});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'],
    );
  }
}

class Connector {
  final int connectorId;
  final String status;
  final String? type;
  final double maxPowerKw;

  Connector({
    required this.connectorId,
    required this.status,
    this.type,
    required this.maxPowerKw,
  });

  factory Connector.fromJson(Map<String, dynamic> json) {
    return Connector(
      connectorId: json['connector_id'],
      status: json['status'],
      type: json['type'],
      maxPowerKw: (json['max_power_kw'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
