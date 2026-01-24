import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:user_app/app/modules/session_history/controllers/session_history_controller.dart';

class SessionView extends GetView<SessionHistoryController> {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Charging History')),
      body: Column(
        children: [
          // Live Status Banner if active
          Obx(() {
            if (controller.currentStatus.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                color: theme.primaryColor.withOpacity(0.2),
                padding: const EdgeInsets.all(8),
                child: Text(
                  controller.currentStatus.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
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
                return RefreshIndicator(
                  onRefresh: controller.fetchSessions,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Text(
                            'No charging sessions found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchSessions,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.sessions.length,
                  itemBuilder: (context, index) {
                    final session = controller.sessions[index];
                    final isActive = session.status == 'active';

                    return Card(
                      color: theme.cardColor,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.battery_charging_full,
                          color: isActive ? theme.primaryColor : theme.disabledColor,
                        ),
                        title: Text(
                          DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(session.startTime),
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Station: ${session.chargerId} (Conn: ${session.connectorId})',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Energy: ${session.totalEnergy.toStringAsFixed(2)} kWh',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Cost: ₹${session.cost.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Status: ${session.status.toUpperCase()}',
                              style: TextStyle(
                                color: isActive
                                    ? theme.primaryColor
                                    : theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: !isActive
                            ? IconButton(
                                icon: Icon(
                                  Icons.receipt_long,
                                  color: theme.iconTheme.color,
                                ),
                                tooltip: 'Email Invoice',
                                onPressed: () =>
                                    controller.requestInvoice(session.sessionId),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
