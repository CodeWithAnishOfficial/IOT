import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.transactions.isEmpty) {
             return const Center(
                child: Text(
                  'No transactions found', 
                  style: TextStyle(color: Colors.white70, fontSize: 16)
                )
             );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.transactions.length,
          itemBuilder: (context, index) {
            final transaction = controller.transactions[index];
            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.receipt_long, 
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction.method.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${transaction.transactionId}',
                           style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          transaction.status ? 'Success' : 'Failed',
                          style: TextStyle(
                              color: transaction.status ? Colors.green : Colors.red,
                              fontSize: 12,
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
