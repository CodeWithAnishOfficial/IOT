import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:user_app/feature/session_history/presentation/controllers/session_history_controller.dart';

class SessionView extends GetView<SessionHistoryController> {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charging History')),
      body: Column(
        children: [
          // Live Status Banner if active
          Obx(() {
            if (controller.currentStatus.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                color: Colors.greenAccent,
                padding: const EdgeInsets.all(8),
                child: Text(
                  controller.currentStatus.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.sessions.isEmpty) {
                return const Center(child: Text('No charging sessions found.'));
              }
              return ListView.builder(
                itemCount: controller.sessions.length,
                itemBuilder: (context, index) {
                  final session = controller.sessions[index];
                  final isActive = session.status == 'active';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.battery_charging_full,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(session.startTime),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Station: ${session.chargerId} (Conn: ${session.connectorId})',
                          ),
                          Text(
                            'Energy: ${session.totalEnergy.toStringAsFixed(2)} kWh',
                          ),
                          Text('Cost: ₹${session.cost.toStringAsFixed(2)}'),
                          Text(
                            'Status: ${session.status.toUpperCase()}',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      trailing: !isActive
                          ? IconButton(
                              icon: const Icon(Icons.receipt_long),
                              tooltip: 'Email Invoice',
                              onPressed: () =>
                                  controller.requestInvoice(session.sessionId),
                            )
                          : null,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
