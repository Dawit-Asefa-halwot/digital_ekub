import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ekub_model.dart';
import '../models/member_model.dart';
import '../models/contribution_model.dart';
import '../models/transaction_model.dart';
import '../models/schedule_model.dart';
import '../models/audit_event_model.dart';
import '../data/mock_data.dart';

/// Central state management service for Digital Ekub prototype.
class EkubStateService extends ChangeNotifier {
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
      final matchesSearch = _searchQuery.isEmpty ||
          ekub.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ekub.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ekub.productName != null && ekub.productName!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' || ekub.category == _selectedCategory;
      final matchesFrequency = _selectedFrequencyFilter == 'All' || ekub.frequency == _selectedFrequencyFilter;

      return matchesSearch && matchesCategory && matchesFrequency;
    }).toList();
  }

  List<EkubModel> get joinedEkubs => _ekubs.where((e) => e.isJoined).toList();

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setFrequencyFilter(String frequency) {
    _selectedFrequencyFilter = frequency;
    notifyListeners();
  }

  /// CRITICAL SAFEGUARD: Prevents duplicate contributions for same user + Ekub + round
  bool isAlreadyPaid(String userId, String ekubId, int roundNumber) {
    return _contributions.any(
      (c) => c.ekubId == ekubId && c.roundNumber == roundNumber && c.status == 'Paid',
    );
  }

  /// Action: Join an Ekub
  bool joinEkub(String ekubId) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index == -1) return false;

    final ekub = _ekubs[index];
    if (ekub.isJoined || ekub.isClosed) return false; // Duplicate join / Closed Ekub prevention

    final updatedEkub = ekub.copyWith(
      isJoined: true,
      joinedMembersCount: ekub.joinedMembersCount + 1,
    );

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

    // Add Audit Log
    updatedEkub.auditLogs.insert(
      0,
      AuditEventModel(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        ekubId: ekub.id,
        title: 'Member Joined',
        description: '${_user.name} joined ${ekub.name}.',
        timestamp: DateTime.now(),
        icon: Icons.person_add_rounded,
      ),
    );

    _ekubs[index] = updatedEkub;

    final newTxn = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      referenceId: 'TXN-TEL-${Random().nextInt(89999) + 10000}',
      userId: _user.id,
      ekubId: ekub.id,
      ekubName: ekub.name,
      type: 'Ekub Membership Joined',
      amount: -ekub.contributionAmount,
      date: DateTime.now(),
      status: 'successful',
      description: 'Joined ${ekub.name}. Initial round deposit recorded locally.',
    );

    _transactions.insert(0, newTxn);

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
      auditLogs: [
        AuditEventModel(
          id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
          ekubId: 'ekub_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Ekub Created',
          description: '$name created by ${_user.name}.',
          timestamp: DateTime.now(),
          icon: Icons.create_new_folder_rounded,
        ),
      ],
      productName: productName,
      productDescription: isKind ? description : null,
      productValue: productValue,
      productIcon: productIcon,
    );

    _ekubs.insert(0, newEkub);

    final newTxn = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      referenceId: 'TXN-CBE-${Random().nextInt(89999) + 10000}',
      userId: _user.id,
      ekubId: newEkub.id,
      ekubName: newEkub.name,
      type: 'Ekub Creation Fee',
      amount: -contributionAmount,
      date: DateTime.now(),
      status: 'successful',
      description: 'Created new $category Ekub: ${newEkub.name}. Initial round deposit recorded.',
    );

    _transactions.insert(0, newTxn);

    notifyListeners();
    return newEkub;
  }

  /// Action: Record Contribution with Payment Service Result
  void recordContributionWithTxn({
    required String ekubId,
    required double amount,
    required TransactionModel transaction,
  }) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index == -1) return;

    final ekub = _ekubs[index];

    final updatedEkub = ekub.copyWith(
      totalPot: ekub.totalPot + amount,
    );

    // Audit log
    updatedEkub.auditLogs.insert(
      0,
      AuditEventModel(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        ekubId: ekub.id,
        title: 'Contribution Recorded',
        description: '${_user.name} paid ${amount.toStringAsFixed(0)} ETB for Round ${ekub.currentRound} via ${transaction.paymentMethod.name}.',
        timestamp: DateTime.now(),
        icon: Icons.check_circle_outline_rounded,
      ),
    );

    _ekubs[index] = updatedEkub;
    _transactions.insert(0, transaction);

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
        transactionId: transaction.id,
      ),
    );

    notifyListeners();
  }

  /// Add failed or arbitrary transaction
  void addTransaction(TransactionModel txn) {
    _transactions.insert(0, txn);
    notifyListeners();
  }

  /// Update Ekub after Lucky Draw Execution
  void updateEkubDrawResult({
    required String ekubId,
    required MemberModel winner,
    required List<String> updatedWonIds,
    required bool isClosedNow,
    required AuditEventModel auditEvent,
  }) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index == -1) return;

    final ekub = _ekubs[index];

    final updatedEkub = ekub.copyWith(
      currentRound: isClosedNow ? ekub.currentRound : ekub.currentRound + 1,
      nextRecipient: isClosedNow ? 'None (Ekub Closed)' : winner.name,
      isCompleted: isClosedNow,
      isClosed: isClosedNow,
      wonMemberIds: updatedWonIds,
    );

    updatedEkub.auditLogs.insert(0, auditEvent);
    _ekubs[index] = updatedEkub;

    notifyListeners();
  }
}
