import '../models/user_model.dart';
import '../models/ekub_model.dart';
import '../models/member_model.dart';
import '../models/contribution_model.dart';
import '../models/transaction_model.dart';
import '../models/schedule_model.dart';
import '../models/payment_method_enum.dart';
import '../models/audit_event_model.dart';

/// Centralized mock data seed for Digital Ekub prototype.
class MockData {
  static UserModel currentUser = UserModel(
    id: 'user_101',
    name: 'Dawit Asefa',
    phone: '+251 91 123 4567',
    email: 'dawit.asefa@ekub.et',
    role: UserRole.admin,
    isVerified: true,
    notificationsEnabled: true,
  );

  static List<EkubModel> initialEkubs = [
    // 1. Joined Cash Ekub
    EkubModel(
      id: 'ekub_01',
      name: 'Family & Friends Ekub',
      description: 'Weekly rotating savings group among close family members and trusted friends.',
      category: 'Popular',
      isInKind: false,
      contributionAmount: 5000,
      frequency: 'Weekly',
      maxMembers: 12,
      joinedMembersCount: 12,
      currentRound: 4,
      totalRounds: 12,
      totalPot: 60000,
      nextRecipient: 'Abebe Tadesse',
      nextDrawDate: DateTime.now().add(const Duration(days: 6)),
      isJoined: true,
      wonMemberIds: ['m1', 'm3'], // Dawit (m1) and Bethlehem (m3) won previous rounds!
      members: [
        MemberModel(id: 'user_101', name: 'Dawit Asefa (You)', turnNumber: 2, hasReceivedPot: true, paymentStatus: 'Paid', amountContributed: 20000),
        MemberModel(id: 'm2', name: 'Abebe Tadesse', turnNumber: 4, hasReceivedPot: false, paymentStatus: 'Paid', amountContributed: 20000),
        MemberModel(id: 'm3', name: 'Bethlehem Worku', turnNumber: 1, hasReceivedPot: true, paymentStatus: 'Paid', amountContributed: 20000),
        MemberModel(id: 'm4', name: 'Chala Kebede', turnNumber: 3, hasReceivedPot: false, paymentStatus: 'Pending', amountContributed: 15000),
        MemberModel(id: 'm5', name: 'Eleni Haile', turnNumber: 5, hasReceivedPot: false, paymentStatus: 'Pending', amountContributed: 15000),
      ],
      schedule: [
        ScheduleEntryModel(roundNumber: 1, date: DateTime.now().subtract(const Duration(days: 21)), recipientName: 'Bethlehem Worku', status: 'Completed'),
        ScheduleEntryModel(roundNumber: 2, date: DateTime.now().subtract(const Duration(days: 14)), recipientName: 'Dawit Asefa (You)', status: 'Completed'),
        ScheduleEntryModel(roundNumber: 3, date: DateTime.now().subtract(const Duration(days: 7)), recipientName: 'Chala Kebede', status: 'Completed'),
        ScheduleEntryModel(roundNumber: 4, date: DateTime.now().add(const Duration(days: 6)), recipientName: 'Abebe Tadesse', status: 'Current'),
        ScheduleEntryModel(roundNumber: 5, date: DateTime.now().add(const Duration(days: 13)), recipientName: 'Eleni Haile', status: 'Scheduled'),
      ],
      auditLogs: [
        AuditEventModel(id: 'a1', ekubId: 'ekub_01', title: 'Ekub Created', description: 'Family & Friends Ekub initialized.', timestamp: DateTime.now().subtract(const Duration(days: 30))),
        AuditEventModel(id: 'a2', ekubId: 'ekub_01', title: 'Member Joined', description: 'Dawit Asefa joined Ekub.', timestamp: DateTime.now().subtract(const Duration(days: 28))),
        AuditEventModel(id: 'a3', ekubId: 'ekub_01', title: 'Round 2 Winner', description: 'Dawit Asefa won Round 2 draw (60,000 ETB).', timestamp: DateTime.now().subtract(const Duration(days: 14))),
      ],
    ),

    // 2. Joined Corporate Ekub
    EkubModel(
      id: 'ekub_02',
      name: 'Bole Tech Entrepreneurs',
      description: 'Monthly business Ekub for technology founders and Bole startup professionals.',
      category: 'Corporate',
      isInKind: false,
      contributionAmount: 10000,
      frequency: 'Monthly',
      maxMembers: 10,
      joinedMembersCount: 10,
      currentRound: 8,
      totalRounds: 10,
      totalPot: 100000,
      nextRecipient: 'Tigist Alemayehu',
      nextDrawDate: DateTime.now().add(const Duration(days: 18)),
      isJoined: true,
      wonMemberIds: ['user_101'],
      members: [
        MemberModel(id: 'user_101', name: 'Dawit Asefa (You)', turnNumber: 3, hasReceivedPot: true, paymentStatus: 'Paid', amountContributed: 80000),
        MemberModel(id: 'm11', name: 'Tigist Alemayehu', turnNumber: 8, hasReceivedPot: false, paymentStatus: 'Paid', amountContributed: 80000),
      ],
      schedule: [
        ScheduleEntryModel(roundNumber: 8, date: DateTime.now().add(const Duration(days: 18)), recipientName: 'Tigist Alemayehu', status: 'Current'),
      ],
      auditLogs: [],
    ),

    // 3. Featured In-Kind Ekub: Samsung Smart TV
    EkubModel(
      id: 'ekub_ik_01',
      name: 'Samsung 55" Smart TV Ekub',
      description: 'Get your desired 4K UHD TV through an affordable rotating contribution plan. Contribute monthly with a group and receive the product when it is your turn.',
      category: 'In-kind',
      isInKind: true,
      productName: 'Samsung 55" 4K Smart TV',
      productDescription: 'Crystal UHD 4K Resolution, HDR10+, Smart Hub with Tizen OS & AirPlay support.',
      productValue: 15000,
      productIcon: 'tv',
      contributionAmount: 1500,
      frequency: 'Monthly',
      maxMembers: 10,
      joinedMembersCount: 7,
      currentRound: 1,
      totalRounds: 10,
      totalPot: 15000,
      nextRecipient: 'First Draw Recipient',
      nextDrawDate: DateTime.now().add(const Duration(days: 12)),
      isJoined: false,
      members: [
        MemberModel(id: 'm20', name: 'Solomon Kassa', turnNumber: 1, hasReceivedPot: false, paymentStatus: 'Paid', amountContributed: 1500),
        MemberModel(id: 'm21', name: 'Hana Tesfaye', turnNumber: 2, hasReceivedPot: false, paymentStatus: 'Paid', amountContributed: 1500),
      ],
      schedule: [
        ScheduleEntryModel(roundNumber: 1, date: DateTime.now().add(const Duration(days: 12)), recipientName: 'Upcoming Round 1 Draw', status: 'Current'),
      ],
    ),
  ];

