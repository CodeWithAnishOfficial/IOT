import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewsController extends GetxController {
  final ScrollController scrollController = ScrollController();
  
  // Carousel Control
  final PageController pageController = PageController(viewportFraction: 0.85);
  final currentPage = 0.obs;
  Timer? _carouselTimer;

  // Data
  final featuredNews = <Map<String, dynamic>>[].obs;
  final latestNews = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNews();
    _startAutoScroll();
  }

  @override
  void onClose() {
    _carouselTimer?.cancel();
    pageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (pageController.hasClients && featuredNews.isNotEmpty) {
        int nextPage = currentPage.value + 1;
        if (nextPage >= featuredNews.length) {
          nextPage = 0;
        }
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        currentPage.value = nextPage;
      }
    });
  }

  Future<void> fetchNews() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1)); // Simulate delay

      // Mock Featured News (Carousel)
      featuredNews.assignAll([
        {
          "id": 1,
          "title": "Temperature stable TS vs LFP: Social safe, prompted income response in whole body",
          "category": "Science",
          "image": "assets/images/ev-car-charging-screen-img.png", // Use placeholder or existing asset
          "author": "Dr. Smith",
          "time": "4h ago"
        },
        {
          "id": 2,
          "title": "New Solid State Batteries promise 1000km range",
          "category": "Technology",
          "image": "assets/images/ev-car-charging-screen-img.png",
          "author": "Tech Daily",
          "time": "6h ago"
        },
        {
          "id": 3,
          "title": "EV Sales hit record high in Q1 2024",
          "category": "Business",
          "image": "assets/images/ev-car-charging-screen-img.png",
          "author": "Market Watch",
          "time": "12h ago"
        },
      ]);

      // Mock Latest News (List)
      latestNews.assignAll([
        {
          "id": 4,
          "title": "IND vs AUS: Green top or rank turner?",
          "time": "14m ago",
          "read_time": "3m read",
          "image": "assets/images/logo.png", // Placeholder
        },
        {
          "id": 5,
          "title": "Scream VI Has the Jumps and Star Quality Cast But...",
          "time": "21m ago",
          "read_time": "5m read",
          "image": "assets/images/logo.png",
        },
        {
          "id": 6,
          "title": "Dutch historian finds medieval treasure using metal detector",
          "time": "1h ago",
          "read_time": "4m read",
          "image": "assets/images/logo.png",
        },
        {
          "id": 7,
          "title": "NASA's Artemis II mission to moon announces crew",
          "time": "2h ago",
          "read_time": "6m read",
          "image": "assets/images/logo.png",
        },
        {
          "id": 8,
          "title": "Top 10 EV charging stations in Bangalore",
          "time": "3h ago",
          "read_time": "5m read",
          "image": "assets/images/logo.png",
        },
      ]);

    } catch (e) {
      print("Error fetching news: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }
}
