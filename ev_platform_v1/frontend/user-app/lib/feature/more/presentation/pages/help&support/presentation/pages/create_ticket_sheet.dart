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
    // Dark theme colors
    const backgroundColor = Color(0xFF1E1E1E);
    const inputFillColor = Color(0xFF2C2C2C);
    const textColor = Colors.white;
    const hintColor = Colors.white54;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
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
              const Text(
                'New Support Ticket',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: textColor),
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
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    labelStyle: const TextStyle(color: hintColor),
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
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: hintColor),
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
                            child: Text(e, style: const TextStyle(color: textColor)),
                          ))
                      .toList(),
                  onChanged: (val) => category.value = val!,
                )),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: hintColor),
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
                backgroundColor: Get.theme.primaryColor,
                foregroundColor: Colors.black, // Primary usually implies black text on neon/lime
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
