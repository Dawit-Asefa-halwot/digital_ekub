import 'package:flutter/material.dart';
import '../services/ekub_state_service.dart';
import '../widgets/ekub_card.dart';
import '../widgets/empty_state_widget.dart';
import '../models/ekub_model.dart';

/// Interactive Discover Screen allowing searching, filtering, and joining Ekubs.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = EkubStateService.instance.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showJoinConfirmationDialog(BuildContext context, EkubModel ekub) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join ${ekub.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ekub.isInKind
                    ? 'Confirm joining this In-kind savings plan for ${ekub.productName ?? ekub.name}.'
                    : 'Confirm joining this cash rotating Ekub group.',
              ),
              const SizedBox(height: 12),
              Text('• Contribution: ${ekub.contributionAmount.toStringAsFixed(0)} ETB / ${ekub.frequency}'),
              Text('• Total Rounds: ${ekub.totalRounds}'),
              Text('• Current Members: ${ekub.joinedMembersCount} / ${ekub.maxMembers}'),
              const SizedBox(height: 12),
              const Text(
                'Note: Initial contribution will be recorded locally.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await EkubStateService.instance.joinEkub(ekub.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Congratulations! You joined ${ekub.name}.'),
                      backgroundColor: Colors.green.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(EkubStateService.instance.errorMessage ?? '⚠️ You are already a member of this Ekub.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Confirm & Join'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EkubStateService.instance,
      builder: (context, child) {
        final ekubs = EkubStateService.instance.filteredEkubs;
        final currentCategory = EkubStateService.instance.selectedCategory;
        final currentFrequency = EkubStateService.instance.selectedFrequencyFilter;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Discover Ekubs'),
          ),
          body: Column(
            children: [
              // Search & Filter Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Text Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, product, or description...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  EkubStateService.instance.clearSearch();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        EkubStateService.instance.setSearchQuery(val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Categories Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(context, 'All', Icons.grid_view_rounded, currentCategory),
                          _buildCategoryChip(context, 'In-kind', Icons.card_giftcard_rounded, currentCategory),
                          _buildCategoryChip(context, 'Popular', Icons.trending_up_rounded, currentCategory),
                          _buildCategoryChip(context, 'Group', Icons.groups_rounded, currentCategory),
                          _buildCategoryChip(context, 'Corporate', Icons.business_rounded, currentCategory),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Frequency Filters
                    Row(
                      children: [
                        const Text('Frequency: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('All'),
                          selected: currentFrequency == 'All',
                          onSelected: (_) => EkubStateService.instance.setFrequencyFilter('All'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Weekly'),
                          selected: currentFrequency == 'Weekly',
                          onSelected: (_) => EkubStateService.instance.setFrequencyFilter('Weekly'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected: currentFrequency == 'Monthly',
                          onSelected: (_) => EkubStateService.instance.setFrequencyFilter('Monthly'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filtered Ekubs List View
              Expanded(
                child: ekubs.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: ekubs.length,
                        itemBuilder: (context, index) {
                          final ekub = ekubs[index];
                          return EkubCard(
                            ekub: ekub,
                            onJoin: () => _showJoinConfirmationDialog(context, ekub),
                          );
                        },
                      )
                    : EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Ekubs Found',
                        description: 'We couldn\'t find any Ekub matching your search query or selected filters.',
                        actionLabel: 'Reset Filters & Search',
                        onAction: () {
                          _searchController.clear();
                          EkubStateService.instance.clearSearch();
                          EkubStateService.instance.selectCategory('All');
                          EkubStateService.instance.setFrequencyFilter('All');
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, IconData icon, String currentCategory) {
    final selected = currentCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onSelected: (bool isSelected) {
          if (isSelected) {
            EkubStateService.instance.selectCategory(label);
          }
        },
      ),
    );
  }
}
