import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/home/domain/models/charging_station.dart';
import 'package:user_app/feature/home/presentation/pages/search_location_view.dart';
import 'package:user_app/feature/home/presentation/pages/qr_scanner_view.dart';
import 'package:user_app/feature/home/presentation/widgets/start_charging_sheet.dart';
import 'package:user_app/feature/charging/presentation/pages/active_session_view.dart';
import 'package:user_app/feature/charging/presentation/pages/charging_preparation_view.dart';
import 'package:user_app/core/Networks/websocket_service.dart';
import 'package:user_app/core/controllers/session_controller.dart';

class HomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final stations = <ChargingStation>[].obs;
  final isLoading = false.obs;

  // Recent Searches
  final recentSearches = <Map<String, String>>[].obs;
  static const String _recentSearchesKey = 'recent_searches';

  // Location Caching
  static const String _lastLatKey = 'last_known_lat';
  static const String _lastLngKey = 'last_known_lng';
  final initialCameraPosition = Rxn<CameraPosition>();
  LatLng? _lastFetchLocation;

  // Trip Planning
  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  final sourceLatLng = Rxn<LatLng>();
  final destinationLatLng = Rxn<LatLng>();
  final activeField = 'destination'.obs; // 'source' or 'destination'
  final searchMode = 'trip'.obs; // 'explore' or 'trip'

  // Map
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _googleMapController;
  final isMapReady = false.obs;
  String? _darkMapStyle;

  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  // Hold the selected nearby Charger location marker separately or as part of state
  Marker? _selectedLocationMarker;

  // Cache marker icons to improve performance
  BitmapDescriptor? _iconGreen;
  BitmapDescriptor? _iconOrange;
  BitmapDescriptor? _iconRed;
  BitmapDescriptor? _iconBlue;

  final currentLocation = Rxn<Position>();
  final currentAddress = "Locating...".obs;
  final isLocationGranted = false.obs;

  // Picker State
  final pickerAddress = "Locating...".obs;
  final isPickerLoading = false.obs;

  // UI Controllers
  final PageController pageController = PageController(viewportFraction: 0.85);
  final ScrollController stationScrollController = ScrollController();

  // Sheet Animation Control
  final _sheetAnimationController = StreamController<double>.broadcast();
  Stream<double> get sheetAnimationStream => _sheetAnimationController.stream;
  final currentSheetHeight = 0.28.obs;

  final searchController = TextEditingController();
  final searchResults = <dynamic>[].obs;
  final isSearching = false.obs;
  final searchError = ''.obs;
  Timer? _debounce;

  WebSocketService? _wsService;

  // Selected station for details view
  final selectedStation = Rxn<ChargingStation>();

  // Selected Connector IDs (Multiple Selection)
  final selectedConnectorIds = <String>{}.obs;

  late Razorpay _razorpay;
  // Temp vars for pending session start
  String? _pendingConnectorId;
  double? _pendingAmount;

  void selectConnector(String id) {
    // Single Selection Mode:
    // Clear others when selecting a new one.
    if (selectedConnectorIds.contains(id)) {
      selectedConnectorIds.remove(id); // Toggle off
    } else {
      selectedConnectorIds.clear(); // Ensure only one is selected
      selectedConnectorIds.add(id);
    }
  }

  void initiateCharging() {
    if (selectedConnectorIds.isEmpty) {
      Get.snackbar(
        "Select Connector",
        "Please select a connector to start charging.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final connectorId = selectedConnectorIds.first;

    Get.to(() => ChargingPreparationView(
      connectorId: connectorId,
      homeController: this,
    ));
  }

  Future<void> startChargingSession(String connectorId, double amount) async {
    Get.back(); // Close sheet

    _pendingConnectorId = connectorId;
    _pendingAmount = amount;

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. Initiate Payment Order
      print("Initiating payment for amount: $amount");
      final response = await _apiProvider.post('/charging/initiate-payment', {
        'amount': amount,
      });

      Get.back(); // Close loading dialog
      
      print("Initiate Payment Response: $response");

      if (response['error'] == false) {
        final orderId = response['data']['id'];
        print("Razorpay Order ID: $orderId");
        
        final apiKey =
            "rzp_test_D9PcSutYWQ2e71"; // Replace with env var or constant
            
        if (orderId == null) {
           throw Exception("Order ID is null from backend");
        }

        var options = {
          'key': apiKey,
          'amount': (amount * 100).toInt(),
          'currency': 'INR',
          'name': 'EV Charging',
          'description': 'Charge Session',
          'order_id': orderId,
          'retry': {'enabled': true, 'max_count': 1},
          'send_sms_hash': true,
          'prefill': {
            'contact': '9876543210', // Get from user profile if available
            'email': 'user@example.com', // Get from user profile if available
          },
        };
        
        print("Opening Razorpay with options: $options");

        _razorpay.open(options);
      } else {
        throw Exception(
          response['message'] ?? "Failed to create payment order",
        );
      }
    } catch (e) {
      Get.back(); // Close loading if open
      _handleError(e);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment Successful, Now Start Session
    if (_pendingConnectorId == null || _pendingAmount == null) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final res = await _apiProvider.post('/charging/start', {
        'station_id': selectedStation.value?.chargerId,
        'connector_id': _pendingConnectorId,
        'amount': _pendingAmount,
        'payment_details': {
          'orderId': response.orderId,
          'paymentId': response.paymentId,
          'signature': response.signature,
        },
      });

      Get.back(); // Close loading

      if (res['data'] != null || res['status'] == 'success') {
        final sessionId =
            res['data']?['sessionId'] ??
            res['sessionId'] ??
            "MOCK_SESSION_${DateTime.now().millisecondsSinceEpoch}";

        Get.snackbar(
          "Success",
          "Charging session started successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.off(
          () => ChargingView(
            connectorId: _pendingConnectorId!,
            initialAmount: _pendingAmount!,
            sessionId: sessionId,
          ),
        );
      } else {
        throw Exception(res['message'] ?? "Failed to start session");
      }
    } catch (e) {
      Get.back();
      _handleError(e);
    } finally {
      _pendingConnectorId = null;
      _pendingAmount = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Razorpay Error: Code=${response.code}, Message=${response.message}");
    Get.snackbar(
      "Payment Failed",
      "Error: ${response.code} - ${response.message}",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    _pendingConnectorId = null;
    _pendingAmount = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar("External Wallet", "Wallet: ${response.walletName}");
  }

  void _handleError(dynamic e) {
    print("Error: $e");
    final errorMsg = e.toString();

    // Handle specific errors gracefully
    if (errorMsg.contains("Insufficient wallet balance")) {
      Get.snackbar(
        "Insufficient Balance",
        "Please top up or use online payment.",
      );
    } else if (errorMsg.contains("busy") || errorMsg.contains("in use")) {
      Get.snackbar("Connector Busy", "This connector is currently in use.");
    } else {
      Get.snackbar(
        "Error",
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? lat = prefs.getDouble(_lastLatKey);
      final double? lng = prefs.getDouble(_lastLngKey);

      if (lat != null && lng != null) {
        initialCameraPosition.value = CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        );
        // Optimistically fetch stations for this location without blocking UI
        fetchNearbyStations(lat: lat, lng: lng, silent: true);
      } else {
         initialCameraPosition.value = const CameraPosition(
          target: LatLng(28.6139, 77.2090),
          zoom: 12,
        );
      }
    } catch (e) {
      print("Error loading last known location: $e");
    }
  }

  Future<void> _saveLastLocation(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatKey, lat);
      await prefs.setDouble(_lastLngKey, lng);
    } catch (e) {
      print("Error saving location: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Pre-load map style
    rootBundle.loadString('assets/map_styles/dark_map_style.json').then((style) {
      _darkMapStyle = style;
    }).catchError((error) {
      print("Error loading map style: $error");
    });
    
    // Load last known location immediately
    _loadLastKnownLocation();

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _initializeMarkerIcons();

    // Connect to WebSocket for Live Map Updates
    _connectWebSocket();

    // Listen for manual text clearing
    searchController.addListener(() {
      if (searchController.text.isEmpty && _selectedLocationMarker != null) {
        _selectedLocationMarker = null;
        _updateMarkers();
      }
    });

    // Initialize source with current location when available
    ever(currentAddress, (address) {
      if (sourceController.text.isEmpty ||
          sourceController.text == "Locating...") {
        sourceController.text = address;
      }
    });

    ever(currentLocation, (position) {
      if (position != null && sourceLatLng.value == null) {
        sourceLatLng.value = LatLng(position.latitude, position.longitude);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      loadRecentSearches();
    });
  }

  void _initializeMarkerIcons() async {
    try {
      // Initialize icons once
      _iconGreen = await _createCustomMarkerBitmap(Colors.green);
      _iconOrange = await _createCustomMarkerBitmap(Colors.orange);
      _iconRed = await _createCustomMarkerBitmap(Colors.red);
      _iconBlue = await _createCustomMarkerBitmap(Colors.blue);
    } catch (e) {
      print("Error creating custom markers: $e");
    }

    // Refresh markers once icons are ready (or failed, using defaults)
    _updateMarkers();
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint whitePaint = Paint()..color = Colors.white;

    const double size = 100.0; // Canvas size
    const double radius = 30.0;

    // Draw Pin Shape (Teardrop)
    final Path path = Path();
    path.moveTo(size / 2, size);
    path.quadraticBezierTo(
      size / 2,
      size * 0.75,
      size / 2 - radius,
      size * 0.45,
    );
    path.arcToPoint(
      Offset(size / 2 + radius, size * 0.45),
      radius: const Radius.circular(radius),
      clockwise: true,
    );
    path.quadraticBezierTo(size / 2, size * 0.75, size / 2, size);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black, 4.0, true);

    // Fill
    canvas.drawPath(path, paint);

    // White Circle in center
    canvas.drawCircle(Offset(size / 2, size * 0.45), 12.0, whitePaint);

    // Convert to Image
    final ui.Image img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Recent Searches Logic
  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_recentSearchesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        recentSearches.value = jsonList
            .map((e) => Map<String, String>.from(e))
            .toList();
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
      recentSearches.insert(0, {
        'placeId': placeId,
        'description': description,
      });

      // Limit to 5
      if (recentSearches.length > 5) {
        recentSearches.value = recentSearches.sublist(0, 5);
      }

      await prefs.setString(_recentSearchesKey, json.encode(recentSearches));
    } catch (e) {
      print('Error saving recent nearby Charger: $e');
    }
  }

  @override
  void onClose() {
    _razorpay.clear(); // Clear listeners
    searchController.dispose();
    sourceController.dispose();
    destinationController.dispose();
    _debounce?.cancel();
    _googleMapController?.dispose();
    _googleMapController = null;
    _wsService?.disconnect();
    _sheetAnimationController.close();
    super.onClose();
  }

  void _connectWebSocket() {
    try {
      final sessionController = Get.find<SessionController>();
      final token = sessionController.token.value;
      if (token.isEmpty) return;

      // Using User API Port 3001
      // Replace with your actual IP if testing on real device
      final wsUrl = "ws://192.168.1.9:3001?token=$token";
      _wsService = WebSocketService(wsUrl);

      _wsService?.stream.listen((data) {
        try {
          final decoded = jsonDecode(data.toString());
          final event = decoded['event'];
          final payload = decoded['data'];

          if (event == 'station_status') {
            _handleStationStatusUpdate(payload);
          }
        } catch (e) {
          print("WS Error: $e");
        }
      }, onError: (error) {
        print("WS Connection Error (Stream): $error");
        // Check for Auth Error (simple heuristic)
        if (error.toString().contains("401") || error.toString().toLowerCase().contains("authorized")) {
           Get.find<SessionController>().clearSession();
           Get.offAllNamed('/login');
        }
      });

      _wsService?.connect();
    } catch (e) {
      print("WS Connection Error: $e");
    }
  }

  void _handleStationStatusUpdate(dynamic payload) {
    final chargerId = payload['chargerId'];
    final status = payload['status'];
    final connectorId = payload['connectorId'];

    final index = stations.indexWhere((s) => s.chargerId == chargerId);
    if (index != -1) {
      var station = stations[index];

      if (connectorId == 0) {
        // Main Station Status Update
        station = station.copyWith(status: status);
      } else {
        // Connector Update
        final connectors = List<Connector>.from(station.connectors);
        final cIndex = connectors.indexWhere(
          (c) => c.connectorId == connectorId,
        );
        if (cIndex != -1) {
          connectors[cIndex] = connectors[cIndex].copyWith(status: status);

          // If all connectors are occupied/faulted, update station status?
          // For simplicity, if any connector updates, we might want to refresh UI.
          // The backend handles station status logic (connectorId=0) separately usually,
          // but let's just update the connector list here.
          station = station.copyWith(connectors: connectors);
        }
      }

      stations[index] = station;
      _updateMarkers();

      // If this station is currently selected, update the selection too
      if (selectedStation.value?.chargerId == chargerId) {
        selectedStation.value = station;
      }
    }
  }

  // Wrapper to handle debounce
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchPlaces(query);
    });
  }

  Future<void> scanQrCode() async {
    // Check camera permission
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final result = await Get.to(
        () => const QrScannerView(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 300),
      );
      if (result != null) {
        // Handle scanned code (e.g., connector ID or station ID)
        Get.snackbar("QR Code Scanned", "Code: $result");
        // Logic to find station or connector can be added here
      }
    } else {
      Get.snackbar(
        "Permission Denied",
        "Camera permission is required to scan QR codes.",
      );
    }
  }

  void openSearch({bool focusSource = false, String mode = 'trip'}) {
    searchMode.value = mode;

    // Reset or Initialize
    if (sourceController.text.isEmpty &&
        currentAddress.value != "Locating...") {
      sourceController.text = currentAddress.value;
      if (currentLocation.value != null) {
        sourceLatLng.value = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude,
        );
      }
    }

    // Don't clear destination if we are just editing source in trip mode
    if (!focusSource && mode == 'trip') {
      destinationController.clear();
    }

    // In explore mode, we want a clean slate for the nearby Charger
    if (mode == 'explore') {
      destinationController.clear();
    }

    searchResults.clear();
    activeField.value = focusSource ? 'source' : 'destination';

    Get.to(
      () => const SearchLocationView(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 300),
    );
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    _selectedLocationMarker = null;
    selectedStation.value = null; // Clear selected station

    // Clear trip state
    sourceLatLng.value = null;
    destinationLatLng.value = null;
    polylines.clear();

    _updateMarkers(); // Immediate visual update
    recenterMap();
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        if (response['results'] != null &&
            (response['results'] as List).isNotEmpty) {
          final result = response['results'][0];
          return result['formatted_address'] ?? "Unknown Location";
        }
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Unknown Location";
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    final address = await getAddressFromCoordinates(lat, lng);
    currentAddress.value = address;
  }

  Future<void> updatePickerAddress(LatLng position) async {
    isPickerLoading.value = true;
    pickerAddress.value = "Fetching address...";
    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    pickerAddress.value = address;
    isPickerLoading.value = false;
  }

  Future<void> confirmPickerLocation(LatLng position, String address) async {
    // Logic to handle selection from picker
    Get.back(); // Close picker

    // Determine if we are in Explore Mode or Trip Mode
    if (searchMode.value == 'explore') {
      // In Explore Mode, we want to go all the way back to HomeView
      // Close SearchLocationView as well if it's open
      if (Get.currentRoute == '/SearchLocationView' ||
          Get.previousRoute == '/SearchLocationView') {
        Get.back();
      }

      // Force UI update to ensure we are back at HomeView
      await Future.delayed(const Duration(milliseconds: 100));

      // Clear previous markers
      _selectedLocationMarker = null;

      // Set new marker
      _selectedLocationMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        icon:
            _iconRed ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: "Selected Location", snippet: address),
      );

      currentAddress.value = address; // Update header text

      // Clear old stations
      stations.clear();

      // Clear trip state if switching back to explore
      sourceLatLng.value = null;
      destinationLatLng.value = null;
      polylines.clear();

      _updateMarkers();

      // Wait for navigation and map rebuild to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      _safeAnimateCamera(CameraUpdate.newLatLngZoom(position, 15));
      fetchNearbyStations(lat: position.latitude, lng: position.longitude);
    } else {
      // Trip Mode - We usually want to return to SearchLocationView to see the filled field
      // unless both fields are full, then we plan trip.

      if (activeField.value == 'source') {
        sourceController.text = address;
        sourceLatLng.value = position;
      } else {
        destinationController.text = address;
        destinationLatLng.value = position;
      }

      searchResults.clear();

      // Check if both set
      if (sourceLatLng.value != null && destinationLatLng.value != null) {
        // If both ready, go to Home to show route
        // We need to close SearchLocationView first
        if (Get.currentRoute == '/SearchLocationView' ||
            Get.previousRoute == '/SearchLocationView') {
          Get.back();
        }
        _planTrip();
      } else {
        // Stay on nearby Charger View (already there after closing picker)
        // Just center map preview? But SearchLocationView doesn't have a map.
        // We just updated the text controller.
      }
    }
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

        _getAddressFromLatLng(position.latitude, position.longitude);

        _safeAnimateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );

        fetchNearbyStations(lat: position.latitude, lng: position.longitude);
      } else {
        Get.snackbar(
          "Permission Denied",
          "Location permission is required to center map.",
        );
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

      // Removed country:in restriction to allow broader nearby Charger
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey',
      );

      final response = await _apiProvider.getDirect(
        url,
        timeout: const Duration(seconds: 20),
      );

      print("Google Places API Status: ${response['status']}");

      if (response['status'] == 'OK') {
        searchResults.value = response['predictions'];
      } else if (response['status'] == 'ZERO_RESULTS') {
        searchResults.clear();
      } else {
        print(
          "Google Places API Error: ${response['error_message'] ?? response['status']}",
        );
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

  Future<void> _safeAnimateCamera(CameraUpdate update) async {
    try {
      final controller =
          _googleMapController ?? await _mapControllerCompleter.future;
      await controller.animateCamera(update);
    } catch (e) {
      // Catch all errors, specifically "disposed" ones, and silently fail
      if (e.toString().contains('disposed') ||
          (e is StateError && e.message.contains('disposed'))) {
        return;
      }
      print("Error animating camera: $e");
    }
  }

  Future<void> useCurrentLocation() async {
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // Check permission
    var status = await Permission.location.request();
    if (!status.isGranted) {
      Get.snackbar("Permission Denied", "Location permission is required.");
      return;
    }

    try {
      isLoading.value = true;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);

      // Get address if not already fetched
      String address = "Current Location";
      if (currentAddress.value != "Locating..." &&
          currentAddress.value != "Unknown Location") {
        address = currentAddress.value;
      } else {
        // Trigger reverse geocoding in background
        _getAddressFromLatLng(position.latitude, position.longitude);
      }

      if (searchMode.value == 'explore') {
        Get.back();

        // Clear previous markers/state
        _selectedLocationMarker = null;

        // FORCE Update address from geocoding to ensure accuracy
        currentAddress.value = address;
        if (address == "Current Location") {
          // If geocoding failed/pending, try to reverse geocode now
          _getAddressFromLatLng(latLng.latitude, latLng.longitude);
        }

        // Clear old stations to avoid confusion
        stations.clear();

        _updateMarkers();

        // Wait for navigation and map rebuild to stabilize
        await Future.delayed(const Duration(milliseconds: 500));

        _safeAnimateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        fetchNearbyStations(lat: latLng.latitude, lng: latLng.longitude);
      } else {
        // Trip Mode
        if (activeField.value == 'source') {
          sourceController.text = "Current Location";
          sourceLatLng.value = latLng;
        } else {
          destinationController.text = "Current Location";
          destinationLatLng.value = latLng;
        }

        // Clear results
        searchResults.clear();

        // Check if both set
        if (sourceLatLng.value != null && destinationLatLng.value != null) {
          _planTrip();
        } else {
          _safeAnimateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not get current location");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onPlaceSelected(String placeId, String description) async {
    try {
      // Save to recent searches
      saveRecentSearch(placeId, description);

      // Update the active field text
      if (activeField.value == 'source') {
        sourceController.text = description;
      } else {
        destinationController.text = description;
      }

      searchResults.clear();
      FocusManager.instance.primaryFocus?.unfocus();

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

        // Handle Explore Mode
        if (searchMode.value == 'explore') {
          Get.back();
          isLoading.value = true;

          // Clear trip state
          sourceLatLng.value = null;
          destinationLatLng.value = null;
          polylines.clear();

          currentAddress.value = description;

          // Clear old stations to avoid confusion
          stations.clear();

          // Set Red Marker
          _selectedLocationMarker = Marker(
            markerId: const MarkerId('selected_location'),
            position: latLng,
            icon:
                _iconRed ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: description),
          );
          _updateMarkers();

          // Wait for navigation and map rebuild to stabilize
          await Future.delayed(const Duration(milliseconds: 500));

          _safeAnimateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

          fetchNearbyStations(lat: lat, lng: lng);
          isLoading.value = false;
          return;
        }

        if (activeField.value == 'source') {
          sourceLatLng.value = latLng;
        } else {
          destinationLatLng.value = latLng;
        }

        // Check if both are set to start trip logic
        if (sourceLatLng.value != null && destinationLatLng.value != null) {
          _planTrip();
        } else {
          // If only one is set (e.g. source changed), center on it but don't start trip yet
          _safeAnimateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not fetch place details: $e");
    }
  }

  Future<void> _planTrip() async {
    Get.back(); // Return to map

    // Wait for keyboard to close and navigation transition to finish
    await Future.delayed(const Duration(milliseconds: 300));

    if (sourceLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar("Error", "Source or destination is missing");
      return;
    }

    isLoading.value = true;

    // 1. Fetch Route
    // 2. Fetch Chargers along route
    // For now, let's just move camera to fit bounds and show markers

    try {
      // Handle case where source and destination are the same
      if (sourceLatLng.value == destinationLatLng.value) {
        _safeAnimateCamera(CameraUpdate.newLatLngZoom(sourceLatLng.value!, 15));
      } else {
        LatLngBounds bounds = _boundsFromLatLngList([
          sourceLatLng.value!,
          destinationLatLng.value!,
        ]);
        _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }

      // Update markers to show Source and Dest immediately
      _updateMarkers();

      // Mocking route logic for now - fetch chargers between the two points
      // In a real scenario, we'd use the route polyline.
      // Here we'll just fetch near the midpoint or destination for demo
      fetchNearbyStations(
        lat: destinationLatLng.value!.latitude,
        lng: destinationLatLng.value!.longitude,
      );
    } catch (e) {
      print("Error planning trip: $e");
      Get.snackbar("Error", "Failed to plan trip");
    } finally {
      isLoading.value = false;
    }
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
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
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

        _getAddressFromLatLng(position.latitude, position.longitude);

        // Move camera to user location immediately upon initialization
        _safeAnimateCamera(
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
    _googleMapController = controller;

    // Apply pre-loaded style or load it now if missed
    if (_darkMapStyle != null) {
      _googleMapController?.setMapStyle(_darkMapStyle);
      // Small delay to allow native map to render the style
      Future.delayed(const Duration(milliseconds: 300), () {
        isMapReady.value = true;
      });
    } else {
      rootBundle
          .loadString('assets/map_styles/dark_map_style.json')
          .then((style) {
            _darkMapStyle = style;
            _googleMapController?.setMapStyle(style);
            Future.delayed(const Duration(milliseconds: 300), () {
              isMapReady.value = true;
            });
          })
          .catchError((error) {
            print("Error setting map style: $error");
            isMapReady.value = true; // Show map anyway on error
          });
    }

    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
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

  Future<void> fetchNearbyStations({double? lat, double? lng, bool silent = false}) async {
    // Default to New Delhi if no location provided
    final double latitude = lat ?? 28.6139;
    final double longitude = lng ?? 77.2090;

    // Check distance optimization
    if (_lastFetchLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastFetchLocation!.latitude,
        _lastFetchLocation!.longitude,
        latitude,
        longitude,
      );

      // If moved less than 500 meters and we have stations, force silent refresh
      if (distance < 500 && stations.isNotEmpty) {
        silent = true;
      }
    }

    try {
      if (!silent) isLoading.value = true;

      // Update last known location
      _lastFetchLocation = LatLng(latitude, longitude);
      _saveLastLocation(latitude, longitude);

      final response = await _apiProvider.get(
        '/search/nearby?lat=$latitude&lng=$longitude&radius=100000',
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        // Use compute to parse JSON in background isolate
        stations.value = await compute(_parseStations, data);
        _updateMarkers();
      }
    } catch (e) {
      print('Error fetching stations: $e');

      String message = 'Unable to connect to server';
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        message = 'Server unreachable';
      } else if (e.toString().contains('timed out')) {
        message = 'Connection timed out';
      }

      // Only show snackbar if not silent
      if (!silent) {
        Get.snackbar(
          'Offline Mode',
          '$message. Showing mock data.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          isDismissible: true,
        );
      }

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
        location: Location(
          lat: centerLat + 0.002,
          lng: centerLng + 0.002,
          address: "Connaught Place, New Delhi",
        ),
        status: "online",
        maxPowerKw: 150.0,
        distance: 2.5,
        facilities: ["Cafe", "Restroom", "Shopping"],
        images: [
          "https://example.com/image1.jpg",
          "https://example.com/image2.jpg",
        ],
        vendor: "Tata Power",
        connectors: [
          Connector(
            connectorId: 1,
            status: "Available",
            type: "CCS2",
            maxPowerKw: 150.0,
          ),
          Connector(
            connectorId: 2,
            status: "Charging",
            type: "Type2",
            maxPowerKw: 22.0,
          ),
        ],
      ),
      ChargingStation(
        chargerId: "MOCK-002",
        name: "Cyber City Fast Charge",
        location: Location(
          lat: centerLat - 0.003,
          lng: centerLng + 0.004,
          address: "Cyber City, Gurugram",
        ),
        status: "offline",
        maxPowerKw: 50.0,
        distance: 4.2,
        facilities: ["Restroom"],
        vendor: "EESL",
        connectors: [
          Connector(
            connectorId: 1,
            status: "Faulted",
            type: "CCS2",
            maxPowerKw: 50.0,
          ),
          Connector(
            connectorId: 2,
            status: "Available",
            type: "CCS2",
            maxPowerKw: 50.0,
          ),
        ],
      ),
      ChargingStation(
        chargerId: "MOCK-003",
        name: "Mall of India Station",
        location: Location(
          lat: centerLat + 0.005,
          lng: centerLng - 0.003,
          address: "Sector 18, Noida",
        ),
        status: "online",
        maxPowerKw: 60.0,
        distance: 5.8,
        facilities: ["Mall", "Food Court", "Cinema"],
        vendor: "Statiq",
        connectors: [
          Connector(
            connectorId: 1,
            status: "Available",
            type: "CCS2",
            maxPowerKw: 60.0,
          ),
          Connector(
            connectorId: 2,
            status: "Available",
            type: "CCS2",
            maxPowerKw: 60.0,
          ),
        ],
      ),
    ];
    _updateMarkers();
    Get.snackbar(
      "Demo Mode",
      "Loaded mock stations (Backend unreachable)",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> startNavigation(ChargingStation station) async {
    if (station.location == null) return;

    // 1. Get current location if not available
    if (currentLocation.value == null) {
      await _initializeLocation();
    }

    if (currentLocation.value == null) {
      Get.snackbar("Error", "Current location not available");
      return;
    }

    final start = LatLng(
      currentLocation.value!.latitude,
      currentLocation.value!.longitude,
    );
    final end = LatLng(station.location!.lat, station.location!.lng);

    // Update state to ensure markers are shown
    sourceLatLng.value = start;
    destinationLatLng.value = end;
    _updateMarkers();

    isLoading.value = true;

    try {
      // 2. Fetch Polyline (Mocking for now or use Directions API)
      List<LatLng> polylineCoordinates = await _getPolylineCoordinates(
        start,
        end,
      );

      // 3. Update Polylines State
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: polylineCoordinates,
          color: Colors.blueAccent, // Brighter blue
          width: 6, // Slightly thicker
          zIndex: 1,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
      );
      polylines.refresh();

      // 4. Update Markers (Already handles station markers)
      // We might want to highlight the destination marker

      // 5. Animate Camera to fit bounds
      LatLngBounds bounds = _boundsFromLatLngList(polylineCoordinates);
      _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

      // 6. Collapse sheet to show map
      currentSheetHeight.value = 0.28;
      _sheetAnimationController.add(0.28);
    } catch (e) {
      print("Navigation error: $e");
      Get.snackbar("Error", "Failed to start navigation");
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<LatLng>> _getPolylineCoordinates(LatLng start, LatLng end) async {
    // REAL IMPLEMENTATION using Google Directions API
    // Ensure you have enabled 'Directions API' in Google Cloud Console

    const apiKey = "AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco";
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$apiKey',
    );

    try {
      final response = await _apiProvider.getDirect(url);

      if (response['status'] == 'OK') {
        final routes = response['routes'] as List;
        if (routes.isNotEmpty) {
          final legs = routes[0]['legs'] as List;
          if (legs.isNotEmpty) {
            final steps = legs[0]['steps'] as List;
            List<LatLng> detailedPoints = [];

            // Decode polyline for each step for higher resolution
            for (var step in steps) {
              final points = _decodePolyline(step['polyline']['points']);
              detailedPoints.addAll(points);
            }

            return detailedPoints;
          } else {
            // Fallback to overview if no legs/steps found
            final points = _decodePolyline(
              routes[0]['overview_polyline']['points'],
            );
            return points;
          }
        } else {
          throw Exception("No routes found");
        }
      } else {
        throw Exception(
          "Directions API Error: ${response['status']} - ${response['error_message'] ?? ''}",
        );
      }
    } catch (e) {
      print("Error fetching directions: $e");
      // Fallback to straight line if API fails
      return [start, end];
    }
  }

  // Helper to decode Google Polyline String
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

  void selectStation(ChargingStation station) {
    selectedStation.value = station;

    // Animate camera slightly South (-lat) so the station appears higher on screen (above the sheet)
    // Adjusted offset to -0.005 to center station in the top sliver of screen
    animateToStation(station, offsetLat: -0.005);

    // Animate sheet up to show details (fully expanded)
    // Small delay to allow UI to rebuild with new content before animating
    Future.delayed(const Duration(milliseconds: 50), () {
      currentSheetHeight.value = 0.85;
      _sheetAnimationController.add(0.85);
    });
  }

  void deselectStation() {
    // Capture station before clearing to re-center view
    final station = selectedStation.value;
    selectedStation.value = null;

    // Animate back to center (offset 0)
    if (station != null) {
      animateToStation(station);
    }

    // Animate sheet back down
    // Small delay to ensure controller is stable after content switch
    Future.delayed(const Duration(milliseconds: 50), () {
      currentSheetHeight.value = 0.28;
      _sheetAnimationController.add(0.28);
    });
  }

  void animateToStation(ChargingStation station, {double offsetLat = 0.0}) {
    if (station.location != null) {
      _safeAnimateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              station.location!.lat + offsetLat,
              station.location!.lng,
            ),
            zoom: 16,
          ),
        ),
      );
    }
  }

  Timer? _markerUpdateDebounce;

  void _updateMarkers() {
    // Debounce/Throttle to prevent rapid updates from flooding the map (fixes Flogger logs/GC thrashing)
    // Increased to 300ms to limit updates to ~3fps, allowing map renderer to catch up.
    if (_markerUpdateDebounce?.isActive ?? false) return;

    _markerUpdateDebounce = Timer(const Duration(milliseconds: 300), () {
      _performMarkerUpdate();
    });
  }

  void _performMarkerUpdate() {
    // Create a local set to minimize observable notifications
    final newMarkers = <Marker>{};

    // Re-add selected location marker if it exists
    if (_selectedLocationMarker != null) {
      // Force a unique ID for the selected location if needed,
      // but keeping it constant allows standard updates.
      // We make sure to add it to the set.
      newMarkers.add(_selectedLocationMarker!);
    }

    // Add trip planning markers
    if (sourceLatLng.value != null && destinationLatLng.value != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('source'),
          position: sourceLatLng.value!,
          icon:
              _iconBlue ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "Start"),
          zIndex: 10,
        ),
      );

      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng.value!,
          icon:
              _iconRed ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Destination"),
          zIndex: 10,
        ),
      );
    }

    // Limit to 500 markers to prevent map freeze when radius is large (100km)
    // This assumes markers are somewhat ordered by distance or relevance from backend
    final stationsToRender = stations.length > 500 ? stations.take(500) : stations;

    for (var station in stationsToRender) {
      if (station.location == null) continue;

      final isOnline = station.status.toLowerCase() == 'online';
      final icon = isOnline
          ? (_iconGreen ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ))
          : (_iconOrange ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ));

      newMarkers.add(
        Marker(
          markerId: MarkerId(station.chargerId),
          position: LatLng(station.location!.lat, station.location!.lng),
          icon: icon,
          zIndex: 5,
          onTap: () {
            // Select the station for details view
            selectStation(station);
          },
        ),
      );
    }

    // Only update if marker count changed or significant event to avoid GC thrashing
    // (Equality check on Sets can be expensive, so we just rely on debounce)
    markers.value = newMarkers;
  }
}

// Top-level function for background isolate
List<ChargingStation> _parseStations(List<dynamic> data) {
  return data.map((e) => ChargingStation.fromJson(e)).toList();
}