import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../screens/ekub_details_screen.dart';

/// Reusable Card component supporting Cash & In-Kind Ekubs.
class EkubCard extends StatelessWidget {
  final EkubModel ekub;
  final VoidCallback onJoin;

  const EkubCard({
    super.key,
    required this.ekub,
    required this.onJoin,
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

    if (ekub.isInKind) {
      // IN-KIND PRODUCT EKUB CARD
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EkubDetailsScreen(ekub: ekub),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Hero Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        _getProductIcon(ekub.productIcon),
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Featured In-kind Ekub',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ekub.productName ?? ekub.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Product Value: ${ekub.productValue?.toStringAsFixed(0)} ETB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info & Description
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ekub.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Product Plan Specs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          context,
                          'Contribution',
                          '${ekub.contributionAmount.toStringAsFixed(0)} ETB / ${ekub.frequency.toLowerCase().replaceAll('ly', '')}',
                        ),
                        _buildInfoColumn(
                          context,
                          'Members',
                          '${ekub.joinedMembersCount} / ${ekub.maxMembers}',
                        ),
                        _buildInfoColumn(
                          context,
                          'Duration',
                          '${ekub.totalRounds} ${ekub.frequency == "Weekly" ? "Weeks" : "Months"}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ekub.isJoined
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('Joined Member'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EkubDetailsScreen(ekub: ekub),
                                  ),
                                );
                              },
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.group_add_rounded),
                              label: Text('Join In-Kind Savings Plan (${ekub.contributionAmount.toStringAsFixed(0)} ETB)'),
                              onPressed: ekub.joinedMembersCount >= ekub.maxMembers ? null : onJoin,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // CASH EKUB CARD
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EkubDetailsScreen(ekub: ekub),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ekub.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    'Pot: ${ekub.totalPot.toStringAsFixed(0)} ETB',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ekub.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ekub.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('${ekub.contributionAmount.toStringAsFixed(0)} ETB / ${ekub.frequency}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('${ekub.joinedMembersCount} / ${ekub.maxMembers} Members'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ekub.isJoined
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text('View Ekub Details'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EkubDetailsScreen(ekub: ekub),
                            ),
                          );
                        },
                      )
                    : ElevatedButton(
                        onPressed: ekub.joinedMembersCount >= ekub.maxMembers ? null : onJoin,
                        child: Text(ekub.joinedMembersCount >= ekub.maxMembers ? 'Ekub Full' : 'Join Ekub'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
