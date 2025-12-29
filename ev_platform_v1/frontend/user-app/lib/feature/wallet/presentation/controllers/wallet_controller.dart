import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/wallet/domain/models/wallet_transaction.dart';

class WalletController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final balance = 0.0.obs;
  final transactions = <WalletTransaction>[].obs;
  final isLoading = false.obs;
  final amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    try {
      isLoading.value = true;
      final balanceResponse = await _apiProvider.get('/wallet/balance');
      if (balanceResponse != null && balanceResponse['data'] != null) {
        balance.value = (balanceResponse['data']['balance'] as num).toDouble();
      } else {
         balance.value = 0.0;
      }

      final transactionsResponse = await _apiProvider.get(
        '/wallet/transactions',
      );
      if (transactionsResponse['data'] != null) {
        final List<dynamic> data = transactionsResponse['data'];
        transactions.value = data
            .map((e) => WalletTransaction.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching wallet data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMoney() async {
    if (amountController.text.isEmpty) return;

    try {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Invalid amount');
        return;
      }

      // Start add money flow
      final response = await _apiProvider.post('/wallet/add-money', {
        'amount': amount,
        'currency': 'INR',
      });

      // In real app, integrate Payment Gateway SDK (Razorpay) here using response.order_id
      // For mock:
      Get.snackbar(
        'Success',
        'Payment initiated: ${response['data']['order_id']}',
      );

      // Assume success for demo and refresh
      amountController.clear();
      // Wait a bit and refresh (mocking backend webhook)
      await Future.delayed(const Duration(seconds: 2));
      // fetchWalletData(); // Would update if backend updated
    } catch (e) {
      Get.snackbar('Error', 'Failed to add money: ${e.toString()}');
    }
  }
}
