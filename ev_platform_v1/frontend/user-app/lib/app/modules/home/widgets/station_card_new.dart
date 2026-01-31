import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/home/domain/models/charger.dart';
import 'package:user_app/core/theme/app_colors.dart';

class StationCard extends StatelessWidget {
  final Charger station;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;

  const StationCard({
    super.key,
    required this.station,
    this.onTap,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final status = station.status.toLowerCase();
    final isOnline = status == 'online';
    final isCharging = status == 'charging' || status == 'busy' || status == 'occupied';
    
    Color statusColor = AppColors.error;
    String statusText = "Unavailable";

    if (isOnline) {
      statusColor = AppColors.success;
      statusText = "Available";
    } else if (isCharging) {
      statusColor = Colors.orange;
      statusText = "Busy";
    } else {
        // Offline or Faulted
        statusColor = Colors.grey;
        statusText = "Offline";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Section
              Padding(
                padding: const EdgeInsets.only(top: 8.0), // Move image down slightly
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: station.images.isNotEmpty
                        ? Image.network(
                            station.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 2. Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      station.name ?? "Unknown Station",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.vendor ?? "Public Charger",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          "${station.distance?.toStringAsFixed(1) ?? '--'} km", // Distance
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Navigation Button (Floating Bottom Right)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   const SizedBox(height: 50), // Spacer to push button down
                   InkWell(
                     onTap: onNavigate,
                     child: Container(
                       width: 48,
                       height: 48,
                       decoration: const BoxDecoration(
                         color: AppColors.primary,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(
                         Icons.directions,
                         color: Colors.white,
                         size: 24,
                       ),
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Image.asset(
      "assets/images/ev-charger-addcharger-img.png",
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          Icons.ev_station,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
