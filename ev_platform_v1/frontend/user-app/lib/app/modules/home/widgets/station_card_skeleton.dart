import 'package:flutter/material.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';

class StationCardSkeleton extends StatelessWidget {
  const StationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Skeleton
          const ShimmerBox(
            width: 100,
            height: 100,
            borderRadius: 16,
          ),
          const SizedBox(width: 16),
          
          // Info Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const ShimmerBox(
                  width: 180,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Address
                const ShimmerBox(
                  width: 120,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 20),
                
                // Bottom Row
                Row(
                  children: [
                    // Status Pill
                    const ShimmerBox(
                      width: 80,
                      height: 24,
                      borderRadius: 6,
                    ),
                    const Spacer(),
                    // Distance & Rating
                    const ShimmerBox(
                      width: 60,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
