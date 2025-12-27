import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class SupportView extends GetView<SupportController> {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTicketDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tickets.isEmpty) {
          return const Center(child: Text('No support tickets found.'));
        }
        return ListView.builder(
          itemCount: controller.tickets.length,
          itemBuilder: (context, index) {
            final ticket = controller.tickets[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text(ticket.subject),
                subtitle: Text('${ticket.status} - ${ticket.category}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${ticket.description}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Responses:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (ticket.responses.isEmpty) const Text('No responses yet.'),
                        ...ticket.responses.map((r) => ListTile(
                          title: Text(r.message),
                          subtitle: Text('${r.sender} - ${r.timestamp}'),
                          tileColor: r.sender == 'admin' ? Colors.grey[100] : null,
                        )),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final category = 'General'.obs;

    Get.defaultDialog(
      title: 'New Ticket',
      content: Column(
        children: [
          TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
          TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 16),
          Obx(() => DropdownButton<String>(
            value: category.value,
            items: ['Billing', 'Technical', 'General', 'Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => category.value = val!,
            isExpanded: true,
          )),
        ],
      ),
      textConfirm: 'Submit',
      textCancel: 'Cancel',
      onConfirm: () {
        if (subjectController.text.isEmpty || descriptionController.text.isEmpty) {
          Get.snackbar('Error', 'Please fill required fields');
          return;
        }
        controller.createTicket(subjectController.text, descriptionController.text, category.value);
      },
    );
  }
}
