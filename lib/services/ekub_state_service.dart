import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ekub_model.dart';
import '../models/member_model.dart';
import '../models/contribution_model.dart';
import '../models/transaction_model.dart';
import '../models/audit_event_model.dart';
import '../models/payment_method_enum.dart';
import '../data/mock_data.dart';
import 'ekub_api_service.dart';
import 'contribution_api_service.dart';
import 'payment_api_service.dart';
import 'notification_api_service.dart';
import 'reminder_api_service.dart';
import 'api_service.dart';

/// Central State Management Service connecting Flutter Application to NestJS REST API
class EkubStateService extends ChangeNotifier {
  static final EkubStateService instance = EkubStateService._internal();
  EkubStateService._internal() {
    refreshAllData();
  }

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel _user = MockData.currentUser;
  UserModel get user => _user;

  List<EkubModel> _ekubs = List.from(MockData.initialEkubs);
  List<EkubModel> get allEkubs => List.unmodifiable(_ekubs);

  List<TransactionModel> _transactions = List.from(MockData.initialTransactions);
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<ContributionModel> _contributions = List.from(MockData.initialContributions);
  List<ContributionModel> get contributions => List.unmodifiable(_contributions);

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> get reminders => List.unmodifiable(_reminders);

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

      final matchesCategory = _selectedCategory == 'All' || ekub.category.toUpperCase() == _selectedCategory.toUpperCase();
      final matchesFrequency = _selectedFrequencyFilter == 'All' || ekub.frequency.toUpperCase() == _selectedFrequencyFilter.toUpperCase();

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
    fetchEkubsFromApi();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    fetchEkubsFromApi();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    fetchEkubsFromApi();
    notifyListeners();
  }

  void setFrequencyFilter(String frequency) {
    _selectedFrequencyFilter = frequency;
    fetchEkubsFromApi();
    notifyListeners();
  }

  /// Refresh all data from NestJS REST API
  Future<void> refreshAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchEkubsFromApi(),
        fetchUserContributionsFromApi(),
        fetchUserTransactionsFromApi(),
        fetchNotificationsFromApi(),
        fetchRemindersFromApi(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Ekubs from NestJS REST API (`GET /ekubs`)
  Future<void> fetchEkubsFromApi() async {
    try {
      final apiEkubs = await EkubApiService.discoverEkubs(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        frequency: _selectedFrequencyFilter != 'All' ? _selectedFrequencyFilter : null,
      );

      if (apiEkubs.isNotEmpty) {
        _ekubs = apiEkubs;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch User Contributions from NestJS REST API (`GET /contributions/me`)
  Future<void> fetchUserContributionsFromApi() async {
    try {
      final data = await ContributionApiService.getUserContributions();
      if (data.isNotEmpty) {
        _contributions = data.map((json) {
          final ekub = json['ekub'] as Map<String, dynamic>?;
          return ContributionModel(
            id: json['id'] as String,
            ekubId: json['ekubId'] as String,
            ekubName: ekub?['name'] as String? ?? 'Ekub Group',
            roundNumber: json['roundNumber'] as int? ?? 1,
            amount: double.tryParse(json['amount'].toString()) ?? 0.0,
            date: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
            status: json['status'] == 'PAID' || json['status'] == 'SUCCESSFUL' ? 'Paid' : 'Pending',
            transactionId: json['transactionId'] as String? ?? 'TXN-${json['id']}',
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch User Transactions from NestJS REST API (`GET /payments/me`)
  Future<void> fetchUserTransactionsFromApi() async {
    try {
      final data = await PaymentApiService.getUserTransactions();
      if (data.isNotEmpty) {
        _transactions = data.map((json) {
          final ekub = json['ekub'] as Map<String, dynamic>?;
          final methodStr = json['paymentMethod']?.toString() ?? 'TELEBIRR';
          PaymentMethod method = PaymentMethod.telebirr;
          if (methodStr.contains('CBE')) method = PaymentMethod.cbeBirr;
          if (methodStr.contains('BANK')) method = PaymentMethod.bankTransfer;

          return TransactionModel(
            id: json['id'] as String,
            referenceId: json['referenceId'] as String? ?? 'TXN-REF',
            userId: json['userId'] as String? ?? '',
            ekubId: json['ekubId'] as String? ?? '',
            ekubName: ekub?['name'] as String? ?? 'Ekub Group',
            type: json['type']?.toString() ?? 'Deposit',
            amount: double.tryParse(json['amount'].toString()) ?? 0.0,
            date: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
            status: json['status']?.toString().toLowerCase() ?? 'successful',
            paymentMethod: method,
            description: json['description'] as String? ?? 'Payment transaction',
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch Notifications from NestJS REST API (`GET /notifications/me`)
  Future<void> fetchNotificationsFromApi() async {
    try {
      final data = await NotificationApiService.getUserNotifications();
      _notifications = data;
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch Reminders from NestJS REST API (`GET /reminders/me`)
  Future<void> fetchRemindersFromApi() async {
    try {
      final data = await ReminderApiService.getUserReminders();
      _reminders = data;
      notifyListeners();
    } catch (_) {}
  }

  /// Mark Notification as Read
  Future<void> markNotificationRead(String id) async {
    try {
      await NotificationApiService.markAsRead(id);
      await fetchNotificationsFromApi();
    } catch (_) {}
  }

  /// Mark All Notifications as Read
  Future<void> markAllNotificationsRead() async {
    try {
      await NotificationApiService.markAllAsRead();
      await fetchNotificationsFromApi();
    } catch (_) {}
  }

  /// Action: Join an Ekub via REST API (`POST /ekubs/:id/join`)
  Future<bool> joinEkub(String ekubId) async {
    try {
      await EkubApiService.joinEkub(ekubId);
      await refreshAllData();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Action: Create a new Ekub via REST API (`POST /ekubs`)
  Future<EkubModel?> createEkub({
    required String name,
    required String category,
    required double contributionAmount,
    required String frequency,
    required int maxMembers,
    required String description,
    String? productName,
    double? productValue,
    String? productIcon,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description,
        'category': category == 'In-kind' ? 'IN_KIND' : category.toUpperCase(),
        'type': category == 'In-kind' ? 'IN_KIND' : 'CASH',
        'contributionAmount': contributionAmount,
        'frequency': frequency.toUpperCase(),
        'maxMembers': maxMembers,
        'totalRounds': maxMembers,
      };

      if (category == 'In-kind') {
        body['productName'] = productName ?? name;
        body['productDescription'] = description;
        body['productValue'] = productValue ?? (contributionAmount * maxMembers);
        body['productImageUrl'] = productIcon ?? 'assets/products/samsung_tv.png';
      }

      final data = await ApiService.post('/ekubs', body: body);
      final createdModel = EkubModel.fromJson(data as Map<String, dynamic>);
      await refreshAllData();
      return createdModel;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Action: Record Contribution & Payment via REST API (`POST /ekubs/:id/contributions` & `POST /payments`)
  Future<bool> processContributionAndPayment({
    required String ekubId,
    required double amount,
    required String paymentMethodStr,
  }) async {
    try {
      // 1. Submit contribution deposit to REST API
      final contribRes = await ContributionApiService.createContribution(ekubId, amount: amount);
      final contribId = contribRes['id'] as String;

      // 2. Initiate simulated payment via REST API
      final paymentMethodEnum = paymentMethodStr.replaceAll(' ', '_').toUpperCase();
      await PaymentApiService.processPayment(
        contributionId: contribId,
        paymentMethod: paymentMethodEnum.contains('TELE') ? 'TELEBIRR' : (paymentMethodEnum.contains('CBE') ? 'CBE_BIRR' : 'BANK_TRANSFER'),
        simulateOutcome: 'SUCCESS',
      );

      // 3. Refresh state from backend
      await refreshAllData();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if user has already paid for a specific Ekub round
  bool isAlreadyPaid(String userIdOrEkubId, [String? ekubId, int? roundNumber]) {
    final targetEkubId = ekubId ?? userIdOrEkubId;
    return _contributions.any((c) => c.ekubId == targetEkubId && c.status == 'Paid');
  }

  /// Update Ekub draw result state locally
  void updateEkubDrawResult({
    required String ekubId,
    required MemberModel winner,
    required List<String> updatedWonIds,
    required bool isClosedNow,
    required AuditEventModel auditEvent,
  }) {
    final index = _ekubs.indexWhere((e) => e.id == ekubId);
    if (index != -1) {
      final ekub = _ekubs[index];
      final updatedEkub = ekub.copyWith(
        wonMemberIds: updatedWonIds,
        isClosed: isClosedNow,
        nextRecipient: winner.name,
      );
      _ekubs[index] = updatedEkub;
      notifyListeners();
    }
  }
}
