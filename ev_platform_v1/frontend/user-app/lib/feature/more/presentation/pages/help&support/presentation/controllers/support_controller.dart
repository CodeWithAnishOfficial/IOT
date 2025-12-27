import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/more/presentation/pages/help&support/domain/models/support_ticket.dart';

class SupportController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final tickets = <SupportTicket>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.get('/support/list');
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        tickets.value = data.map((e) => SupportTicket.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tickets');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTicket(
    String subject,
    String description,
    String category,
  ) async {
    try {
      isLoading.value = true;
      await _apiProvider.post('/support/create', {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': 'Medium',
      });
      Get.back();
      fetchTickets();
      Get.snackbar('Success', 'Ticket created');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create ticket: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
