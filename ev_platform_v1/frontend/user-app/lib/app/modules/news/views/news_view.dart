import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/widgets/shimmer/shimmer_box.dart';
import '../controllers/news_controller.dart';
import 'news_detail_view.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NewsController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color),
          onPressed: () {}, // Open drawer or menu
        ),
        title: Text(
          'Daily News',
          style: GoogleFonts.merriweather( // Serif font for "Daily News" look
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmerLoading();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Featured Carousel
              if (controller.featuredNews.isNotEmpty) ...[
                SizedBox(
                  height: 240,
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.featuredNews.length,
                    itemBuilder: (context, index) {
                      final news = controller.featuredNews[index];
                      return _buildFeaturedCard(context, news);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                
                // Page Indicator
                Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.featuredNews.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: controller.currentPage.value == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index 
                            ? Colors.blue 
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 24),

              // Latest News Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Latest News",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Latest News List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                itemCount: controller.latestNews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final news = controller.latestNews[index];
                  return _buildNewsListItem(context, news);
                },
              ),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Map<String, dynamic> news) {
    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailView(news: news), transition: Transition.rightToLeft),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10), // Reduced margin for closer carousel items
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Slightly more rounded
          image: DecorationImage(
            image: AssetImage(news['image']),
            fit: BoxFit.cover,
            onError: (_, __) {}, 
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0], // Start gradient lower to keep top clean
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9), // Darker at bottom
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      news['category'] ?? 'News',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    news['title'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsListItem(BuildContext context, Map<String, dynamic> news) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailView(news: news), transition: Transition.rightToLeft),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news['title'],
                    style: GoogleFonts.merriweather( // Serif font for headlines
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        "${news['time']} · ${news['read_time']}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                news['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ShimmerBox(width: double.infinity, height: 240, borderRadius: 20),
        const SizedBox(height: 30),
        const ShimmerBox(width: 150, height: 20, borderRadius: 4),
        const SizedBox(height: 20),
        ...List.generate(5, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 200, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const ShimmerBox(width: 80, height: 80, borderRadius: 12),
            ],
          ),
        )),
      ],
    );
  }
}
