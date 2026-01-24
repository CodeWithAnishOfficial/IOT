import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class CreateTicketSheet extends StatefulWidget {
  const CreateTicketSheet({super.key});

  @override
  State<CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<CreateTicketSheet> {
  final SupportController controller = Get.find<SupportController>();
  late TextEditingController subjectController;
  late TextEditingController descriptionController;
  final category = 'General'.obs;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    subjectController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = theme.cardColor;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200];
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color ?? (isDark ? Colors.white54 : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Support Ticket',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: subjectController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    labelStyle: TextStyle(color: hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                  ),
                  validator: (val) => val?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                Obx(() => DropdownButtonFormField<String>(
                  value: category.value,
                  dropdownColor: backgroundColor,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                  ),
                  items: ['Billing', 'Technical', 'General', 'Account', 'Other']
                      .map((e) => DropdownMenuItem(
                            value: e, 
                            child: Text(e, style: TextStyle(color: textColor)),
                          ))
                      .toList(),
                  onChanged: (val) => category.value = val!,
                )),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: hintColor),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                  ),
                  validator: (val) => val?.isEmpty == true ? 'Required' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  controller.createTicket(
                    subjectController.text,
                    descriptionController.text,
                    category.value,
                  );
                }
              },
              child: const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          // Add padding for keyboard - Get.bottomSheet handles this usually, but safe to keep modest padding
          // If isScrollControlled is true, we often don't need manual viewInsets padding if the sheet height is managed.
          // However, putting it in a SingleChildScrollView or just letting the sheet resize is better.
          // Let's rely on the sheet behavior but add a small buffer.
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 0),
        ],
      ),
    );
  }
}
