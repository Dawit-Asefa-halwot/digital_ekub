import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../services/ekub_state_service.dart';
import '../widgets/contribute_dialog.dart';

/// Detailed View Screen for an individual Ekub (Cash or In-Kind).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: EkubStateService.instance,
      builder: (context, child) {
        // Retrieve fresh model instance from state
        final currentEkub = EkubStateService.instance.allEkubs.firstWhere(
          (e) => e.id == ekub.id,
          orElse: () => ekub,
        );

        return DefaultTabController(
          length: 4,
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
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, currentEkub),
                _buildMembersTab(context, currentEkub),
                _buildContributionsTab(context, currentEkub),
                _buildScheduleTab(context, currentEkub),
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
                child: currentEkub.isJoined
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Record Contribution Now'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ContributeDialog(),
                          );
                        },
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.group_add_rounded),
                        label: Text(
                          currentEkub.isInKind
                              ? 'Join In-Kind Savings Plan (${currentEkub.contributionAmount.toStringAsFixed(0)} ETB)'
                              : 'Join Ekub (${currentEkub.contributionAmount.toStringAsFixed(0)} ETB)',
                        ),
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

  // 1. Overview Tab (With Special In-Kind Product Hero)
  Widget _buildOverviewTab(BuildContext context, EkubModel currentEkub) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IN-KIND PRODUCT HERO BANNER
          if (currentEkub.isInKind) ...[
            Card(
              elevation: 3,
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        _getProductIcon(currentEkub.productIcon),
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Featured In-Kind Savings Plan',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroStat(
                          context,
                          'Product Value',
                          '${currentEkub.productValue?.toStringAsFixed(0) ?? currentEkub.totalPot.toStringAsFixed(0)} ETB',
                        ),
                        _buildHeroStat(
                          context,
                          'Contribution',
                          '${currentEkub.contributionAmount.toStringAsFixed(0)} ETB / ${currentEkub.frequency.toLowerCase().replaceAll("ly", "")}',
                        ),
                        _buildHeroStat(
                          context,
                          'Duration',
                          '${currentEkub.totalRounds} ${currentEkub.frequency == "Weekly" ? "Weeks" : "Months"}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CASH OR GENERAL EKUB STATS CARD
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
                    title: Text(currentEkub.isInKind ? 'Next Product Recipient' : 'Next Pot Recipient'),
                    trailing: Text(currentEkub.nextRecipient, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Members Availability'),
                    trailing: Text('${currentEkub.joinedMembersCount} / ${currentEkub.maxMembers}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // HOW IT WORKS BANNER
          Text(
            'How this ${currentEkub.category} Ekub Works',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentEkub.isInKind
                    ? 'In-kind Ekubs allow members to save towards a physical product. Each member contributes ${currentEkub.contributionAmount.toStringAsFixed(0)} ETB every ${currentEkub.frequency.toLowerCase().replaceAll("ly", "")}. When your turn arrives in the lottery draw, you receive the guaranteed product.'
                    : 'Cash rotating Ekubs pool member contributions every ${currentEkub.frequency.toLowerCase().replaceAll("ly", "")}. The total pot of ${currentEkub.totalPot.toStringAsFixed(0)} ETB is awarded to one winning member per round based on the group agreement schedule.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  // 2. Members Tab
  Widget _buildMembersTab(BuildContext context, EkubModel currentEkub) {
    return currentEkub.members.isNotEmpty
        ? ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: currentEkub.members.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final member = currentEkub.members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${member.turnNumber}'),
                ),
                title: Text(member.name),
                subtitle: Text('Turn #${member.turnNumber} • Contributed: ${member.amountContributed.toStringAsFixed(0)} ETB'),
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
          )
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No member roster details available yet. Be the first to join!'),
            ),
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
    return currentEkub.schedule.isNotEmpty
        ? ListView.builder(
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
          )
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Draw schedule will be finalized once all member slots are filled.'),
            ),
          );
  }
}
