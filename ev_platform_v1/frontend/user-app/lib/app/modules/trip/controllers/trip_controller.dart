import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/home/domain/models/saved_trip.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';

class TripController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  // Text Controllers
  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  
  // Location State
  final sourceLatLng = Rxn<LatLng>();
  final destinationLatLng = Rxn<LatLng>();
  final activeField = 'destination'.obs; // 'source' or 'destination'
  
  // Trip State
  final departureSoC = 90.0.obs;
  final arrivalSoC = 0.0.obs;
  final tripStops = <Charger>[].obs;
  final isItineraryMinimized = false.obs;
  
  // Saved Trips
  final savedTrips = <SavedTrip>[].obs;
  final currentSavedTripId = Rxn<String>();
  
  // Trip View Mode
  final isSavedTripMode = false.obs;
  
  // Map State
  GoogleMapController? mapController;
  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final isMapReady = false.obs;
  final isMapDragging = false.obs;

  // Marker Icons
  BitmapDescriptor? _iconGreen;
  BitmapDescriptor? _iconOrange;
  BitmapDescriptor? _iconRed;
  BitmapDescriptor? _iconBlue;
  
  // Selected Station (for details on trip map)
  final selectedStation = Rxn<Charger>();
  
  // Search State
  final searchResults = <dynamic>[].obs;
  final isSearching = false.obs;
  final searchError = ''.obs;
  Timer? _debounce;
  
  // Generic Loading State
  final isLoading = false.obs;

  // ... (rest of the file)

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      searchError.value = '';
      return;
    }

    try {
      isSearching.value = true;
      searchError.value = '';
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(
        url,
        timeout: const Duration(seconds: 20),
      );

      if (response['status'] == 'OK') {
        searchResults.value = response['predictions'];
      } else {
        searchResults.clear();
        searchError.value = "No results found";
      }
    } catch (e) {
      print("Search error: $e");
      searchError.value = "Search failed";
    } finally {
      isSearching.value = false;
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchPlaces(query);
    });
  }

  Future<void> onPlaceSelected(String placeId, String description) async {
    try {
      if (activeField.value == 'source') {
        sourceController.text = description;
      } else {
        destinationController.text = description;
      }

      searchResults.clear();
      // Unfocus handled by UI

      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        final location = response['result']['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        final latLng = LatLng(lat, lng);

        if (activeField.value == 'source') {
          sourceLatLng.value = latLng;
        } else {
          destinationLatLng.value = latLng;
        }
        
        // Return back to Trip View if we are in a picker
        // (Assuming we are navigating to a search view)
      }
    } catch (e) {
      Get.snackbar("Error", "Could not fetch place details");
    }
  }
  @override
  void onInit() {
    super.onInit();
    _initializeMarkerIcons();
    fetchSavedTrips();
    
    // Check arguments
    if (Get.arguments != null) {
      if (Get.arguments is SavedTrip) {
        loadSavedTrip(Get.arguments as SavedTrip);
      }
    }
    
    // Listeners to clear state
    sourceController.addListener(() {
      if (sourceController.text.isEmpty) {
        sourceLatLng.value = null;
      }
    });

    destinationController.addListener(() {
      if (destinationController.text.isEmpty) {
        destinationLatLng.value = null;
      }
    });
    
    // Auto-update trip markers when stops change
    ever(tripStops, (_) async => await _updateMarkers());
  }
  
  @override
  void onClose() {
    sourceController.dispose();
    destinationController.dispose();
    mapController?.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    isMapReady.value = true;
    
    // If we have data, fit bounds
    if (sourceLatLng.value != null && destinationLatLng.value != null) {
      _fitBounds();
    } else {
        // Try to center on current location if available from Home
        try {
            final home = Get.find<HomeController>();
            if (home.currentLocation.value != null) {
                controller.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(home.currentLocation.value!.latitude, home.currentLocation.value!.longitude),
                    14
                ));
            }
        } catch (e) {
            print("Home controller not found or no location: $e");
        }
    }
  }

  void toggleItineraryMinimize() => isItineraryMinimized.toggle();

  void selectStation(Charger station) {
    selectedStation.value = station;
    // Animate to station
    if (station.location != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(station.location!.lat, station.location!.lng),
          16,
        ),
      );
    }
  }

  void deselectStation() {
    selectedStation.value = null;
  }

  // --- Trip Planning Logic ---

  Future<void> planTrip() async {
    if (sourceLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar("Error", "Please select valid Source and Destination");
      return;
    }

    try {
      // 1. Collect Waypoints
      List<LatLng> waypoints = [];
      for (var stop in tripStops) {
        if (stop.location != null) {
          waypoints.add(LatLng(stop.location!.lat, stop.location!.lng));
        }
      }

      // 2. Fetch Route (Using same logic as Home)
      // We need to implement _getPolylineCoordinates or import it.
      // For now, I'll copy the logic logic or delegate if possible.
      // Since I can't easily delegate private methods, I'll duplicate the route fetching logic
      // or move it to a service. For now, duplication/adaptation.
      
      final routePoints = await _getPolylineCoordinates(
        sourceLatLng.value!,
        destinationLatLng.value!,
        waypoints: waypoints,
      );

      // 3. Update Polylines
      polylines.clear();
      if (routePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId("trip_corridor"),
            points: routePoints,
            color: AppColors.primary.withOpacity(0.2),
            width: 20,
            zIndex: 1,
          ),
        );
        polylines.add(
          Polyline(
            polylineId: const PolylineId("trip_route"),
            points: routePoints,
            color: AppColors.primary,
            width: 5,
            zIndex: 2,
          ),
        );
      }

      // 4. Fit Bounds
      _fitBounds();

      // 5. Fetch Chargers along route
      await fetchRouteStations(routePoints);
      
      await _updateMarkers();

    } catch (e) {
      print("Error planning trip: $e");
      Get.snackbar("Error", "Failed to plan trip");
    }
  }

  void _fitBounds() {
     if (polylines.isEmpty || mapController == null) return;
     // Calculate bounds from polyline points
     final points = polylines.first.points;
     if (points.isEmpty) return;
     
     final bounds = _boundsFromLatLngList(points);
     mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // --- API / Logic ---

  Future<List<LatLng>> _getPolylineCoordinates(
    LatLng start,
    LatLng end, {
    List<LatLng>? waypoints,
  }) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointsString =
            waypoints.map((e) => "${e.latitude},${e.longitude}").join('|');
        url += "&waypoints=$waypointsString";
      }

      final response = await _apiProvider.getDirect(Uri.parse(url));

      if (response['status'] == 'OK' &&
          response['routes'] != null &&
          (response['routes'] as List).isNotEmpty) {
        final encodedPoints =
            response['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(encodedPoints);
      } else {
        print("Directions API Error: ${response['status']}");
        return [start, end];
      }
    } catch (e) {
      print("Error fetching directions: $e");
      return [start, end];
    }
  }

  Future<void> fetchRouteStations(List<LatLng> routePoints) async {
    // Simplify route points
    List<Map<String, double>> pointsPayload = [];
    int step = 1;
    if (routePoints.length > 500) {
      step = (routePoints.length / 500).ceil();
    }

    for (int i = 0; i < routePoints.length; i += step) {
      pointsPayload.add({
        'lat': routePoints[i].latitude,
        'lng': routePoints[i].longitude,
      });
    }
    if (routePoints.isNotEmpty) {
      pointsPayload.add({
        'lat': routePoints.last.latitude,
        'lng': routePoints.last.longitude,
      });
    }

    try {
      final response = await _apiProvider.post('/search/route', {
        'routePoints': pointsPayload,
        'bufferDistance': 1000,
      });

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        final stations = data.map((e) => Charger.fromJson(e)).toList();
        
        // Use these stations to update markers
        // We might want to store them in a list first
        // For now, I'll just add them to markers directly in _updateMarkers
        // But I need to store them somewhere. 
        // Let's add a `routeStations` list.
        routeStations.value = stations;
        await _updateMarkers();
      }
    } catch (e) {
      print("Error fetching route stations: $e");
    }
  }

  final routeStations = <Charger>[].obs;

  // --- Saved Trips ---

  Future<void> fetchSavedTrips() async {
    try {
      isLoading.value = true;
      final res = await _apiProvider.get('/saved-trips');
      if (res['error'] == false) {
        final list = (res['data'] as List)
            .map((e) => SavedTrip.fromJson(e))
            .toList();
        savedTrips.assignAll(list);
      }
    } catch (e) {
      print("Fetch Saved Trips Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveCurrentTrip(String name) async {
    if (sourceLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar("Error", "Source and Destination required");
      return;
    }

    try {
      isLoading.value = true;
      final stopsData = tripStops
          .where((s) => s.location != null)
          .map(
            (s) => TripStop(
              chargerId: s.chargerId,
              name: s.name,
              address: s.location?.address,
              location: TripLocation(
                address: s.location?.address ?? '',
                lat: s.location!.lat,
                lng: s.location!.lng,
              ),
            ),
          )
          .toList();

      final body = {
        'name': name,
        'source': {
          'address': sourceController.text,
          'lat': sourceLatLng.value!.latitude,
          'lng': sourceLatLng.value!.longitude,
        },
        'destination': {
          'address': destinationController.text,
          'lat': destinationLatLng.value!.latitude,
          'lng': destinationLatLng.value!.longitude,
        },
        'stops': stopsData.map((s) => s.toJson()).toList(),
      };

      final res = await _apiProvider.post('/saved-trips', body);
      if (res['error'] == false) {
        Get.snackbar("Success", "Trip saved!");
        await fetchSavedTrips();
      } else {
        Get.snackbar("Error", res['message'] ?? "Failed to save trip");
      }
    } catch (e) {
      print("Save Trip Error: $e");
      Get.snackbar("Error", "Failed to save trip");
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteSavedTrip(String id) async {
    try {
      isLoading.value = true;
      final res = await _apiProvider.delete('/saved-trips/$id');
      if (res['error'] == false) {
        Get.snackbar("Success", "Trip deleted!");
        await fetchSavedTrips();
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      print("Delete Trip Error: $e");
      isLoading.value = false;
    }
  }

  void loadSavedTrip(SavedTrip trip) {
    isSavedTripMode.value = true;
    currentSavedTripId.value = trip.id;
    sourceController.text = trip.source.address;
    sourceLatLng.value = LatLng(trip.source.lat, trip.source.lng);

    destinationController.text = trip.destination.address;
    destinationLatLng.value = LatLng(
      trip.destination.lat,
      trip.destination.lng,
    );

    tripStops.clear();
    final mappedStations = trip.stops.map((s) {
      return Charger(
        chargerId: s.chargerId ?? 'unknown',
        name: s.name,
        location: Location(
          lat: s.location.lat,
          lng: s.location.lng,
          address: s.location.address,
        ),
        status: 'Unknown',
        maxPowerKw: 0,
        connectors: [],
      );
    }).toList();
    tripStops.assignAll(mappedStations);
    
    planTrip();
  }

  void cancelTrip() {
    isSavedTripMode.value = false;
    currentSavedTripId.value = null;
    sourceController.clear();
    destinationController.clear();
    sourceLatLng.value = null;
    destinationLatLng.value = null;
    polylines.clear();
    markers.clear();
    tripStops.clear();
    routeStations.clear();
    selectedStation.value = null;
    
    // Reset map?
    _updateMarkers();
  }

  // --- Helpers ---

  Future<void> _updateMarkers() async {
    final newMarkers = <Marker>{};

    // Source
    if (sourceLatLng.value != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('source'),
        position: sourceLatLng.value!,
        icon: _iconBlue ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Start"),
        zIndex: 2,
      ));
    }

    // Destination
    if (destinationLatLng.value != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destinationLatLng.value!,
        icon: _iconRed ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Destination"),
        zIndex: 2,
      ));
    }

    // Stations
    for (var station in routeStations) {
       final isOnline = station.status.toLowerCase() == 'online';
       final icon = isOnline
          ? (_iconGreen ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))
          : (_iconOrange ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));
          
       newMarkers.add(Marker(
         markerId: MarkerId(station.chargerId),
         position: LatLng(station.location!.lat, station.location!.lng),
         icon: icon,
         onTap: () => selectStation(station),
         zIndex: 0,
       ));
    }
    
    // Stops
    for (int i = 0; i < tripStops.length; i++) {
        final stop = tripStops[i];
        if (stop.location != null) {
             final icon = await _createCustomMarkerBitmap(Colors.purple, text: "${i + 1}");
             
             newMarkers.add(Marker(
                markerId: MarkerId("stop_${stop.chargerId}"),
                position: LatLng(stop.location!.lat, stop.location!.lng),
                icon: icon,
                infoWindow: InfoWindow(title: stop.name ?? "Stop ${i + 1}"),
                onTap: () => selectStation(stop),
                zIndex: 3, // Highest priority
             ));
        }
    }

    markers.assignAll(newMarkers);
  }
  
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
  
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0!) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _initializeMarkerIcons() async {
    try {
      _iconGreen = await _createCustomMarkerBitmap(Colors.green);
      _iconOrange = await _createCustomMarkerBitmap(Colors.orange);
      _iconRed = await _createCustomMarkerBitmap(Colors.red);
      _iconBlue = await _createCustomMarkerBitmap(Colors.blue);
      _updateMarkers();
    } catch (e) {
      print("Error creating icons: $e");
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color, {String? text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint whitePaint = Paint()..color = Colors.white;

    const double size = 100.0;
    const double radius = 30.0;

    final Path path = Path();
    path.moveTo(size / 2, size);
    path.quadraticBezierTo(size / 2, size * 0.75, size / 2 - radius, size * 0.45);
    path.arcToPoint(Offset(size / 2 + radius, size * 0.45), radius: const Radius.circular(radius), clockwise: true);
    path.quadraticBezierTo(size / 2, size * 0.75, size / 2, size);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size / 2, size * 0.45), 12.0, whitePaint);

    if (text != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 16, // Adjusted for 24px diameter circle
            color: Colors.black, 
            fontWeight: FontWeight.bold
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(size / 2 - textPainter.width / 2, size * 0.45 - textPainter.height / 2)
      );
    }

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
