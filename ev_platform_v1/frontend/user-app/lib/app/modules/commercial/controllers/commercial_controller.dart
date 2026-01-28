import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';

class CommercialController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  final isLoading = false.obs;
  final myChargers = <dynamic>[].obs;
  final analytics = {}.obs;
  final walletHistory = <dynamic>[].obs;

  final searchResults = <dynamic>[].obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch data when controller initializes
    fetchMyChargers();
    fetchAnalytics();
    fetchWalletHistory();
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco"; // Using same key as Home
      final encodedQuery = Uri.encodeComponent(query);
      
      // Use direct http call or ApiProvider if it supports full URL
      // Since ApiProvider appends baseUrl, we might need a direct get or use http package directly if ApiProvider doesn't support absolute URLs.
      // Looking at HomeController, it uses _apiProvider.getDirect(url)
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        searchResults.assignAll(response['predictions']);
      } else {
        searchResults.clear();
      }
    } catch (e) {
      print('Search error: $e');
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        final result = response['result'];
        final location = result['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
          'address': result['formatted_address']
        };
      }
    } catch (e) {
      print('Place details error: $e');
    }
    return null;
  }


  Future<void> fetchMyChargers() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.get('/commercial/chargers');
      
      if (response != null) {
        // Standardized format
        if (response is Map && response.containsKey('data')) {
           if (response['error'] == true) {
             print('Error fetching chargers: ${response['message']}');
             return;
           }
           final data = response['data'];
           if (data is List) {
             myChargers.assignAll(data);
           }
        } 
        // Fallback or raw list
        else if (response is List) {
           myChargers.assignAll(response);
        }
      }
    } catch (e) {
      print('Error fetching chargers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAnalytics() async {
    try {
      final response = await _apiProvider.get('/commercial/analytics');
      
      if (response != null) {
        if (response is Map && response.containsKey('data')) {
          if (response['error'] == true) {
             print('Error fetching analytics: ${response['message']}');
             return;
          }
          analytics.value = response['data'];
        } else {
          // Fallback
          analytics.value = response;
        }
      }
    } catch (e) {
      print('Error fetching analytics: $e');
    }
  }

  Future<void> fetchWalletHistory() async {
    try {
      final response = await _apiProvider.get('/commercial/wallet');
      
      if (response != null) {
         if (response is Map && response.containsKey('data')) {
           if (response['error'] == true) {
             print('Error fetching wallet: ${response['message']}');
             return;
           }
           final data = response['data'];
           if (data is List) {
             walletHistory.assignAll(data);
           }
         }
         else if (response is List) {
            walletHistory.assignAll(response);
         }
      }
    } catch (e) {
      print('Error fetching wallet: $e');
    }
  }

  Future<void> addCharger(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.post('/commercial/charger', data);
      
      Get.snackbar(
        'Success', 
        'Charger added successfully! It will appear on the map shortly.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      
      // Navigate to Home and focus on the new charger
      Get.offAllNamed('/dashboard');
      
      // Allow time for dashboard/home to initialize
      Future.delayed(const Duration(milliseconds: 800), () {
        if (Get.isRegistered<DashboardController>()) {
           Get.find<DashboardController>().changeTabIndex(0);
        }
        
        if (Get.isRegistered<HomeController>()) {
           final homeController = Get.find<HomeController>();
           final loc = data['location'];
           if (loc != null && loc['lat'] != null && loc['lng'] != null) {
              homeController.focusOnLocation(loc['lat'], loc['lng']);
           }
        }
      });
      
    } catch (e) {
      print('Full error adding charger: $e');
      String errorMessage = 'Failed to add charger';
      
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      
      Get.snackbar(
        'Error', 
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
