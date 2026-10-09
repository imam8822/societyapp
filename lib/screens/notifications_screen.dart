import 'package:society_app/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../core/api/api_services.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications right now.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (ctx, idx) {
              final n = notifications[idx];
              final isRead = n.isRead;

              // Determine icon based on type
              IconData icon = Icons.info;
              Color iconColor = Colors.blue;
              if (n.type == 'Success') {
                icon = Icons.check_circle;
                iconColor = Colors.green;
              } else if (n.type == 'Warning') {
                icon = Icons.warning;
                iconColor = Colors.orange;
              } else if (n.type == 'Error') {
                icon = Icons.error;
                iconColor = Colors.red;
              }

              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.body),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(n.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: isRead
                    ? null
                    : const CircleAvatar(radius: 4, backgroundColor: Colors.blue),
                onTap: () async {
                  if (!isRead) {
                    try {
                      await NotificationApi.markAsRead(n.id);
                      ref.invalidate(notificationsProvider);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: const AppSpinner()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
