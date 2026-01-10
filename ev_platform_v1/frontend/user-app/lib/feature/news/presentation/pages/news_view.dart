import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/utils/theme/themes.dart';
import 'package:user_app/utils/widgets/shimmer/shimmer_box.dart';
import '../controllers/news_controller.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NewsController());
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: NestedScrollView(
        controller: controller.scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            floating: true,
            pinned: false,
            snap: true,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Text(
                  'Quan EV Buzz',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset('assets/images/logo.png', height: 28),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTopNavItem(Icons.explore_outlined, "Discover", true),
                    _buildTopNavItem(Icons.bookmark_border, "Saved", false),
                    _buildTopNavItem(Icons.schedule, "Events", false),
                    _buildTopNavItem(Icons.people_outline, "Community", false),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(topPadding: topPadding),
          ),
        ],
        body: Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerList();
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: controller.posts.length + (controller.hasMore.value ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == controller.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                );
              }
              return _buildPostCard(controller.posts[index]);
            },
          );
        }),
      ),
    );
  }

  Widget _buildTopNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : const Color(0xFF1E1E1E),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.white10,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 300, borderRadius: 16),
          const SizedBox(height: 12),
          const ShimmerBox(width: 150, height: 14, borderRadius: 4),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
          const SizedBox(height: 4),
          const ShimmerBox(width: 200, height: 14, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post["username"],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ],
                  ),
                  Text(
                    post["time"],
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Image Content
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Mock Image Gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: post["image_gradient"] as List<Color>,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid Pattern Overlay
                      Opacity(
                        opacity: 0.1,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: GridPainter(),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.electric_car,
                          size: 100,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Overlay Text
                Center(
                  child: Text(
                    post["headline"],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 3,
                      height: 1.2,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Tag
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "Trending in EV",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _buildActionButton(Icons.favorite_border, "${post['likes']}"),
              const SizedBox(width: 16),
              _buildActionButton(Icons.chat_bubble_outline, "${post['comments']}"),
              const SizedBox(width: 16),
              _buildActionButton(Icons.send_outlined, ""),
              const Spacer(),
              _buildActionButton(Icons.bookmark_border, ""),
            ],
          ),
        ),

        // Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              children: [
                TextSpan(
                  text: "${post['username']} ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: post['caption'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;

  _SearchBarDelegate({required this.topPadding});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121212),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search topics, news...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, color: Colors.white70, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 55 + 20 + topPadding;

  @override
  double get minExtent => 55 + 20 + topPadding;

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}
