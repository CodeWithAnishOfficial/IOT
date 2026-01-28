import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final val = double.tryParse(amountController.text);
    setState(() {
      _selectedAmount = val;
    });
  }

  @override
  void dispose() {
    amountController.removeListener(_onAmountChanged);
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for dark mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define modern colors
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = theme.disabledColor;
    
    return Material(
      color: Colors.transparent, 
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 20,
               offset: const Offset(0, -5),
             )
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Charging",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Connector ID: ${widget.connectorId}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: textColor.withOpacity(0.6)),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.dividerColor.withOpacity(0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Input Label
              Text(
                "Enter Amount",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              
              // Amount Input Field
              Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor, // Slightly different background
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IntrinsicWidth(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: "0",
                          hintStyle: GoogleFonts.poppins(
                            color: hintColor.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Quick Amount Chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: quickAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return InkWell(
                    onTap: () {
                      amountController.text = amount.toInt().toString();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : theme.dividerColor,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Text(
                        "₹${amount.toInt()}",
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              
              // Action Button
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: Text(
                    "Pay & Start Session",
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, 
                      letterSpacing: 0.5
                    ),
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
