import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/home/domain/models/charging_station.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

class StationDetailSheet extends StatelessWidget {
  final ChargingStation station;
  final ScrollController scrollController;
  final HomeController controller;

  const StationDetailSheet({
    super.key,
    required this.station,
    required this.scrollController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = station.status.toLowerCase() == 'online';
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content List
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                // 1. Header Image
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                       station.images.isNotEmpty
                          ? Image.network(
                              station.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                 return Container(
                                   color: Colors.grey[100],
                                   child: Center(
                                     child: Icon(Icons.ev_station_rounded, size: 80, color: Colors.grey[300]),
                                   ),
                                 );
                              },
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(Icons.ev_station_rounded, size: 80, color: Colors.grey[300]),
                              ),
                            ),
                    ],
                  ),
                ),

                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100), // Bottom padding for sticky button
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Title & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name ?? "Unknown Station",
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  station.location?.address ?? "Address not available",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isOnline ? Icons.check_circle : Icons.error_outline,
                                  size: 20,
                                  color: isOnline ? Colors.green : Colors.red,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOnline ? "Online" : "Offline",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOnline ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutlineAction(
                              icon: Icons.directions_outlined,
                              label: "Directions",
                              onTap: () => controller.startNavigation(station),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOutlineAction(
                              icon: Icons.share_outlined,
                              label: "Share",
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOutlineAction(
                              icon: Icons.bookmark_border,
                              label: "Save",
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Divider(thickness: 0.5, color: Colors.grey.shade200),
                      const SizedBox(height: 20),

                      // 4. Connectors Section
                      Row(
                        children: [
                          Icon(Icons.ev_station, size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            "Connectors (${station.connectors.length})",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                           Text(
                            "${station.connectors.where((c) => c.status.toLowerCase() == 'available').length} Available",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() => Column(
                        children: station.connectors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final c = entry.value;
                          // Use connectorId if available, otherwise fallback to index-based ID
                          final String uniqueId = c.connectorId?.toString() ?? "idx_$index";
                          
                          return _buildConnectorCard(
                            c, 
                            isSelected: controller.selectedConnectorIds.contains(uniqueId),
                            onTap: () => controller.selectConnector(uniqueId),
                          );
                        }).toList(),
                      )),

                      const SizedBox(height: 24),

                      // 5. Amenities Section
                      if (station.facilities.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 20, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              "Amenities",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: station.facilities.map((f) => _buildAmenityChip(f)).toList(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close Button (Floating)
          Positioned(
            top: 16,
            right: 16,
            child: InkWell(
              onTap: controller.deselectStation,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.black87, size: 22),
              ),
            ),
          ),
          
          // Sticky Bottom Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                     controller.initiateCharging();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 24),
                  label: const Text(
                    "Start Charging",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorCard(Connector connector, {bool isSelected = false, VoidCallback? onTap}) {
    final statusLower = connector.status.toLowerCase();
    
    String statusText;
    Color statusColor;
    Color bgColor;

    if (statusLower == 'available') {
      statusText = "Available";
      statusColor = Colors.green[700]!;
      bgColor = Colors.green.withOpacity(0.1);
    } else if (statusLower == 'faulted' || statusLower == 'unavailable' || statusLower == 'offline') {
      statusText = "Faulted"; // Or "Unavailable" if preferred
      statusColor = Colors.red[700]!;
      bgColor = Colors.red.withOpacity(0.1);
    } else {
      statusText = "In Use";
      statusColor = Colors.orange[800]!;
      bgColor = Colors.orange.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
              ),
              child: Icon(
                Icons.electrical_services_rounded, 
                color: isSelected ? Colors.green : Colors.blue[700], 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connector.type ?? "Type 2",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "${connector.maxPowerKw.toInt()} kW • Fast",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String name) {
    IconData icon;
    switch (name.toLowerCase()) {
      case 'cafe':
      case 'coffee':
        icon = Icons.coffee_rounded;
        break;
      case 'restroom':
      case 'washroom':
        icon = Icons.wc_rounded;
        break;
      case 'shopping':
      case 'mall':
        icon = Icons.shopping_bag_rounded;
        break;
      case 'food':
      case 'restaurant':
        icon = Icons.restaurant_rounded;
        break;
      case 'wifi':
        icon = Icons.wifi_rounded;
        break;
      case 'parking':
        icon = Icons.local_parking_rounded;
        break;
      default:
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
