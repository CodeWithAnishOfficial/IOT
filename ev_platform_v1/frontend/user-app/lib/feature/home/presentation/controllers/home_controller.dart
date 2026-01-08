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
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher import
import 'package:user_app/core/network/api_provider.dart';

import 'package:user_app/feature/home/domain/models/charging_station.dart';
import 'package:user_app/feature/home/domain/models/saved_trip.dart'; // Import SavedTrip
import 'package:user_app/feature/home/presentation/pages/search_location_view.dart';
import 'package:user_app/feature/home/presentation/pages/qr_scanner_view.dart';
import 'package:user_app/feature/charging/presentation/pages/active_session_view.dart';
import 'package:user_app/feature/charging/presentation/pages/charging_preparation_view.dart';
import 'package:user_app/core/Networks/websocket_service.dart';
import 'package:user_app/core/controllers/session_controller.dart';
import 'package:user_app/feature/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

class HomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final stations = <ChargingStation>[].obs;
  final isLoading = false.obs;

  // Recent Searches
  final recentSearches = <Map<String, String>>[].obs;
  static const String _recentSearchesKey = 'recent_searches';

  // Razorpay Keys
  static const String _razorpayKeyId = "rzp_test_D9PcSutYWQ2e71";

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
  final searchMode = 'explore'.obs; // 'explore' or 'trip'

  // Trip Planning State
  final departureSoC = 90.0.obs;
  final arrivalSoC = 0.0.obs; // Calculated
  final tripStops = <ChargingStation>[].obs; // User added stops
  final isItineraryMinimized = false.obs;
  
  final savedTrips = <SavedTrip>[].obs;
  final currentSavedTripId = Rxn<String>(); // Track currently loaded saved trip ID

  void toggleItineraryMinimize() => isItineraryMinimized.toggle();

  // Map
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _googleMapController;
  GoogleMapController? tripMapController;
  final isMapReady = false.obs;
  String? _darkMapStyle;

  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;

  // Trip Map State
  final tripMarkers = <Marker>{}.obs;
  final tripPolylines = <Polyline>{}.obs;

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
  bool _isRequestingPermission = false;

  void showStationDetails(String chargerId) async {
    // 1. Switch to Map Tab (Index 0) if using Dashboard
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeTabIndex(0);
    }
    
    // 2. Find station in local list or fetch it
    ChargingStation? station = stations.firstWhereOrNull((s) => s.chargerId == chargerId);
    
    if (station == null) {
      // Try fetching specific station
      try {
        isLoading.value = true;
        final response = await _apiProvider.get('/stations/$chargerId'); // Assuming endpoint exists
        if (response['data'] != null) {
             station = ChargingStation.fromJson(response['data']);
        }
      } catch (e) {
        print("Error fetching station details: $e");
      } finally {
        isLoading.value = false;
      }
    }
    
    if (station != null) {
       // 3. Center Map
       if (station.location != null && _googleMapController != null) {
          _googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(station.location!.lat, station.location!.lng),
              15,
            ),
          );
       }
       
       // 4. Select Station (triggers sheet)
       selectStation(station);
    } else {
       Get.snackbar("Error", "Station not found");
    }
  }

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

    Get.to(
      () => ChargingPreparationView(
        connectorId: connectorId,
        homeController: this,
      ),
    );
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

        if (orderId == null) {
          throw Exception("Order ID is null from backend");
        }

        var options = {
          'key': _razorpayKeyId,
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

    // Capture values in local variables to avoid race conditions/null checks in async closures
    final String connectorId = _pendingConnectorId!;
    final double amount = _pendingAmount!;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final res = await _apiProvider
          .post('/charging/start', {
            'station_id': selectedStation.value?.chargerId,
            'connector_id': connectorId,
            'amount': amount,
            'payment_details': {
              'orderId': response.orderId,
              'paymentId': response.paymentId,
              'signature': response.signature,
            },
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                "Server is taking too long to respond. Please check charger status.",
              );
            },
          );

      Get.back(); // Close loading

      if (res['data'] != null || res['status'] == 'success') {
        final sessionId =
            (res['data']?['sessionId'] ??
                    res['sessionId'] ??
                    "MOCK_SESSION_${DateTime.now().millisecondsSinceEpoch}")
                .toString();

        Get.snackbar(
          "Success",
          "Charging session started successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.off(
          () => ChargingView(
            connectorId: connectorId,
            initialAmount: amount,
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
    if (e is TimeoutException) {
      Get.snackbar(
        "Request Timed Out",
        "The server failed to respond in time. The charger might be offline.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (errorMsg.contains("Insufficient wallet balance")) {
      Get.snackbar(
        "Insufficient Balance",
        "Please top up or use online payment.",
      );
    } else if (errorMsg.contains("busy") || errorMsg.contains("in use")) {
      Get.snackbar("Connector Busy", "This connector is currently in use.");
    } else if (errorMsg.contains("offline") ||
        errorMsg.contains("not connected")) {
      Get.snackbar(
        "Charger Offline",
        "This charger is currently not connected to the network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

    // Safety timeout: Ensure map loading screen doesn't get stuck forever
    // If map callback doesn't fire within 5 seconds, hide the loader.
    Future.delayed(const Duration(seconds: 5), () {
      if (!isMapReady.value) {
        print("Map initialization timed out, forcing UI to show.");
        isMapReady.value = true;
      }
    });

    // Pre-load map style
    rootBundle
        .loadString('assets/map_styles/dark_map_style.json')
        .then((style) {
          _darkMapStyle = style;
        })
        .catchError((error) {
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
    
    // Auto-update trip markers when stops change
    ever(tripStops, (_) => _updateTripMarkers());

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

    // Initialize Location & Data after a delay to avoid permission conflicts with NotificationService
    Future.delayed(const Duration(seconds: 2), () {
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
      final wsUrl = "ws://192.168.0.58:3001?token=$token";
      _wsService = WebSocketService(wsUrl);

      _wsService?.stream.listen(
        (data) {
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
        },
        onError: (error) {
          print("WS Connection Error (Stream): $error");
          // Check for Auth Error (simple heuristic)
          if (error.toString().contains("401") ||
              error.toString().toLowerCase().contains("authorized")) {
            Get.find<SessionController>().clearSession();
            Get.offAllNamed('/login');
          }
        },
      );

      _wsService?.connect();
    } catch (e) {
      print("WS Connection Error: $e");
    }
  }

  Timer? _wsUpdateBatchTimer;
  final Map<String, dynamic> _pendingStationUpdates = {};

  void _handleStationStatusUpdate(dynamic payload) {
    // Add to pending batch
    _pendingStationUpdates[payload['chargerId']] = payload;

    if (_wsUpdateBatchTimer?.isActive ?? false) return;

    // Flush updates every 1 second to avoid UI thrashing
    _wsUpdateBatchTimer = Timer(
      const Duration(seconds: 1),
      _processPendingUpdates,
    );
  }

  void _processPendingUpdates() {
    if (_pendingStationUpdates.isEmpty) return;

    // Process all pending updates in one go
    final updates = Map<String, dynamic>.from(_pendingStationUpdates);
    _pendingStationUpdates.clear();

    // Create a new list to avoid mutating the RxList repeatedly in loop
    // (though for RxList, efficient modification is tricky, but let's try)
    bool needsMarkerUpdate = false;

    // We can iterate through stations once, or iterate updates.
    // If updates << stations, iterate updates.

    for (var entry in updates.entries) {
      final chargerId = entry.key;
      final payload = entry.value;
      final status = payload['status'];
      final connectorId = payload['connectorId'];

      final index = stations.indexWhere((s) => s.chargerId == chargerId);
      if (index != -1) {
        var station = stations[index];

        if (connectorId == 0) {
          station = station.copyWith(status: status);
        } else {
          final connectors = List<Connector>.from(station.connectors);
          final cIndex = connectors.indexWhere(
            (c) => c.connectorId == connectorId,
          );
          if (cIndex != -1) {
            connectors[cIndex] = connectors[cIndex].copyWith(status: status);
            station = station.copyWith(connectors: connectors);
          }
        }

        stations[index] = station;
        needsMarkerUpdate = true;

        if (selectedStation.value?.chargerId == chargerId) {
          selectedStation.value = station;
        }
      }
    }

    // Trigger marker update once if needed
    if (needsMarkerUpdate) {
      _updateMarkers();
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
    sourceController.clear();
    destinationController.clear();
    searchResults.clear();
    _selectedLocationMarker = null;
    selectedStation.value = null; // Clear selected station
    currentSavedTripId.value = null; // Clear saved trip ID

    // Clear trip state
    sourceLatLng.value = null;
    destinationLatLng.value = null;
    polylines.clear();
    tripPolylines.clear(); // Clear trip polylines
    tripMarkers.clear(); // Clear trip markers
    tripStops.clear(); // Clear trip stops

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
      var status = await Permission.location.status;
      if (!status.isGranted) {
        try {
          status = await Permission.location.request();
        } catch (_) {
          status = await Permission.location.status;
        }
      }

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
      GoogleMapController? controller;
      if (searchMode.value == 'trip' && tripMapController != null) {
        controller = tripMapController;
      } else {
        controller =
            _googleMapController ?? await _mapControllerCompleter.future;
      }

      if (controller != null) {
        await controller.animateCamera(update);
      }
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
    var status = await Permission.location.status;
    if (!status.isGranted) {
      try {
        status = await Permission.location.request();
      } catch (_) {
        status = await Permission.location.status;
      }
    }

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

  Future<void> planTripFromEmbedded() async {
    // Similar to _planTrip but without Get.back() as we are already on the page
    // And assuming inputs are already set in sourceLatLng and destinationLatLng

    // Validate inputs
    if (sourceLatLng.value == null &&
        sourceController.text == "Current Location" &&
        currentLocation.value != null) {
      sourceLatLng.value = LatLng(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
      );
    }

    // Force "Current Location" if it was just text
    if (sourceLatLng.value == null) {
      // Try geocoding sourceController.text if needed, or error
      if (sourceController.text.isNotEmpty &&
          sourceController.text != "Current Location") {
        // Assume user selected something or typed valid address.
        // Realistically, onPlaceSelected should have set sourceLatLng.
        // If manually typed, we need to geocode.
        // For now, let's assume it's set or error.
      }
    }

    if (sourceLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar("Error", "Please select valid locations");
      return;
    }

    isLoading.value = true;

    // Switch to Map View (by closing sheet or changing state)
    // Here we can just execute the route logic and the UI (SearchLocationView)
    // should probably react to `tripPolylines` being populated.
    // Actually, SearchLocationView's _buildTripPlannerLayout shows map IF configured?
    // No, it shows map as background always.

    // We need to dismiss the bottom sheet part of SearchLocationView or minimize it.
    // For now, let's just draw the route.

    await _executeTripPlanning();

    // Calculate approx arrival SoC (Mock logic)
    // Distance / Efficiency
    // E.g. 1% per 2km
    if (tripPolylines.isNotEmpty) {
      // Calculate distance (very rough sum of points)
      // Or get from API response if we stored it
      // Let's just mock it based on straight line * 1.3
      final dist =
          Geolocator.distanceBetween(
            sourceLatLng.value!.latitude,
            sourceLatLng.value!.longitude,
            destinationLatLng.value!.latitude,
            destinationLatLng.value!.longitude,
          ) /
          1000; // km

      final realDist = dist * 1.4; // Road factor
      final consumption = realDist / 3.0; // 3km per %

      double arrival = departureSoC.value - consumption;
      if (arrival < 0) arrival = 0;
      arrivalSoC.value = arrival;
    }
  }

  Future<void> _planTrip() async {
    Get.back(); // Return to map
    await Future.delayed(const Duration(milliseconds: 300));
    await _executeTripPlanning();
  }

  Future<void> _executeTripPlanning() async {
    if (sourceLatLng.value == null || destinationLatLng.value == null) return;

    isLoading.value = true;

    try {
      // 1. Fetch Route using Directions API
      final routePoints = await _getPolylineCoordinates(
        sourceLatLng.value!,
        destinationLatLng.value!,
      );

      // 2. Animate Camera to fit bounds
      if (routePoints.isNotEmpty) {
        LatLngBounds bounds = _boundsFromLatLngList(routePoints);
        _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }

      // 3. Update Markers (Source/Dest)
      _updateTripMarkers();

      // 4. Add Polyline (Corridor Style)
      tripPolylines.clear();
      if (routePoints.isNotEmpty) {
        // Outer Corridor (Wide Semi-Transparent Reddish)
        tripPolylines.add(
          Polyline(
            polylineId: const PolylineId("trip_corridor"),
            points: routePoints,
            color: AppTheme.primaryColor.withOpacity(
              0.2,
            ), // Primary theme corridor
            width: 20, // Wide
            zIndex: 1,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        );

        // Inner Route (Primary Theme Color)
        tripPolylines.add(
          Polyline(
            polylineId: const PolylineId("trip_route"),
            points: routePoints,
            color: AppTheme.primaryColor, // Use brand color (Fluorescent)
            width: 5,
            zIndex: 2,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        );
      }

      // Fetch chargers along route (1km buffer)
      await fetchRouteStations(routePoints);
    } catch (e) {
      print("Error planning trip: $e");
      Get.snackbar("Error", "Failed to plan trip");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRouteStations(List<LatLng> routePoints) async {
    // Simplify route points if too many (simple step sampling)
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
    // Ensure last point is included
    if (routePoints.isNotEmpty) {
      pointsPayload.add({
        'lat': routePoints.last.latitude,
        'lng': routePoints.last.longitude,
      });
    }

    try {
      final response = await _apiProvider.post('/search/route', {
        'routePoints': pointsPayload,
        'bufferDistance': 1000, // 1km buffer
      });

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        stations.value = await compute(_parseStations, data);

        // Update markers (both map views)
        _updateMarkers();
        if (searchMode.value == 'trip') {
          _updateTripMarkers();
        }
      }
    } catch (e) {
      print("Error fetching route stations: $e");
      // Fallback
      fetchNearbyStations(
        lat: destinationLatLng.value?.latitude,
        lng: destinationLatLng.value?.longitude,
        radius: 50000,
        silent: true,
      );
    }
  }

  Future<void> fetchSavedTrips() async {
    try {
      final res = await _apiProvider.get('/saved-trips');
      if (res['error'] == false) {
        final list = (res['data'] as List).map((e) => SavedTrip.fromJson(e)).toList();
        savedTrips.assignAll(list);
      }
    } catch (e) {
      print("Fetch Saved Trips Error: $e");
    }
  }

  Future<void> saveCurrentTrip(String name) async {
     if (sourceLatLng.value == null || destinationLatLng.value == null) {
       Get.snackbar("Error", "Source and Destination required");
       return;
     }
     
     final stopsData = tripStops.map((s) => TripStop(
         chargerId: s.chargerId,
         name: s.name,
         address: s.location?.address,
         location: TripLocation(
             address: s.location?.address ?? '',
             lat: s.location!.lat,
             lng: s.location!.lng,
         ),
     )).toList();

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

     try {
         final res = await _apiProvider.post('/saved-trips', body);
         if (res['error'] == false) {
             Get.snackbar("Success", "Trip saved successfully!", backgroundColor: Colors.green, colorText: Colors.white);
             fetchSavedTrips();
         } else {
             Get.snackbar("Error", res['message'] ?? "Failed to save trip", backgroundColor: Colors.red, colorText: Colors.white);
         }
     } catch (e) {
         print("Save Trip Error: $e");
         Get.snackbar("Error", "Failed to save trip");
     }
  }
  
  void deleteSavedTrip(String id) async {
    try {
      final res = await _apiProvider.delete('/saved-trips/$id');
      if (res['error'] == false) {
        Get.snackbar("Success", "Trip deleted successfully!", backgroundColor: Colors.green, colorText: Colors.white);
        fetchSavedTrips(); // Refresh list
      } else {
        Get.snackbar("Error", res['message'] ?? "Failed to delete trip", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("Delete Trip Error: $e");
      Get.snackbar("Error", "Failed to delete trip");
    }
  }

  void loadSavedTrip(SavedTrip trip) {
     currentSavedTripId.value = trip.id; // Set ID
     sourceController.text = trip.source.address;
     sourceLatLng.value = LatLng(trip.source.lat, trip.source.lng);
     
     destinationController.text = trip.destination.address;
     destinationLatLng.value = LatLng(trip.destination.lat, trip.destination.lng);
     
     tripStops.clear();
     
     // Correct mapping for ChargingStation constructor
     final mappedStations = trip.stops.map((s) {
        return ChargingStation(
           chargerId: s.chargerId ?? 'unknown',
           name: s.name,
           location: Location(
               lat: s.location.lat, 
               lng: s.location.lng, 
               address: s.location.address
           ),
           status: 'Unknown',
           maxPowerKw: 0,
           connectors: [],
        );
     }).toList();
     
     tripStops.assignAll(mappedStations);
     
     // Switch to trip mode
     searchMode.value = 'trip';
     Get.to(
       () => const SearchLocationView(
         isEmbedded: true, 
         showBackButton: true,
         isSavedTripMode: true,
       ),
       arguments: {'fromSaved': true},
     );
     
     // Trigger route calculation
     _executeTripPlanning();
  }

  void _updateTripMarkers() {
    final newMarkers = <Marker>{};

    // Add all fetched stations (available chargers along route)
    for (var station in stations) {
      if (station.location == null) continue;

      // Skip if this station is already in tripStops (to avoid Z-fighting)
      if (tripStops.any((s) => s.chargerId == station.chargerId)) continue;

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
          markerId: MarkerId("trip_${station.chargerId}"),
          position: LatLng(station.location!.lat, station.location!.lng),
          icon: icon,
          zIndex: 5,
          onTap: () => selectStation(station),
        ),
      );
    }

    if (sourceLatLng.value != null) {
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
    }

    if (destinationLatLng.value != null) {
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

    // Add numbered markers for stops
    _addStopMarkers(newMarkers);

    tripMarkers.value = newMarkers;
  }

  Future<void> _addStopMarkers(Set<Marker> markers) async {
    for (int i = 0; i < tripStops.length; i++) {
      final stop = tripStops[i];
      if (stop.location == null) continue;

      final icon = await _createNumberedMarkerBitmap(i + 1);

      markers.add(
        Marker(
          markerId: MarkerId("stop_${stop.chargerId}"),
          position: LatLng(stop.location!.lat, stop.location!.lng),
          icon: icon,
          zIndex: 15,
          infoWindow: InfoWindow(title: stop.name ?? "Stop ${i + 1}"),
          onTap: () => selectStation(stop),
        ),
      );
    }

    // Update state to trigger redraw
    tripMarkers.refresh();
  }

  Future<BitmapDescriptor> _createNumberedMarkerBitmap(int number) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100.0;

    // Paint for the circle background
    final Paint circlePaint = Paint()
      ..color = Colors
          .deepOrange // Use brand color
      ..style = PaintingStyle.fill;

    // Shadow
    canvas.drawCircle(
      const Offset(size / 2 + 2.0, size / 2 + 4.0),
      size / 2,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Draw Circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, circlePaint);

    // Add Border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);

    // Text Painter
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 50.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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
    if (_isRequestingPermission) return;
    isLoading.value = true;
    try {
      _isRequestingPermission = true;
      var status = await Permission.location.status;

      if (!status.isGranted) {
        try {
          status = await Permission.location.request();
        } catch (e) {
          // Ignore if permission request is already running
          print("Permission request error: $e");
          // Re-check status in case another request finished and granted it
          status = await Permission.location.status;
        }
      }

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
    } finally {
      _isRequestingPermission = false;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;

    // Apply pre-loaded style or load it now if missed
    if (_darkMapStyle != null) {
      _googleMapController?.setMapStyle(_darkMapStyle);
      // Increased delay to 2 seconds to ensure grid is hidden even on slow connections
      Future.delayed(const Duration(seconds: 2), () {
        isMapReady.value = true;
      });
    } else {
      rootBundle
          .loadString('assets/map_styles/dark_map_style.json')
          .then((style) {
            _darkMapStyle = style;
            _googleMapController?.setMapStyle(style);
            Future.delayed(const Duration(seconds: 2), () {
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

  void onTripMapCreated(GoogleMapController controller) {
    tripMapController = controller;
    if (_darkMapStyle != null) {
      tripMapController?.setMapStyle(_darkMapStyle);
    }
  }

  Future<void> fetchNearbyStations({
    double? lat,
    double? lng,
    double? radius,
    bool silent = false,
  }) async {
    // Default to New Delhi if no location provided
    final double latitude = lat ?? 28.6139;
    final double longitude = lng ?? 77.2090;
    final double searchRadius = radius ?? 100000;

    // Check distance optimization
    if (_lastFetchLocation != null && radius == null) {
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

      // Update last known location (only if not a custom radius search which might be for trip planning)
      if (radius == null) {
        _lastFetchLocation = LatLng(latitude, longitude);
        _saveLastLocation(latitude, longitude);
      }

      final response = await _apiProvider.get(
        '/search/nearby?lat=$latitude&lng=$longitude&radius=$searchRadius',
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        // Use compute to parse JSON in background isolate
        stations.value = await compute(_parseStations, data);
        _updateMarkers();

        // Update Trip Markers if in Trip Mode
        if (searchMode.value == 'trip') {
          _updateTripMarkers();
        }
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
      } else if (response['status'] == 'ZERO_RESULTS') {
        print("Directions API: No route found (ZERO_RESULTS)");
        Get.snackbar(
          "No Route Found",
          "Cannot drive between these locations.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return [start, end]; // Fallback to straight line
      } else {
        print("Directions API Error: ${response['status']}");
        // Only throw for actual errors, not expected states
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

  Future<void> launchGoogleMapsNavigation() async {
    if (sourceLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar("Error", "Source or destination not set");
      return;
    }

    final source =
        "${sourceLatLng.value!.latitude},${sourceLatLng.value!.longitude}";
    final dest =
        "${destinationLatLng.value!.latitude},${destinationLatLng.value!.longitude}";

    // Construct Waypoints
    // Format: lat,lng|lat,lng|...
    String waypoints = "";
    if (tripStops.isNotEmpty) {
      waypoints = tripStops
          .where((s) => s.location != null)
          .map((s) => "${s.location!.lat},${s.location!.lng}")
          .join("|");
    }

    // Google Maps URL Scheme
    // api=1 ensures cross-platform compatibility
    // waypoints param adds stops
    // travelmode=driving

    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=$source&destination=$dest&waypoints=$waypoints&travelmode=driving",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not launch Google Maps");
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

    // Re-add selected location marker if it exists (For Explore Mode)
    if (_selectedLocationMarker != null) {
      newMarkers.add(_selectedLocationMarker!);
    }

    // We do NOT add source/dest markers to Main Home Map anymore,
    // unless we want them to appear there? User wants them separated.
    // So "trip planning markers" (source/dest) should only be in _updateTripMarkers.

    // Limit to 500 markers to prevent map freeze when radius is large (100km)
    // This assumes markers are somewhat ordered by distance or relevance from backend
    final stationsToRender = stations.length > 500
        ? stations.take(500)
        : stations;

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

    // Also update trip markers if we have stations, to keep them in sync
    if (searchMode.value == 'trip') {
      _updateTripMarkers();
    }
  }
}

// Top-level function for background isolate
List<ChargingStation> _parseStations(List<dynamic> data) {
  return data.map((e) => ChargingStation.fromJson(e)).toList();
}
