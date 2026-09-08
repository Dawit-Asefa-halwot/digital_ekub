import 'package:flutter/material.dart';
import '../services/reminder_service.dart';
import '../services/auth_service.dart';
import '../models/reminder_model.dart';

/// In-App Notification & Payment Reminder Center Bottom Sheet.
class ReminderCenterSheet extends StatelessWidget {
  const ReminderCenterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: ReminderService.instance,
      builder: (context, child) {
        final currentUser = AuthService.instance.currentUser;
        final userId = currentUser?.id ?? 'user_101';
        final reminders = ReminderService.instance.getRemindersForUser(userId);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Color(0xFF006C4C)),
                      const SizedBox(width: 8),
                      Text(
                        'Contribution Reminders',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text('${ReminderService.instance.getUnpaidCount(userId)} Unpaid'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Local notification simulation: Note that previous Ekub winners must continue paying future rounds and receiving reminders.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: reminders.isNotEmpty
                    ? ListView.builder(
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final rem = reminders[index];
                          return _buildReminderTile(context, rem);
                        },
                      )
                    : const Center(
                        child: Text('No active reminders found.'),
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderTile(BuildContext context, ReminderModel reminder) {
    Color badgeColor;
    String badgeText;
    IconData icon;

    switch (reminder.status) {
      case 'overdue':
        badgeColor = Colors.red.shade100;
        badgeText = '⚠️ Overdue';
        icon = Icons.warning_amber_rounded;
        break;
      case 'due':
        badgeColor = Colors.orange.shade100;
        badgeText = '🔔 Due Soon';
        icon = Icons.notifications_active_outlined;
        break;
      case 'paid':
        badgeColor = Colors.green.shade100;
        badgeText = '✓ Paid';
        icon = Icons.check_circle_outlined;
        break;
      default:
        badgeColor = Colors.blue.shade100;
        badgeText = 'Upcoming';
        icon = Icons.calendar_today_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        title: Text(reminder.ekubName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Round ${reminder.roundNumber} • ${reminder.amount.toStringAsFixed(0)} ETB\nDue: ${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
