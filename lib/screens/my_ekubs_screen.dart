import 'package:flutter/material.dart';
import '../services/ekub_state_service.dart';
import '../widgets/ekub_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/create_ekub_dialog.dart';

/// Screen displaying all Ekubs the user has joined.
class MyEkubsScreen extends StatelessWidget {
  const MyEkubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EkubStateService.instance,
      builder: (context, child) {
        final joinedEkubs = EkubStateService.instance.joinedEkubs;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Ekubs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Create New Ekub',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateEkubDialog(),
                  );
                },
              ),
            ],
          ),
          body: joinedEkubs.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: joinedEkubs.length,
                  itemBuilder: (context, index) {
                    final ekub = joinedEkubs[index];
                    return EkubCard(
                      ekub: ekub,
                      onJoin: () {},
                    );
                  },
                )
              : EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No Ekubs Joined Yet',
                  description: 'You are not participating in any rotating savings group yet. Discover open Ekubs or create your own!',
                  actionLabel: 'Discover Ekubs',
                  onAction: () => EkubStateService.instance.setTabIndex(1),
                ),
        );
      },
    );
  }
}
