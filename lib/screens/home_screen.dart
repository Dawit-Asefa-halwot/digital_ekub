import 'package:flutter/material.dart';
import '../services/ekub_state_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/contribute_dialog.dart';
import '../widgets/create_ekub_dialog.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../widgets/reminder_center_sheet.dart';
import 'ekub_details_screen.dart';

/// Interactive Home Screen for Digital Ekub.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleCreateEkubClick(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;

    if (currentUser != null && currentUser.isAdmin) {
      showDialog(
        context: context,
        builder: (context) => const CreateEkubDialog(),
      );
    } else {
      // Authorization Guard dialog for Members
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: Colors.purple),
                SizedBox(width: 8),
                Text('Admin Permission Required'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creating and organizing new Ekubs is restricted to Admin users.'),
                SizedBox(height: 12),
                Text(
                  'Would you like to switch your role to Admin (Organizer) to test creating an Ekub?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  AuthService.instance.switchRole(UserRole.admin);
                  showDialog(
                    context: context,
                    builder: (context) => const CreateEkubDialog(),
                  );
                },
                child: const Text('Switch to Admin & Create'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([EkubStateService.instance, AuthService.instance]),
      builder: (context, child) {
        final user = AuthService.instance.currentUser;
        if (user == null) return const SizedBox.shrink();

        final joinedEkubs = EkubStateService.instance.joinedEkubs;
        final activeEkub = joinedEkubs.isNotEmpty ? joinedEkubs.first : null;
        final availableEkubs = EkubStateService.instance.allEkubs.where((e) => !e.isJoined).toList();
        final recentTransactions = EkubStateService.instance.transactions.take(3).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.savings_rounded),
                SizedBox(width: 8),
                Text('Digital Ekub'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded),
                tooltip: 'Reminders & Notifications',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ReminderCenterSheet(),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Greeting Header with Role Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selam, ${user.name.split(" ").first} 👋',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Welcome to your rotating savings dashboard',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Chip(
                      avatar: Icon(user.isAdmin ? Icons.star_rounded : Icons.person_rounded, size: 16),
                      label: Text(user.roleName),
                      backgroundColor: user.isAdmin ? Colors.purple.shade100 : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Active Ekub Summary Card
                if (activeEkub != null)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  activeEkub.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(context, 'Current Round', 'Round ${activeEkub.currentRound} / ${activeEkub.totalRounds}'),
                              _buildSummaryItem(context, 'Contribution', '${activeEkub.contributionAmount.toStringAsFixed(0)} ETB'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(context, 'Total Pot', '${activeEkub.totalPot.toStringAsFixed(0)} ETB'),
                              _buildSummaryItem(context, 'Next Recipient', activeEkub.nextRecipient),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Round ${activeEkub.currentRound} status: Active',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text('Details'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EkubDetailsScreen(ekub: activeEkub),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, size: 40, color: Colors.amber),
                          const SizedBox(height: 8),
                          const Text('No Active Ekub Joined', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Explore available savings pools and join or create an Ekub to start.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => EkubStateService.instance.setTabIndex(1),
                            child: const Text('Discover Ekubs'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // 3. Working Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionButton(
                      context,
                      icon: Icons.add_card_rounded,
                      label: 'Contribute',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ContributeDialog(),
                        );
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.group_add_rounded,
                      label: 'Join Ekub',
                      onTap: () {
                        EkubStateService.instance.setTabIndex(1); // Navigate to Discover
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.create_new_folder_rounded,
                      label: user.isAdmin ? 'Create Ekub' : 'Create (Admin)',
                      onTap: () => _handleCreateEkubClick(context),
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.history_rounded,
                      label: 'Transactions',
                      onTap: () {
                        EkubStateService.instance.setTabIndex(3); // Navigate to Transactions
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Recommended Ekubs Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended Ekubs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => EkubStateService.instance.setTabIndex(1),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                if (availableEkubs.isNotEmpty)
                  ...availableEkubs.take(2).map((ekub) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ekub.isInKind ? Colors.amber.shade100 : Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(
                            ekub.isInKind ? Icons.card_giftcard : Icons.storefront_rounded,
                            color: ekub.isInKind ? Colors.amber.shade900 : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(ekub.name),
                        subtitle: Text('${ekub.contributionAmount.toStringAsFixed(0)} ETB / ${ekub.frequency} • ${ekub.joinedMembersCount}/${ekub.maxMembers} Members'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EkubDetailsScreen(ekub: ekub),
                            ),
                          );
                        },
                      ),
                    );
                  })
                else
                  const Text('All Ekubs currently joined!'),

                const SizedBox(height: 20),

                // 5. Recent Activity Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => EkubStateService.instance.setTabIndex(3),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                Card(
                  child: Column(
                    children: recentTransactions.map((txn) {
                      final isPayout = txn.amount > 0;
                      return ListTile(
                        leading: Icon(
                          isPayout ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isPayout ? Colors.green : Colors.grey.shade700,
                        ),
                        title: Text(txn.type),
                        subtitle: Text('${txn.ekubName} • ID: ${txn.id}'),
                        trailing: Text(
                          '${isPayout ? "+" : ""}${txn.amount.toStringAsFixed(0)} ETB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPayout ? Colors.green.shade700 : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => TransactionDetailDialog(transaction: txn),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
