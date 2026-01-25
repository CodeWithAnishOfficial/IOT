import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_app/app/modules/home/controllers/home_controller.dart';
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
    // Check for dark mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define modern colors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : theme.cardColor;
    final surfaceColor = isDark ? const Color(0xFF2C2C2C) : theme.cardColor; // Slightly lighter for inputs
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Material(
      color: Colors.transparent, 
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.3),
               blurRadius: 20,
               offset: const Offset(0, -5),
             )
          ],
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Start Charging",
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: theme.iconTheme.color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 56), // Align with title text
                child: Text(
                  "Connector ID: ${widget.connectorId}",
                  style: TextStyle(color: textColor.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Enter Amount",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    prefixText: "₹ ",
                    prefixStyle: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: "0",
                    hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.transparent, // Handled by Container
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: quickAmounts.map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text("₹${amount.toInt()}"),
                        labelStyle: TextStyle(
                            color: textColor.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                        ),
                        onPressed: () {
                          amountController.text = amount.toInt().toString();
                        },
                        backgroundColor: surfaceColor,
                        padding: const EdgeInsets.symmetric(vertical: 8), 
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      Get.snackbar(
                        "Invalid Amount",
                        "Please enter a valid amount to start charging.",
                        colorText: Colors.white,
                        backgroundColor: Colors.red,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 16,
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28), // Fully rounded
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: const Text(
                    "Pay & Start Session",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
