import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/home/domain/models/charging_station.dart';
import 'package:user_app/feature/home/presentation/pages/search_location_view.dart';

class HomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final stations = <ChargingStation>[].obs;
  final isLoading = false.obs;
  final selectedTab = 0.obs;

  // Recent Searches
  final recentSearches = <Map<String, String>>[].obs;
  static const String _recentSearchesKey = 'recent_searches';

  // Map
  final Completer<GoogleMapController> _mapController = Completer();
  final markers = <Marker>{}.obs;
  // Hold the selected search location marker separately or as part of state
  Marker? _selectedLocationMarker; 
  
  // Cache marker icons to improve performance
  late final BitmapDescriptor _iconGreen;
  late final BitmapDescriptor _iconOrange;
  late final BitmapDescriptor _iconRed;

  final currentLocation = Rxn<Position>();
  final isLocationGranted = false.obs;

  // UI Controllers
  final PageController pageController = PageController(viewportFraction: 0.85);

  final searchController = TextEditingController();
  final searchResults = <dynamic>[].obs;
  final isSearching = false.obs;
  final searchError = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _initializeMarkerIcons();
    
    // Listen for manual text clearing
    searchController.addListener(() {
      if (searchController.text.isEmpty && _selectedLocationMarker != null) {
        _selectedLocationMarker = null;
        _updateMarkers();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      loadRecentSearches();
    });
  }

  void _initializeMarkerIcons() {
    // Initialize icons once
    _iconGreen = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _iconOrange = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _iconRed = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  
  // Recent Searches Logic
  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_recentSearchesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        recentSearches.value = jsonList.map((e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> saveRecentSearch(String placeId, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove duplicates
      recentSearches.removeWhere((item) => item['placeId'] == placeId);
      
      // Add to top
      recentSearches.insert(0, {'placeId': placeId, 'description': description});
      
      // Limit to 5
      if (recentSearches.length > 5) {
        recentSearches.value = recentSearches.sublist(0, 5);
      }
      
      // Save to prefs
      await prefs.setString(_recentSearchesKey, json.encode(recentSearches));
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  // Wrapper to handle debounce
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchPlaces(query);
    });
  }

  void openSearch() {
    searchController.clear();
    searchResults.clear();
    // Using a simpler transition to avoid potential rendering crashes on heavy load
    Get.to(
      () => const SearchLocationView(), 
      transition: Transition.fade, // Changed from downToUp to fade for stability
      duration: const Duration(milliseconds: 200) // Slightly faster
    );
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    _selectedLocationMarker = null;
    _updateMarkers(); // Immediate visual update
    recenterMap();
  }

  Future<void> recenterMap() async {
    isLoading.value = true;
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        currentLocation.value = position;
        
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
        
        fetchNearbyStations(lat: position.latitude, lng: position.longitude);
      } else {
        Get.snackbar("Permission Denied", "Location permission is required to center map.");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not get current location: $e");
    } finally {
      isLoading.value = false;
    }
  }

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
      
      // Encode query to handle spaces and special characters
      final encodedQuery = Uri.encodeComponent(query);
      
      // Removed country:in restriction to allow broader search
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey');
      
      final response = await _apiProvider.getDirect(url, timeout: const Duration(seconds: 20));
      
      print("Google Places API Status: ${response['status']}");

      if (response['status'] == 'OK') {
        searchResults.value = response['predictions'];
      } else if (response['status'] == 'ZERO_RESULTS') {
        searchResults.clear();
      } else {
        print("Google Places API Error: ${response['error_message'] ?? response['status']}");
        searchResults.clear();
        searchError.value = "No results found or API error";
        
        if (response['status'] == 'REQUEST_DENIED') {
          searchError.value = "API Key Invalid or Permission Denied";
        } else if (response['status'] == 'OVER_QUERY_LIMIT') {
           searchError.value = "Search quota exceeded";
        }
      }
    } catch (e) {
      print("Search error: $e");
      searchResults.clear();
      if (e.toString().contains("TimeoutException")) {
        searchError.value = "Network timeout. Please check your connection.";
      } else {
        searchError.value = "Search failed. Please try again.";
      }
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> onPlaceSelected(String placeId, String description) async {
    try {
      // Save to recent searches
      saveRecentSearch(placeId, description);

      // Close search view and return to map
      Get.back();

      searchController.text = description;
      searchResults.clear();
      FocusManager.instance.primaryFocus?.unfocus();

      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey');

      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        final location = response['result']['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];

        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
          ),
        );
        
        // Add a red marker for the selected location
        _selectedLocationMarker = Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          icon: _iconRed,
          infoWindow: InfoWindow(title: description),
        );

        fetchNearbyStations(lat: lat, lng: lng);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not fetch place details: $e");
    }
  }

  Future<void> _initializeLocation() async {
    isLoading.value = true;
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        isLocationGranted.value = true;
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        currentLocation.value = position;
        
        // Move camera to user location immediately upon initialization
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );

        fetchNearbyStations(lat: position.latitude, lng: position.longitude);
      } else {
        isLocationGranted.value = false;
        fetchNearbyStations(); // Fallback
      }
    } catch (e) {
      print("Error getting location: $e");
      fetchNearbyStations(); // Fallback
    }
  }

  void onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }

    // Set style or initial position if needed
    if (currentLocation.value != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation.value!.latitude,
              currentLocation.value!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    if (index == 0) {
      // If returning to home tab, maybe refresh or re-center map
    }
  }

  Future<void> fetchNearbyStations({double? lat, double? lng}) async {
    // Default to New Delhi if no location provided
    final double latitude = lat ?? 28.6139;
    final double longitude = lng ?? 77.2090;

    try {
      isLoading.value = true;

      final response = await _apiProvider.get(
        '/search/nearby?lat=$latitude&lng=$longitude&radius=50000',
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        stations.value = data.map((e) => ChargingStation.fromJson(e)).toList();
        _updateMarkers();
      }
    } catch (e) {
      print('Error fetching stations: $e');
      _loadMockData(latitude, longitude);
    } finally {
      isLoading.value = false;
    }
  }

  void _loadMockData(double centerLat, double centerLng) {
    // Generate some mock stations around the center
    stations.value = [
      ChargingStation(
        chargerId: "MOCK-001",
        name: "Connaught Place Supercharger",
        location: Location(lat: centerLat + 0.002, lng: centerLng + 0.002, address: "Connaught Place, New Delhi"),
        status: "online",
        maxPowerKw: 150.0,
        connectors: [
          Connector(connectorId: 1, status: "Available", type: "CCS2", maxPowerKw: 150.0),
          Connector(connectorId: 2, status: "Charging", type: "Type2", maxPowerKw: 22.0),
        ],
      ),
      ChargingStation(
        chargerId: "MOCK-002",
        name: "Cyber City Fast Charge",
        location: Location(lat: centerLat - 0.003, lng: centerLng + 0.004, address: "Cyber City, Gurugram"),
        status: "offline",
        maxPowerKw: 50.0,
        connectors: [
          Connector(connectorId: 1, status: "Faulted", type: "CCS2", maxPowerKw: 50.0),
        ],
      ),
      ChargingStation(
        chargerId: "MOCK-003",
        name: "Mall of India Station",
        location: Location(lat: centerLat + 0.005, lng: centerLng - 0.003, address: "Sector 18, Noida"),
        status: "online",
        maxPowerKw: 60.0,
        connectors: [
          Connector(connectorId: 1, status: "Available", type: "CCS2", maxPowerKw: 60.0),
          Connector(connectorId: 2, status: "Available", type: "CCS2", maxPowerKw: 60.0),
        ],
      ),
    ];
    _updateMarkers();
    Get.snackbar("Demo Mode", "Loaded mock stations (Backend unreachable)", 
      snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
  }

  void _updateMarkers() {
    // Create a local set to minimize observable notifications
    final newMarkers = <Marker>{};
    
    // Re-add selected location marker if it exists
    if (_selectedLocationMarker != null) {
      newMarkers.add(_selectedLocationMarker!);
    }

    for (var station in stations) {
      if (station.location != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(station.chargerId),
            position: LatLng(station.location!.lat, station.location!.lng),
            infoWindow: InfoWindow(title: station.name ?? station.chargerId),
            // Use cached icons
            icon: station.status == 'online' ? _iconGreen : _iconOrange,
            onTap: () {
              int index = stations.indexOf(station);
              if (index != -1 && pageController.hasClients) {
                pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        );
      }
    }
    
    // Assign all at once to trigger a single rebuild
    markers.assignAll(newMarkers);
  }

  // Called when page view changes
  void onPageChanged(int index) async {
    if (index >= 0 && index < stations.length) {
      final station = stations[index];
      if (station.location != null) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(station.location!.lat, station.location!.lng),
              zoom: 15,
            ),
          ),
        );

        // Show info window
        controller.showMarkerInfoWindow(MarkerId(station.chargerId));
      }
    }
  }

  Future<void> reserveConnector(String chargerId, int connectorId) async {
    try {
      isLoading.value = true;
      await _apiProvider.post('/reservations/create', {
        'charger_id': chargerId,
        'connector_id': connectorId,
        'expiry_minutes': 15,
      });
      Get.snackbar('Success', 'Connector reserved for 15 mins');
    } catch (e) {
      Get.snackbar('Error', 'Reservation failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> launchMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not open maps");
    }
  }
}
