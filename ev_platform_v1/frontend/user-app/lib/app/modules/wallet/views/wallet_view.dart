import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_app/app/modules/wallet/domain/models/wallet_transaction.dart';
import 'package:user_app/app/modules/wallet/views/transaction_detail_view.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildShimmerItem(context),
          );
        }
        
        if (controller.transactions.isEmpty) {
             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found', 
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white54 : Colors.black54, 
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
             );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: controller.transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final transaction = controller.transactions[index];
            return _buildTransactionCard(context, transaction);
          },
        );
      }),
    );
  }

  Widget _buildTransactionCard(BuildContext context, PaymentTransaction transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Get.to(() => TransactionDetailView(transaction: transaction)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: theme.iconTheme.color,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.method,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(transaction.date),
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.orbitron(
                    color: transaction.status ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.status 
                        ? AppColors.success.withOpacity(0.1) 
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      transaction.status ? 'Success' : 'Failed',
                      style: GoogleFonts.poppins(
                          color: transaction.status ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                      ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Icon Shimmer
          ShimmerBox(
            width: 48,
            height: 48,
            borderRadius: 16,
            baseColor: isDark ? Colors.white10 : Colors.grey[200],
            highlightColor: isDark ? Colors.white24 : Colors.grey[100],
          ),
          
          const SizedBox(width: 16),
          
          // Info Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 16,
                  baseColor: isDark ? Colors.white10 : Colors.grey[200],
                  highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: 100,
                  height: 12,
                  baseColor: isDark ? Colors.white10 : Colors.grey[200],
                  highlightColor: isDark ? Colors.white24 : Colors.grey[100],
                ),
              ],
            ),
          ),
          
          // Amount & Status Shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerBox(
                width: 80,
                height: 20,
                baseColor: isDark ? Colors.white10 : Colors.grey[200],
                highlightColor: isDark ? Colors.white24 : Colors.grey[100],
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: 60,
                height: 14,
                borderRadius: 4,
                baseColor: isDark ? Colors.white10 : Colors.grey[200],
                highlightColor: isDark ? Colors.white24 : Colors.grey[100],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
