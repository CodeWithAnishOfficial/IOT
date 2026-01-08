import 'package:get/get.dart';
import 'package:user_app/core/network/api_provider.dart';
import 'package:user_app/feature/wallet/domain/models/wallet_transaction.dart';

class WalletController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final transactions = <PaymentTransaction>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final transactionsResponse = await _apiProvider.get(
        '/wallet/transactions',
      );
      if (transactionsResponse['data'] != null) {
        final List<dynamic> data = transactionsResponse['data'];
        transactions.value = data
            .map((e) => PaymentTransaction.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
