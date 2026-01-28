import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/app/modules/vehicles/views/add_vehicle_steps_view.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';

class SelectCarView extends StatefulWidget {
  const SelectCarView({super.key});

  @override
  State<SelectCarView> createState() => _SelectCarViewState();
}

class _SelectCarViewState extends State<SelectCarView> {
  final TextEditingController searchController = TextEditingController();
  String _selectedMake = 'All';
  bool _isLoading = true;
  
  // Mock Data
  final List<Map<String, String>> allCars = [
    {'make': 'Tesla', 'model': 'Model 3', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Tesla', 'model': 'Model Y', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Tesla', 'model': 'Model S', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Hyundai', 'model': 'Ioniq 5', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Hyundai', 'model': 'Kona Electric', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Kia', 'model': 'EV6', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Kia', 'model': 'Niro EV', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Ford', 'model': 'Mustang Mach-E', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Volkswagen', 'model': 'ID.4', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Nissan', 'model': 'Leaf', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'BMW', 'model': 'i4', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Audi', 'model': 'e-tron GT', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Porsche', 'model': 'Taycan', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'Tata', 'model': 'Nexon EV', 'image': 'assets/images/ev-car-charging-screen-img.png'},
    {'make': 'MG', 'model': 'ZS EV', 'image': 'assets/images/ev-car-charging-screen-img.png'},
  ];

  List<Map<String, String>> filteredCars = [];

  @override
  void initState() {
    super.initState();
    filteredCars = allCars;
    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _filterCars() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredCars = allCars.where((car) {
        final make = car['make']!;
        final matchesSearch = make.toLowerCase().contains(query) || 
                            car['model']!.toLowerCase().contains(query);
        final matchesMake = _selectedMake == 'All' || make == _selectedMake;
        return matchesSearch && matchesMake;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Extract unique makes
    final makes = ['All', ...{...allCars.map((c) => c['make']!)}.toList()];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Select Your EV',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                controller: searchController,
                onChanged: (_) => _filterCars(),
                style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Search brand or model...',
                  hintStyle: GoogleFonts.poppins(color: theme.disabledColor),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: theme.disabledColor),
                ),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: makes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final make = makes[index];
                final isSelected = _selectedMake == make;
                return ChoiceChip(
                  label: Text(
                    make,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMake = make;
                      });
                      _filterCars();
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),

          // Car List (Grid)
          Expanded(
            child: _isLoading 
                ? _buildShimmerGrid(context)
                : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredCars.length,
              itemBuilder: (context, index) {
                final car = filteredCars[index];
                return _buildCarCard(context, car);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 9, // Show a few shimmer items
      itemBuilder: (context, index) {
        return _buildShimmerItem(context);
      },
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(
            width: 48, 
            height: 48, 
            borderRadius: 24,
            baseColor: isDark ? Colors.white10 : Colors.grey[200],
            highlightColor: isDark ? Colors.white24 : Colors.grey[100],
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: 60, 
            height: 10,
            baseColor: isDark ? Colors.white10 : Colors.grey[200],
            highlightColor: isDark ? Colors.white24 : Colors.grey[100],
          ),
          const SizedBox(height: 6),
          ShimmerBox(
            width: 80, 
            height: 12,
            baseColor: isDark ? Colors.white10 : Colors.grey[200],
            highlightColor: isDark ? Colors.white24 : Colors.grey[100],
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Map<String, String> car) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(() => AddVehicleStepsView(selectedCar: car));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Car Image
                Container(
                  width: 80,
                  height: 60,
                  alignment: Alignment.center,
                  child: Image.asset(
                    car['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.directions_car_filled_rounded,
                        color: AppColors.primary,
                        size: 32,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  car['make']!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: theme.disabledColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  car['model']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
