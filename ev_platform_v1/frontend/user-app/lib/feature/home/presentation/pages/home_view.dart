import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/feature/wallet/presentation/pages/wallet_view.dart';
import 'package:user_app/feature/more/presentation/pages/account/presentation/pages/profile_view.dart';
import 'package:user_app/utils/theme/themes.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate pages once to preserve state
    final List<Widget> pages = [
      _buildHomeTab(context),
      const WalletView(),
      const ProfileView(),
    ];

    return Scaffold(
      extendBody: true, // Allow map behind nav bar
      body: Obx(() => IndexedStack(
        index: controller.selectedTab.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: NavigationBar(
            selectedIndex: controller.selectedTab.value,
            onDestinationSelected: controller.changeTab,
            backgroundColor: Colors.white,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return Stack(
      children: [
        // Full Screen Map
        Obx(
          () => GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090), // Default New Delhi
              zoom: 12,
            ),
            onMapCreated: controller.onMapCreated,
            markers: controller.markers,
            myLocationEnabled: controller.isLocationGranted.value,
            myLocationButtonEnabled: false, // Custom button
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        // Search Bar (Trigger)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12, // Reduced top margin
          left: 24, // Increased side margins for smaller width
          right: 24,
          child: GestureDetector(
            onTap: controller.openSearch,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.searchController,
                  builder: (context, value, child) {
                    return Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20), // Smaller icon
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            value.text.isEmpty 
                                ? 'Search charging stations...' 
                                : value.text,
                            style: TextStyle(
                              fontSize: 14, // Smaller font
                              color: value.text.isEmpty 
                                  ? Colors.grey 
                                  : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (value.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () => controller.clearSearch(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                          onPressed: () => _showFilterSheet(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Current Location Button
        Positioned(
          right: 16,
          bottom: 240, // Above station cards
          child: FloatingActionButton(
            heroTag: "myLocation",
            onPressed: () {
              controller.recenterMap();
            },
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Loading Indicator
        Obx(
          () => controller.isLoading.value
              ? Positioned(
                  top: 110,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("Searching area..."),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Station Cards (Floating Horizontal List)
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          height: 180,
          child: Obx(() {
            if (controller.stations.isEmpty) return const SizedBox.shrink();

            return PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              itemCount: controller.stations.length,
              itemBuilder: (context, index) {
                final station = controller.stations[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Show detail modal or page
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        station.name ?? station.chargerId,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                          const Text(
                                            " 4.5",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "• ${station.connectors.length} Plugs",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: station.status == 'online'
                                        ? Colors.green[50]
                                        : Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.electric_bolt,
                                    color: station.status == 'online'
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "0.5 km", // Mock distance
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Text(
                                      "20 min drive",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (station.location != null) {
                                      controller.launchMaps(
                                          station.location!.lat, station.location!.lng);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text("Navigate"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filter Stations",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text("Fast Charging (DC)")),
                Chip(label: Text("Slow Charging (AC)")),
                Chip(label: Text("Available Now")),
                Chip(label: Text("4+ Stars")),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Apply Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
