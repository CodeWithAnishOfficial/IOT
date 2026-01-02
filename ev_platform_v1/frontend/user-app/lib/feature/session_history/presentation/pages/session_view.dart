import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:user_app/feature/session_history/presentation/controllers/session_history_controller.dart';

class SessionView extends GetView<SessionHistoryController> {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Charging History')),
      body: Column(
        children: [
          // Live Status Banner if active
          Obx(() {
            if (controller.currentStatus.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                padding: const EdgeInsets.all(8),
                child: Text(
                  controller.currentStatus.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
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
                return const Center(
                  child: Text(
                    'No charging sessions found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
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
                        color: isActive ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                      title: Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(session.startTime),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Station: ${session.chargerId} (Conn: ${session.connectorId})',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Energy: ${session.totalEnergy.toStringAsFixed(2)} kWh',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Cost: ₹${session.cost.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Status: ${session.status.toUpperCase()}',
                            style: TextStyle(
                              color: isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      trailing: !isActive
                          ? IconButton(
                              icon: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                              ),
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
