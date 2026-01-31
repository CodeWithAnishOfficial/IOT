import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/app/modules/home/views/station_details_view.dart';

class AllStationsController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  final stations = <Charger>[].obs;
  final filteredStations = <Charger>[].obs;
  final isLoading = false.obs;
  
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

  // Pagination
  int currentPage = 1;
  final int limit = 15;
  final hasMore = true.obs;
  final isLoadMoreRunning = false.obs;
  final ScrollController scrollController = ScrollController();

  // Store last used coordinates for pagination
  double? _lastLat;
  double? _lastLng;
  double? _lastRadius;

  @override
  void onInit() {
    super.onInit();
    fetchStations();
    
    // Listen to search changes
    searchController.addListener(() {
      _onSearchChanged();
    });

    // Listen to scroll for pagination
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    
    // Trigger load more aggressively (after ~40% scroll) to ensure smooth infinite scroll
    // This addresses the requirement to fetch next batch early (e.g. after 5th card of 15)
    if (currentScroll >= maxScroll * 0.4 || currentScroll >= maxScroll - 500) {
      if (hasMore.value && !isLoading.value && !isLoadMoreRunning.value) {
        fetchStations(isLoadMore: true);
      }
    }
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
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
        searchPlaces(query);
    });
  }

  void filterStations() {
    String query = searchController.text.toLowerCase();
    
    if (isSearchingLocation.value) return;

    List<Charger> temp = stations;
    
    // 1. Filter by Search (Name/Address)
    if (query.isNotEmpty && query.toLowerCase() != _lastSelectedPlaceText?.toLowerCase()) {
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
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
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
             
             await fetchStations(lat: lat, lng: lng, radius: 50000);
        }
      } catch (e) {
         print("Error fetching place details: $e");
         Get.snackbar("Error", "Failed to load location details");
         isLoading.value = false;
      }
  }

  Future<void> fetchStations({
    double? lat,
    double? lng,
    double radius = 100000,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (!hasMore.value) return;
      isLoadMoreRunning.value = true;
    } else {
      isLoading.value = true;
      currentPage = 1;
      hasMore.value = true;
    }

    try {
      double? targetLat = lat ?? _lastLat;
      double? targetLng = lng ?? _lastLng;

      // If this is a fresh load (not load more) and no location provided, find location
      if (!isLoadMore && (targetLat == null || targetLng == null)) {
         if (Get.isRegistered<HomeController>()) {
            final homeController = Get.find<HomeController>();
            if (homeController.currentLocation.value != null) {
              targetLat = homeController.currentLocation.value!.latitude;
              targetLng = homeController.currentLocation.value!.longitude;
            }
         }
         
         if (targetLat == null || targetLng == null) {
           try {
             var status = await Permission.location.status;
             if (!status.isGranted) {
                 status = await Permission.location.request();
             }
             if (status.isGranted) {
               Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
               );
               targetLat = position.latitude;
               targetLng = position.longitude;
             }
           } catch (e) {
             print("Error getting location in AllStations: $e");
           }
         }
      }

      final double latitude = targetLat ?? 28.6139;
      final double longitude = targetLng ?? 77.2090;
      
      // Update stored location for next page
      _lastLat = latitude;
      _lastLng = longitude;
      _lastRadius = radius;

      final response = await _apiProvider.get(
        '/search/nearby?lat=$latitude&lng=$longitude&radius=$radius&page=$currentPage&limit=$limit',
      );

      print("Fetch Stations Response: Page $currentPage, Data Length: ${response['data']?.length ?? 0}");

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        final newStations = data.map((e) => Charger.fromJson(e)).toList();
        
        if (isLoadMore) {
          stations.addAll(newStations);
        } else {
          stations.value = newStations;
        }

        // Check meta for pagination
        if (response['meta'] != null) {
            hasMore.value = response['meta']['hasMore'] ?? false;
        } else {
            // Fallback if meta is missing
            hasMore.value = newStations.length >= limit;
        }
        
        if (hasMore.value) {
            currentPage++;
        }

        filterStations();
      } else {
         if (!isLoadMore) {
            stations.clear();
            filterStations();
         }
         hasMore.value = false;
      }
    } catch (e) {
      print("Error fetching stations: $e");
    } finally {
      isLoading.value = false;
      isLoadMoreRunning.value = false;
    }
  }
  
  void navigateToStationDetails(Charger station) {
    if (Get.isRegistered<HomeController>()) {
       Get.find<HomeController>().navigateToStationDetails(station);
    } else {
       // Fallback if needed, though HomeController should be there
       Get.to(
          () => StationDetailsView(station: station, controller: Get.find<HomeController>()),
          transition: Transition.fadeIn
       );
    }
  }
}