  static List<TransactionModel> initialTransactions = [
    TransactionModel(
      id: 'TXN-9042',
      referenceId: 'TXN-TEL-89210',
      userId: 'user_101',
      ekubId: 'ekub_01',
      ekubName: 'Family & Friends Ekub',
      type: 'Contribution Deposit',
      paymentMethod: PaymentMethod.telebirr,
      amount: -5000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: 'successful',
      description: 'Round 4 weekly contribution deposit via Telebirr.',
    ),
    TransactionModel(
      id: 'TXN-8810',
      referenceId: 'TXN-CBE-44120',
      userId: 'user_101',
      ekubId: 'ekub_01',
      ekubName: 'Family & Friends Ekub',
      type: 'Pot Payout Received',
      paymentMethod: PaymentMethod.cbeBirr,
      amount: 60000,
      date: DateTime.now().subtract(const Duration(days: 14)),
      status: 'successful',
      description: 'Round 2 pot win payout transferred via Commercial Bank CBE Birr.',
    ),
  ];

  static List<ContributionModel> initialContributions = [
    ContributionModel(
      id: 'cnt_01',
      ekubId: 'ekub_01',
      ekubName: 'Family & Friends Ekub',
      roundNumber: 4,
      amount: 5000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Paid',
      transactionId: 'TXN-9042',
    ),
  ];
}
