import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../services/ekub_state_service.dart';
import '../services/ekub_draw_service.dart';
import '../widgets/simulated_payment_modal.dart';
import '../widgets/lucky_draw_dialog.dart';

/// Detailed View Screen for an individual Ekub with Lucky Draw & Audit History.
class EkubDetailsScreen extends StatelessWidget {
  final EkubModel ekub;

  const EkubDetailsScreen({
    super.key,
    required this.ekub,
  });

  IconData _getProductIcon(String? iconType) {
    switch (iconType) {
      case 'tv':
        return Icons.tv_rounded;
      case 'refrigerator':
        return Icons.kitchen_rounded;
      case 'washing_machine':
        return Icons.local_laundry_service_rounded;
      case 'oven':
        return Icons.microwave_rounded;
      case 'smartphone':
        return Icons.smartphone_rounded;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  void _executeDraw(BuildContext context, EkubModel currentEkub) {
    final result = EkubDrawService.instance.runLuckyDraw(currentEkub.id);

    if (result != null) {
      showDialog(
        context: context,
        builder: (context) => LuckyDrawDialog(result: result),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No eligible members remaining for lucky draw or Ekub is closed.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: EkubStateService.instance,
      builder: (context, child) {
        final currentEkub = EkubStateService.instance.allEkubs.firstWhere(
          (e) => e.id == ekub.id,
          orElse: () => ekub,
        );

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentEkub.name),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Members'),
                  Tab(icon: Icon(Icons.payments_outlined), text: 'Contributions'),
                  Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Schedule'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, currentEkub),
                _buildMembersTab(context, currentEkub),
                _buildContributionsTab(context, currentEkub),
                _buildScheduleTab(context, currentEkub),
                _buildAuditLogTab(context, currentEkub),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: currentEkub.isClosed
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🎉 EKUB COMPLETED & CLOSED: All members have received their turn.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : currentEkub.isJoined
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_card_rounded),
                                  label: const Text('Contribute'),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => SimulatedPaymentModal(ekub: currentEkub),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.casino_rounded, color: Colors.amber),
                                label: const Text('Lucky Draw'),
                                onPressed: () => _executeDraw(context, currentEkub),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.group_add_rounded),
                            label: Text('Join Ekub (${currentEkub.contributionAmount.toStringAsFixed(0)} ETB)'),
                            onPressed: currentEkub.joinedMembersCount >= currentEkub.maxMembers
                                ? null
                                : () {
                                    final success = EkubStateService.instance.joinEkub(currentEkub.id);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('🎉 You joined ${currentEkub.name}!'),
                                          backgroundColor: Colors.green.shade800,
                                        ),
                                      );
                                    }
                                  },
                          ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(BuildContext context, EkubModel currentEkub) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CLOSED BANNER
          if (currentEkub.isClosed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_rounded, size: 36, color: Colors.green),
                  SizedBox(height: 8),
                  Text(
                    '🎉 EKUB COMPLETED & CLOSED',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All members have received their turn. No new contributions or draws are accepted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // IN-KIND PRODUCT HERO BANNER
          if (currentEkub.isInKind) ...[
            Card(
              elevation: 2,
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        _getProductIcon(currentEkub.productIcon),
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentEkub.productName ?? currentEkub.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentEkub.productDescription ?? currentEkub.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // STATS CARD
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(currentEkub.isInKind ? 'Total Product Pool Value' : 'Total Pot Amount'),
                    subtitle: Text(
                      '${currentEkub.totalPot.toStringAsFixed(0)} ETB',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.sync_rounded),
                    title: const Text('Current Round'),
                    trailing: Text('Round ${currentEkub.currentRound} of ${currentEkub.totalRounds}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_rounded),
                    title: const Text('Previous Winner'),
                    trailing: Text(currentEkub.nextRecipient, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // LUCKY DRAW TRIGGER CARD
          if (!currentEkub.isClosed)
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.casino_rounded, color: Colors.brown),
                        SizedBox(width: 8),
                        Text(
                          'Ekub Lucky Draw Engine',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rounds use random selection among eligible members who have NOT won a previous draw. Winners must continue paying future rounds!',
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text('Run Round Lucky Draw'),
                      onPressed: () => _executeDraw(context, currentEkub),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 2. Members Tab
  Widget _buildMembersTab(BuildContext context, EkubModel currentEkub) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: currentEkub.members.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final member = currentEkub.members[index];
        final hasWon = currentEkub.wonMemberIds.contains(member.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: hasWon ? Colors.amber.shade100 : null,
            child: Text(
              hasWon ? '🏆' : '${member.turnNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          title: Text(member.name),
          subtitle: Text('${hasWon ? "Won Previous Draw • " : ""}Contributed: ${member.amountContributed.toStringAsFixed(0)} ETB'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: member.paymentStatus == 'Paid' ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.paymentStatus,
              style: TextStyle(
                color: member.paymentStatus == 'Paid' ? Colors.green.shade900 : Colors.orange.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  // 3. Contributions Tab
  Widget _buildContributionsTab(BuildContext context, EkubModel currentEkub) {
    final ekubContributions = EkubStateService.instance.contributions
        .where((c) => c.ekubId == currentEkub.id)
        .toList();

    return ekubContributions.isNotEmpty
        ? ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: ekubContributions.length,
            itemBuilder: (context, index) {
              final item = ekubContributions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Round ${item.roundNumber} Contribution'),
                  subtitle: Text('Paid ${item.amount.toStringAsFixed(0)} ETB • Date: ${item.date.day}/${item.date.month}/${item.date.year}'),
                  trailing: Text(
                    item.status,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          )
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No contribution deposit history recorded for this Ekub yet.'),
            ),
          );
  }

  // 4. Schedule Tab
  Widget _buildScheduleTab(BuildContext context, EkubModel currentEkub) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: currentEkub.schedule.length,
      itemBuilder: (context, index) {
        final item = currentEkub.schedule[index];
        final isCurrent = item.status == 'Current';

        return Card(
          color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent ? Theme.of(context).colorScheme.primary : null,
              child: Icon(
                Icons.event_outlined,
                color: isCurrent ? Theme.of(context).colorScheme.onPrimary : null,
              ),
            ),
            title: Text('Round ${item.roundNumber} - ${item.recipientName}'),
            subtitle: Text('Draw Date: ${item.date.day}/${item.date.month}/${item.date.year}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Theme.of(context).colorScheme.onPrimary : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 5. Audit Log Tab
  Widget _buildAuditLogTab(BuildContext context, EkubModel currentEkub) {
    return currentEkub.auditLogs.isNotEmpty
        ? ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: currentEkub.auditLogs.length,
            itemBuilder: (context, index) {
              final log = currentEkub.auditLogs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(log.icon, size: 20),
                  ),
                  title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${log.description}\n${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} at ${log.timestamp.hour.toString().padLeft(2, "0")}:${log.timestamp.minute.toString().padLeft(2, "0")}'),
                  isThreeLine: true,
                ),
              );
            },
          )
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No audit events logged yet.'),
            ),
          );
  }
}
