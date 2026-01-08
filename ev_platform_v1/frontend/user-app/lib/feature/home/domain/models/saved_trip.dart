class SavedTrip {
  final String id;
  final int? userId; // Added userId as integer
  final String name;
  final TripLocation source;
  final TripLocation destination;
  final List<TripStop> stops;
  final DateTime createdAt;

  SavedTrip({
    required this.id,
    this.userId,
    required this.name,
    required this.source,
    required this.destination,
    required this.stops,
    required this.createdAt,
  });

  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    return SavedTrip(
      id: json['trip_id']?.toString() ?? json['_id'], // Prefer numeric ID
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      name: json['name'],
      source: TripLocation.fromJson(json['source']),
      destination: TripLocation.fromJson(json['destination']),
      stops: (json['stops'] as List?)
              ?.map((s) => TripStop.fromJson(s))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': int.tryParse(id), // Try to send back as int if needed
      'user_id': userId,
      'name': name,
      'source': source.toJson(),
      'destination': destination.toJson(),
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }
}

class TripLocation {
  final String address;
  final double lat;
  final double lng;

  TripLocation({required this.address, required this.lat, required this.lng});

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      address: json['address'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}

class TripStop {
  final String? chargerId;
  final String? name;
  final String? address;
  final TripLocation location;

  TripStop({
    this.chargerId,
    this.name,
    this.address,
    required this.location,
  });

  factory TripStop.fromJson(Map<String, dynamic> json) {
    return TripStop(
      chargerId: json['charger_id'],
      name: json['name'],
      address: json['address'],
      location: TripLocation.fromJson(json['location']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charger_id': chargerId,
      'name': name,
      'address': address,
      'location': location.toJson(),
    };
  }
}
