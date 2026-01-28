import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/app/modules/commercial/controllers/commercial_controller.dart';
import 'package:user_app/app/modules/commercial/views/add_charger_view.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';

class CommercialView extends GetView<CommercialController> {
  const CommercialView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             color: isDark ? Colors.white : Colors.black,
             onPressed: () => Get.back(),
          ),
          title: Text(
            'Commercialization',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha:0.1),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Chargers', icon: Icon(Icons.ev_station)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
              Tab(text: 'Earnings', icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyChargersTab(context),
            _buildAnalyticsTab(context),
            _buildEarningsTab(context),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const AddChargerView()),
          icon: const Icon(Icons.add),
          label: Text("Add Charger", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: isDark ? Colors.white : theme.primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  Widget _buildMyChargersTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => const ShimmerBox(height: 150, width: double.infinity, borderRadius: 20),
        );
      }
      if (controller.myChargers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ev-charger-addcharger-img.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.ev_station_outlined, size: 64, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'No chargers added yet.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: controller.myChargers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final charger = controller.myChargers[index];
          final site = charger['site_id'] is Map ? charger['site_id'] : null;
          final status = charger['status'] ?? 'offline';
          final isOnline = status == 'online' || status == 'charging';

          // Match the "Transaction Card" aesthetic
          final theme = Theme.of(context);


          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.success.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.ev_station,
                        color: isOnline ? AppColors.success : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            charger['name'] ?? 'Charger #${charger['charger_id']}',
                            style: GoogleFonts.poppins(
                              color: theme.textTheme.titleMedium?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${charger['charger_id']}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.success.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: isOnline ? AppColors.success : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (site != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                       Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                       const SizedBox(width: 4),
                       Expanded(
                         child: Text(
                          "${site['name'] ?? ''} - ${site['address'] ?? 'No Address'}",
                          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                ],
                // const SizedBox(height: 12), // Removed Spacer
                // Divider(color: theme.dividerColor.withValues(alpha:0.1)), // Removed Divider
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Connectors', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                         const SizedBox(height: 2),
                         if (charger['connectors'] != null && (charger['connectors'] as List).isNotEmpty)
                           Text('${(charger['connectors'] as List).length} Ports', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14))
                         else
                           Text('0 Ports', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                       ],
                     ),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text('Price', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                         const SizedBox(height: 2),
                         Text('₹${charger['price_per_kwh']}/kWh', 
                            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                       ],
                     ),
                  ],
                )
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: const [
              ShimmerBox(height: 100, width: double.infinity, borderRadius: 20),
              SizedBox(height: 16),
              ShimmerBox(height: 100, width: double.infinity, borderRadius: 20),
              SizedBox(height: 16),
              ShimmerBox(height: 100, width: double.infinity, borderRadius: 20),
            ],
          ),
        );
      }
      final data = controller.analytics;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCard(context, 'Total Earnings', '₹${data['total_earnings'] ?? 0}', Icons.payments, Colors.green),
            _buildStatCard(context, 'Total Sessions', '${data['total_sessions'] ?? 0}', Icons.charging_station, Colors.blue),
            _buildStatCard(context, 'Energy Delivered', '${data['total_energy'] ?? 0} kWh', Icons.flash_on, Colors.orange),
          ],
        ),
      );
    });
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      shape: BoxShape.circle
                  ),
                  child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                  ]
              )
          ],
        )
    );
  }

  Widget _buildEarningsTab(BuildContext context) {
     return Obx(() {
      if (controller.isLoading.value) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => const ShimmerBox(height: 80, width: double.infinity, borderRadius: 20),
        );
      }
      if (controller.walletHistory.isEmpty) {
        return Center(child: Text('No earnings history yet.', style: GoogleFonts.poppins(color: Colors.grey)));
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: controller.walletHistory.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final txn = controller.walletHistory[index];
          final theme = Theme.of(context);


          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.arrow_downward, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings Credit',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        txn['created_at'].toString().split('T')[0],
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+₹${txn['amount']}', 
                  style: GoogleFonts.orbitron(
                    color: Colors.green, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
