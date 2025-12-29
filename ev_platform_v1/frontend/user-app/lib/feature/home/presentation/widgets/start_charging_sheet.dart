import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/feature/home/presentation/controllers/home_controller.dart';
import 'package:user_app/utils/theme/themes.dart';

class StartChargingSheet extends StatefulWidget {
  final HomeController controller;
  final String connectorId;

  const StartChargingSheet({
    super.key,
    required this.controller,
    required this.connectorId,
  });

  @override
  State<StartChargingSheet> createState() => _StartChargingSheetState();
}

class _StartChargingSheetState extends State<StartChargingSheet> {
  final TextEditingController amountController = TextEditingController();
  final List<double> quickAmounts = [100, 200, 500, 1000];
  
  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Required for Material to be invisible but provide context
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Start Charging",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Connector ID: ${widget.connectorId}",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          Text(
            "Enter Amount",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: "₹ ",
              hintText: "0",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: quickAmounts.map((amount) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text("₹${amount.toInt()}"),
                  onPressed: () {
                    amountController.text = amount.toInt().toString();
                  },
                  backgroundColor: Colors.grey[100],
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  Get.snackbar("Invalid Amount", "Please enter a valid amount to start charging.");
                  return;
                }
                widget.controller.startChargingSession(widget.connectorId, amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Pay & Start Session",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}
