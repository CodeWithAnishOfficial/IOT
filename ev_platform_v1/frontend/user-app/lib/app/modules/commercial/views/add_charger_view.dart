import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/app/modules/commercial/controllers/commercial_controller.dart';
import 'package:user_app/app/modules/commercial/views/location_picker_view.dart';

class AddChargerView extends StatefulWidget {
  const AddChargerView({Key? key}) : super(key: key);

  @override
  State<AddChargerView> createState() => _AddChargerViewState();
}

class _AddChargerViewState extends State<AddChargerView> {
  final PageController _pageController = PageController();
  final CommercialController _controller = Get.find<CommercialController>();
  
  int _currentStep = 0;
  final int _totalSteps = 4; // Increased to 4

  // Step 1: Details
  final TextEditingController _chargerIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Step 2: Pricing
  final TextEditingController _priceController = TextEditingController();

  // Step 3: Connectors
  final List<Map<String, dynamic>> _connectors = [
    {'id': 1, 'type': 'Type 2', 'power': '7.4', 'status': 'Available'}
  ];
  final List<String> _connectorTypes = ['Type 2', 'CCS 2', 'CHAdeMO', 'Type 1', 'GB/T', 'Wall Outlet'];

  // Step 4: Location
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _selectedLocation = const LatLng(12.9716, 77.5946); // Default Bangalore
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
    _getAddressFromLatLng(_selectedLocation);

    if (_mapController.future != null) {
       // Only if controller is ready, might not be if we haven't reached that step
       // Actually, we shouldn't await here if the map isn't built yet.
       // The Map creates the controller when built.
    }
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          _getTitleForStep(_currentStep),
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.dividerColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme), // Connectors
                _buildStep4(theme), // Location
              ],
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Back',
                        style: GoogleFonts.poppins(
                          color: theme.disabledColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Obx(() => ElevatedButton(
                    onPressed: _controller.isLoading.value ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _totalSteps - 1 ? 'Finish' : 'Next',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTitleForStep(int step) {
    switch (step) {
      case 0: return 'Charger Details';
      case 1: return 'Set Pricing';
      case 2: return 'Connectors';
      case 3: return 'Location';
      default: return 'Add Charger';
    }
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/ev-charger-addcharger-img.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ev_station, size: 64, color: AppColors.primary),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            theme,
            controller: _chargerIdController,
            label: 'Charger ID / Serial Number',
            icon: Icons.qr_code,
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            theme,
            controller: _nameController,
            label: 'Charger Name',
            icon: Icons.edit,
            hint: 'e.g. My Home Charger',
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Set your selling price',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How much do you want to charge per kWh?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 40),
          
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              prefixText: '₹',
              prefixStyle: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: theme.disabledColor,
              ),
              hintText: '0.00',
              hintStyle: GoogleFonts.poppins(
                color: theme.disabledColor.withOpacity(0.3),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connector Configuration',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the connectors available at your charger.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          
          ..._connectors.asMap().entries.map((entry) {
            int idx = entry.key;
            Map<String, dynamic> connector = entry.value;
            return _buildConnectorCard(theme, idx, connector);
          }).toList(),
          
          const SizedBox(height: 16),
          
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _connectors.add({
                    'id': _connectors.length + 1,
                    'type': 'Type 2',
                    'power': '7.4',
                    'status': 'Available'
                  });
                });
              },
              icon: const Icon(Icons.add),
              label: Text("Add Another Connector", style: GoogleFonts.poppins()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectorCard(ThemeData theme, int index, Map<String, dynamic> connector) {
    return Container(
      key: ValueKey(connector['id']),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connector ${index + 1}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_connectors.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _connectors.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: connector['type'],
            decoration: InputDecoration(
              labelText: 'Connector Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _connectorTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type, style: GoogleFonts.poppins()),
            )).toList(),
            onChanged: (val) {
              setState(() {
                connector['type'] = val;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: connector['power'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Max Power (kW)',
              suffixText: 'kW',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              connector['power'] = val;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(ThemeData theme) {
    return Stack(
      children: [
        Column(
          children: [
             Expanded(
               child: Stack(
                 children: [
                   GoogleMap(
                     initialCameraPosition: CameraPosition(
                       target: _selectedLocation,
                       zoom: 15,
                     ),
                     onMapCreated: (GoogleMapController controller) {
                       if (!_mapController.isCompleted) {
                         _mapController.complete(controller);
                       }
                     },
                     onCameraMove: (CameraPosition position) {
                       _selectedLocation = position.target;
                     },
                     onCameraIdle: () {
                       _getAddressFromLatLng(_selectedLocation);
                     },
                     myLocationEnabled: true,
                     myLocationButtonEnabled: true,
                   ),
                   const Center(
                     child: Padding(
                       padding: EdgeInsets.only(bottom: 40.0),
                       child: Icon(Icons.location_on, size: 50, color: AppColors.primary),
                     ),
                   ),
                 ],
               ),
             ),
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: theme.scaffoldBackgroundColor,
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 10,
                     offset: const Offset(0, -4),
                   ),
                 ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Location Address',
                     style: GoogleFonts.poppins(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     ),
                   ),
                   const SizedBox(height: 12),
                   _buildTextField(
                     theme,
                     controller: _addressController,
                     label: 'Enter Address',
                     icon: Icons.location_on,
                     maxLines: 2,
                   ),
                 ],
               ),
             )
          ],
        ),
        
        // Search Bar Overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                 BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: TextField(
              controller: _searchController,
              readOnly: true,
              onTap: _openLocationPicker,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search Location...',
                icon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      if (_currentStep == 0) {
        if (_chargerIdController.text.isEmpty || _nameController.text.isEmpty) {
          Get.snackbar('Error', 'Please fill in all details');
          return;
        }
      } else if (_currentStep == 1) {
        if (_priceController.text.isEmpty) {
           Get.snackbar('Error', 'Please enter a price');
           return;
        }
      } else if (_currentStep == 2) {
         // Validate connectors
         if (_connectors.isEmpty) {
            Get.snackbar('Error', 'Please add at least one connector');
            return;
         }
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit
      final data = {
        'charger_id': _chargerIdController.text,
        'name': _nameController.text,
        'price_per_kwh': double.tryParse(_priceController.text) ?? 0.0,
        'location': {
          'lat': _selectedLocation.latitude,
          'lng': _selectedLocation.longitude,
          'address': _addressController.text,
        },
        'connectors': _connectors.map((c) => {
          'connector_id': c['id'],
          'type': c['type'],
          'max_power_kw': double.tryParse(c['power'].toString()) ?? 7.4,
          'status': c['status']
        }).toList()
      };
      
      _controller.addCharger(data);
    }
  }

  void _openLocationPicker() async {
    final result = await Get.to(() => const LocationPickerView());
    if (!mounted) return;
    if (result != null && result is Map) {
      final lat = result['lat'];
      final lng = result['lng'];
      final address = result['address'];
      
      setState(() {
        _selectedLocation = LatLng(lat, lng);
        _addressController.text = address ?? '';
        _searchController.text = address ?? '';
      });
      
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
  }
}
