import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ekub_model.dart';
import '../models/member_model.dart';
import '../models/contribution_model.dart';
import '../models/transaction_model.dart';
import '../models/schedule_model.dart';
import '../data/mock_data.dart';

/// Central state management service for Digital Ekub prototype.
/// Extends ChangeNotifier to provide reactive state updates across all screens.
class EkubStateService extends ChangeNotifier {
  // Singleton pattern for simple application access
  static final EkubStateService instance = EkubStateService._internal();
  EkubStateService._internal();

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  final UserModel _user = MockData.currentUser;
  UserModel get user => _user;

  final List<EkubModel> _ekubs = List.from(MockData.initialEkubs);
  List<EkubModel> get allEkubs => List.unmodifiable(_ekubs);

  final List<TransactionModel> _transactions = List.from(MockData.initialTransactions);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  final List<ContributionModel> _contributions = List.from(MockData.initialContributions);
  List<ContributionModel> get contributions => List.unmodifiable(_contributions);

  // Search & Filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _selectedFrequencyFilter = 'All';
  String get selectedFrequencyFilter => _selectedFrequencyFilter;

  // Filtered Ekubs getter
  List<EkubModel> get filteredEkubs {
    return _ekubs.where((ekub) {
      // 1. Search Query Filter
      final matchesSearch = _searchQuery.isEmpty ||
          ekub.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ekub.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ekub.productName != null && ekub.productName!.toLowerCase().contains(_searchQuery.toLowerCase()));

      // 2. Category Filter
      final matchesCategory = _selectedCategory == 'All' || ekub.category == _selectedCategory;

      // 3. Frequency Filter
      final matchesFrequency = _selectedFrequencyFilter == 'All' || ekub.frequency == _selectedFrequencyFilter;

      return matchesSearch && matchesCategory && matchesFrequency;
    }).toList();
  }

  // Joined Ekubs getter
  List<EkubModel> get joinedEkubs => _ekubs.where((e) => e.isJoined).toList();

  // Navigation controller helper
  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Search updater
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Category selection
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setFrequencyFilter(String frequency) {
    _selectedFrequencyFilter = frequency;
    notifyListeners();
  }

  /// Action: Join an Ekub
  bool joinEkub(String ekubId) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index == -1) return false;

    final ekub = _ekubs[index];
    if (ekub.isJoined) return false; // Duplicate join prevention

    // Update Ekub model state
    final updatedEkub = ekub.copyWith(
      isJoined: true,
      joinedMembersCount: ekub.joinedMembersCount + 1,
    );

    // Add current user to member list
    updatedEkub.members.add(
      MemberModel(
        id: _user.id,
        name: '${_user.name} (You)',
        turnNumber: updatedEkub.joinedMembersCount,
        hasReceivedPot: false,
        paymentStatus: 'Paid',
        amountContributed: updatedEkub.contributionAmount,
      ),
    );

    _ekubs[index] = updatedEkub;

    // Create local join transaction
    final newTxn = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ekubId: ekub.id,
      ekubName: ekub.name,
      type: 'Ekub Membership Joined',
      amount: -ekub.contributionAmount,
      date: DateTime.now(),
      status: 'Successful',
      description: 'Joined ${ekub.name}. Initial round deposit recorded locally.',
    );

    _transactions.insert(0, newTxn);

    // Create initial contribution entry
    _contributions.insert(
      0,
      ContributionModel(
        id: 'cnt_${DateTime.now().millisecondsSinceEpoch}',
        ekubId: ekub.id,
        ekubName: ekub.name,
        roundNumber: ekub.currentRound,
        amount: ekub.contributionAmount,
        date: DateTime.now(),
        status: 'Paid',
        transactionId: newTxn.id,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Action: Create a new Ekub locally
  EkubModel createEkub({
    required String name,
    required String category,
    required double contributionAmount,
    required String frequency,
    required int maxMembers,
    required String description,
    String? productName,
    double? productValue,
    String? productIcon,
  }) {
    final isKind = category == 'In-kind';

    final newEkub = EkubModel(
      id: 'ekub_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      isInKind: isKind,
      contributionAmount: contributionAmount,
      frequency: frequency,
      maxMembers: maxMembers,
      joinedMembersCount: 1,
      currentRound: 1,
      totalRounds: maxMembers,
      totalPot: isKind ? (productValue ?? contributionAmount * maxMembers) : contributionAmount * maxMembers,
      nextRecipient: '${_user.name} (You)',
      nextDrawDate: DateTime.now().add(const Duration(days: 7)),
      isJoined: true,
      members: [
        MemberModel(
          id: _user.id,
          name: '${_user.name} (You)',
          turnNumber: 1,
          hasReceivedPot: false,
          paymentStatus: 'Paid',
          amountContributed: contributionAmount,
        ),
      ],
      schedule: [
        ScheduleEntryModel(
          roundNumber: 1,
          date: DateTime.now().add(const Duration(days: 7)),
          recipientName: '${_user.name} (You)',
          status: 'Current',
        ),
      ],
      productName: productName,
      productDescription: isKind ? description : null,
      productValue: productValue,
      productIcon: productIcon,
    );

    _ekubs.insert(0, newEkub);

    // Create creation transaction
    final newTxn = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ekubId: newEkub.id,
      ekubName: newEkub.name,
      type: 'Ekub Creation Fee',
      amount: -contributionAmount,
      date: DateTime.now(),
      status: 'Successful',
      description: 'Created new $category Ekub: ${newEkub.name}. Initial round deposit recorded.',
    );

    _transactions.insert(0, newTxn);

    notifyListeners();
    return newEkub;
  }

  /// Action: Record a Contribution
  bool recordContribution({
    required String ekubId,
    required double amount,
  }) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index == -1) return false;

    final ekub = _ekubs[index];

    // Update total pot in state
    final updatedEkub = ekub.copyWith(
      totalPot: ekub.totalPot + amount,
    );
    _ekubs[index] = updatedEkub;

    final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Record Transaction
    _transactions.insert(
      0,
      TransactionModel(
        id: txnId,
        ekubId: ekub.id,
        ekubName: ekub.name,
        type: 'Contribution Deposit',
        amount: -amount,
        date: DateTime.now(),
        status: 'Successful',
        description: 'Round ${ekub.currentRound} contribution deposit for ${ekub.name}.',
      ),
    );

    // Record Contribution
    _contributions.insert(
      0,
      ContributionModel(
        id: 'cnt_${DateTime.now().millisecondsSinceEpoch}',
        ekubId: ekub.id,
        ekubName: ekub.name,
        roundNumber: ekub.currentRound,
        amount: amount,
        date: DateTime.now(),
        status: 'Paid',
        transactionId: txnId,
      ),
    );

    notifyListeners();
    return true;
  }

  // Profile actions
  void toggleNotifications(bool enabled) {
    _user.notificationsEnabled = enabled;
    notifyListeners();
  }
}
