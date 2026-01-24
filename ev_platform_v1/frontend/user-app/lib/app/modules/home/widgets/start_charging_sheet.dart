import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/core/theme/app_colors.dart';

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
      color: Colors
          .transparent, // Required for Material to be invisible but provide context
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Start Charging",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: Colors.white, // Removed to use theme default
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Connector ID: ${widget.connectorId}",
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),

              Text(
                "Enter Amount",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  // color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    fontSize: 24,
                  ),
                  hintText: "0",
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
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
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      onPressed: () {
                        amountController.text = amount.toInt().toString();
                      },
                      backgroundColor: Theme.of(context).cardColor,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                      Get.snackbar(
                        "Invalid Amount",
                        "Please enter a valid amount to start charging.",
                        colorText: Colors.white,
                        backgroundColor: Colors.red,
                      );
                      return;
                    }
                    widget.controller.startChargingSession(
                      widget.connectorId,
                      amount,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
