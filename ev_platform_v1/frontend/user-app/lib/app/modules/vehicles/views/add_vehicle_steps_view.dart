import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/app/modules/vehicles/controllers/vehicles_controller.dart';

class AddVehicleStepsView extends StatefulWidget {
  final Map<String, String> selectedCar;

  const AddVehicleStepsView({super.key, required this.selectedCar});

  @override
  State<AddVehicleStepsView> createState() => _AddVehicleStepsViewState();
}

class _AddVehicleStepsViewState extends State<AddVehicleStepsView> {
  final PageController _pageController = PageController();
  final VehiclesController _controller = Get.find<VehiclesController>();
  
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form Data
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  String _selectedConnector = 'Type2';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'Add Vehicle',
          style: GoogleFonts.poppins(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 24,
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

          // Selected Car Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  alignment: Alignment.center,
                  child: widget.selectedCar['image'] != null
                      ? Image.asset(
                          widget.selectedCar['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_car_filled_rounded,
                              size: 120,
                              color: AppColors.primary,
                            );
                          },
                        )
                      : Icon(
                          Icons.directions_car_filled_rounded,
                          size: 120,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.selectedCar['make']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.disabledColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.selectedCar['model']!,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
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
                _buildStep3(theme),
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

  void _handleNext() {
    if (_currentStep == 0) {
      if (_yearController.text.isEmpty) {
        Get.snackbar('Required', 'Please enter the vehicle year');
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
       // Plate is optional or required? Let's assume optional as per previous code
       _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit
      _submitVehicle();
    }
  }

  Future<void> _submitVehicle() async {
    // Add vehicle via controller
    await _controller.addVehicle({
      'make': widget.selectedCar['make'],
      'modelName': widget.selectedCar['model'],
      'year': int.parse(_yearController.text),
      'plate_no': _plateController.text,
      'connector_type': _selectedConnector,
      'is_default': false,
    });
    
    // Close the wizard and selection screen (2 levels)
    Get.close(2); 
  }

  Widget _buildStep1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What year is this car?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'YYYY',
              hintStyle: GoogleFonts.poppins(
                color: theme.disabledColor.withOpacity(0.3),
                letterSpacing: 2,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Vehicle Registration Number',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(Optional)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'ABC-1234',
                hintStyle: GoogleFonts.poppins(
                  color: theme.disabledColor.withOpacity(0.3),
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    final connectors = ['Type2', 'CCS2', 'Chademo', 'GB/T'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Select Connector Type',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: connectors.length,
              itemBuilder: (context, index) {
                final type = connectors[index];
                final isSelected = _selectedConnector == type;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedConnector = type;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.electrical_services_rounded,
                          size: 32,
                          color: isSelected ? Colors.white : theme.iconTheme.color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
