import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewsController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final posts = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  
  int _page = 1;
  final int _limit = 5;

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isMoreLoading.value && hasMore.value) {
        loadMorePosts();
      }
    }
  }

  Future<void> fetchPosts() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      
      // Mock Data
      final newPosts = List.generate(_limit, (index) => _generateMockPost(index));
      posts.assignAll(newPosts);
      
      _page++;
    } catch (e) {
      print("Error fetching posts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    try {
      isMoreLoading.value = true;
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // Mock Data
      final newPosts = List.generate(_limit, (index) => _generateMockPost(posts.length + index));
      
      if (newPosts.isEmpty) {
        hasMore.value = false;
      } else {
        posts.addAll(newPosts);
        _page++;
      }
      
      // Stop infinite scroll for demo after 20 posts
      if (posts.length >= 20) {
        hasMore.value = false;
      }

    } catch (e) {
      print("Error loading more posts: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  Map<String, dynamic> _generateMockPost(int index) {
    return {
      "id": index,
      "username": "Quan EV Official",
      "time": "${index + 2}h ago",
      "likes": (index + 1) * 150,
      "comments": (index + 1) * 12,
      "caption": index % 2 == 0 
          ? "Experience the thrill of silent power! ⚡ #EV #Future"
          : "New fast charging stations live in your city. Check the map now! 🗺️",
      "image_gradient": index % 3 == 0 
          ? [const Color(0xFF2C3E50), const Color(0xFF000000)] // Dark Blue
          : index % 3 == 1
              ? [const Color(0xFF16222A), const Color(0xFF3A6073)] // Slate
              : [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Deep Space
      "headline": index % 2 == 0 ? "THE FUTURE IS\nELECTRIC" : "CHARGE FASTER\nGO FURTHER",
    };
  }
}
