import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/home/domain/models/charger.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:user_app/feature/more/presentation/pages/account/presentation/controllers/profile_controller.dart';

class ReservationController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  final stations = <Charger>[].obs;
  final filteredStations = <Charger>[].obs;
  final isLoading = false.obs;
  
  final myReservations = <dynamic>[].obs; // List of user's reservations

  final searchController = TextEditingController();
  final selectedFilter = 'All Chargers'.obs;
  
  final filters = ['All Chargers', 'Available', 'Fast (DC)', 'Slow (AC)'];
  
  // Search Location Logic
  final searchResults = <dynamic>[].obs;
  final isSearchingLocation = false.obs;
  final searchError = ''.obs;
  Timer? _debounce;
  
  bool _ignoreSearchListener = false;
  String? _lastSelectedPlaceText;

  final viewMode = 0.obs; // 0: My Reservations, 1: Book New
  
  @override
  void onInit() {
    super.onInit();
    fetchStations();
    fetchMyReservations();
    
    // Listen to search changes
    searchController.addListener(() {
      _onSearchChanged();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
  
  void _onSearchChanged() {
    if (_ignoreSearchListener) return;

    final query = searchController.text;
    if (query.isEmpty) {
      isSearchingLocation.value = false;
      searchResults.clear();
      _lastSelectedPlaceText = null;
      filterStations(); // Reset to local filter or all stations
      return;
    }
    
    // If query is short, maybe it's just local filtering of existing list?
    // But user asked for "Search Location like Home".
    // So we should trigger autocomplete.
    // However, we also want to filter existing list by name.
    // Let's assume if user is typing, we show autocomplete results primarily if they want to change location.
    // Or maybe we show both?
    // User requirement: "isnted map poointin i nee dti fetch teh nearby staio a and show theat"
    // This implies searching for a PLACE (e.g. "Connaught Place") -> Fetch stations there.
    
    // So if I type "Connau...", I expect "Connaught Place" suggestion.
    // Tapping it fetches stations.
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
        searchPlaces(query);
    });
  }

  void filterStations() {
    // This is for local filtering of FETCHED stations
    String query = searchController.text.toLowerCase();
    
    // If we are showing search results from API (Places), we don't need this local filter yet.
    // But if isSearchingLocation is false (user cleared search or selected a place), we show filtered stations.
    if (isSearchingLocation.value) return;

    List<Charger> temp = stations;
    
    // 1. Filter by Search (Name/Address) - Only if we have stations and not searching for a new place
    if (query.isNotEmpty && query.toLowerCase() != _lastSelectedPlaceText?.toLowerCase()) {
       // If user typed something but didn't select a place yet, maybe we shouldn't filter locally unless we want to search BY NAME in current list.
       // Let's keep local filter for now as a fallback or secondary feature.
      temp = temp.where((s) {
        return (s.name?.toLowerCase().contains(query) ?? false) ||
               (s.location?.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // 2. Filter by Chip
    if (selectedFilter.value == 'Available') {
      temp = temp.where((s) => s.status.toLowerCase() == 'online').toList();
    } else if (selectedFilter.value == 'Fast (DC)') {
      temp = temp.where((s) => s.connectors.any((c) => (c.type?.contains('CCS') ?? false) || (c.type?.contains('DC') ?? false))).toList();
    } else if (selectedFilter.value == 'Slow (AC)') {
      temp = temp.where((s) => s.connectors.any((c) => (c.type?.contains('AC') ?? false) || (c.type?.contains('Type2') ?? false))).toList();
    }
    
    filteredStations.value = temp;
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    filterStations();
  }
  
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;
    
    try {
      isSearchingLocation.value = true;
      searchError.value = '';
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco"; // Using same key as Home
      final encodedQuery = Uri.encodeComponent(query);
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(url);
      
      if (response['status'] == 'OK') {
        searchResults.value = response['predictions'];
      } else {
        searchResults.clear();
      }
    } catch (e) {
      print("Place Search Error: $e");
      searchResults.clear();
    }
  }
  
  Future<void> onPlaceSelected(String placeId, String description) async {
      _ignoreSearchListener = true;
      searchController.text = description;
      _lastSelectedPlaceText = description;
      _ignoreSearchListener = false;

      isSearchingLocation.value = false;
      searchResults.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      
      isLoading.value = true;
      
      try {
        const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
        final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey',
        );
        
        final response = await _apiProvider.getDirect(url);
        
        if (response['status'] == 'OK') {
             final location = response['result']['geometry']['location'];
             final double lat = location['lat'];
             final double lng = location['lng'];
             
             // Fetch stations near this location
             await fetchStations(lat: lat, lng: lng, radius: 50000); // 50km radius
        }
      } catch (e) {
         print("Error fetching place details: $e");
         Get.snackbar("Error", "Failed to load location details");
         isLoading.value = false;
      }
  }

  Future<void> fetchStations({double? lat, double? lng, double radius = 100000}) async {
    isLoading.value = true;
    try {
      double? targetLat = lat;
      double? targetLng = lng;

      // Reuse Home Controller stations ONLY if no specific location requested
      if (lat == null && lng == null) {
         if (Get.isRegistered<HomeController>()) {
            final homeController = Get.find<HomeController>();
            
            // 1. Try reusing stations if available
            if (homeController.stations.isNotEmpty) {
              stations.value = homeController.stations;
              filterStations(); // Apply filters
              isLoading.value = false;
              return;
            }
            
            // 2. Try using Home Controller's location if available
            if (homeController.currentLocation.value != null) {
              targetLat = homeController.currentLocation.value!.latitude;
              targetLng = homeController.currentLocation.value!.longitude;
            }
         }
         
         // If we still don't have location, try getting current location safely
         if (targetLat == null || targetLng == null) {
           try {
             var status = await Permission.location.status;
             if (!status.isGranted) {
               try {
                 status = await Permission.location.request();
               } catch (e) {
                 // Concurrent request check
                 status = await Permission.location.status;
               }
             }
             
             if (status.isGranted) {
               Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
               );
               targetLat = position.latitude;
               targetLng = position.longitude;
             }
           } catch (e) {
             print("Error getting location in Reservation: $e");
           }
         }
      }

      // Default to New Delhi if absolutely nothing available
      final double latitude = targetLat ?? 28.6139;
      final double longitude = targetLng ?? 77.2090;

      final response = await _apiProvider.get(
        '/search/nearby?lat=$latitude&lng=$longitude&radius=$radius',
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        stations.value = data.map((e) => Charger.fromJson(e)).toList();
        filterStations(); // Apply filters
      } else {
         stations.clear();
         filterStations();
      }
    } catch (e) {
      print("Error fetching stations: $e");
      // Load mock data if fail
      _loadMockData();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadMockData() {
     stations.value = [
      Charger(
        chargerId: "MOCK-001",
        name: "KA | Bengaluru | The Pavilion 2",
        location: Location(
          lat: 12.9716,
          lng: 77.5946,
          address: "Hyundai EVCS, Bengaluru",
        ),
        status: "online",
        maxPowerKw: 150.0,
        distance: 1.0,
        facilities: [],
        images: [],
        vendor: "Tata Power",
        connectors: [
          Connector(connectorId: 1, status: "Available", type: "CCS2", maxPowerKw: 150.0),
        ],
      ),
      Charger(
        chargerId: "MOCK-002",
        name: "L2STTEST",
        location: Location(
          lat: 12.9716,
          lng: 77.5946,
          address: "Someshwara Colony",
        ),
        status: "online",
        maxPowerKw: 22.0,
        distance: 1.2,
        facilities: [],
        images: [],
        vendor: "EESL",
        connectors: [
           Connector(connectorId: 1, status: "Available", type: "Type2", maxPowerKw: 22.0),
        ],
      ),
      Charger(
        chargerId: "MOCK-003",
        name: "B&B Opulent Spire Car charger 3",
        location: Location(
          lat: 12.9716,
          lng: 77.5946,
          address: "Jayanagar",
        ),
        status: "online",
        maxPowerKw: 7.4,
        distance: 2.5,
        facilities: [],
        images: [],
        vendor: "Statiq",
        connectors: [
           Connector(connectorId: 1, status: "Available", type: "AC", maxPowerKw: 7.4),
        ],
      ),
    ];
    filterStations();
  }

  Future<void> createReservation(String chargerId, int connectorId, int expiryMinutes) async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.post('/reservations/create', {
        'charger_id': chargerId,
        'connector_id': connectorId,
        'expiry_minutes': expiryMinutes,
      });

      if (response['error'] == false) {
        Get.back(); // Close Booking View
        Get.snackbar(
          "Success", 
          "Reservation created successfully!", 
          backgroundColor: Colors.green, 
          colorText: Colors.white
        );
        // Refresh profile to update side menu
        if (Get.isRegistered<ProfileController>()) {
           Get.find<ProfileController>().fetchUpcomingReservation();
        }
        // Refresh my reservations
        fetchMyReservations();
      } else {
        Get.snackbar("Error", response['message'] ?? "Failed to create reservation", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to create reservation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyReservations() async {
    try {
      // Don't set global isLoading as it might block station search
      final response = await _apiProvider.get('/reservations/list');
      if (response['error'] == false) {
        myReservations.value = response['data'];
      }
    } catch (e) {
      print("Error fetching my reservations: $e");
    }
  }

  void onReservationClick(dynamic reservation) {
     final String chargerId = reservation['charger_id'];
     
     // Navigate to Home and show details
     if (Get.isRegistered<HomeController>()) {
        Get.offAllNamed('/home'); // Go to dashboard
        // Wait for frame to ensure controller is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
           Get.find<HomeController>().showStationDetails(chargerId);
        });
     } else {
        Get.offAllNamed('/home');
        // If controller not registered yet, it will init on home load
        // But we need to pass the intent. 
        // Best way is to pass arguments to Home/Dashboard and handle it there.
        // But for now, assuming HomeController is likely alive or Fenix.
        Future.delayed(const Duration(milliseconds: 500), () {
           if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().showStationDetails(chargerId);
           }
        });
     }
  }
}
