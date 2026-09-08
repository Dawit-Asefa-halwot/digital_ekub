import 'member_model.dart';
import 'schedule_model.dart';
import 'audit_event_model.dart';

/// Main Ekub Model supporting Cash and In-Kind rotating savings groups.
class EkubModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'Popular', 'Group', 'Corporate', 'In-kind'
  final bool isInKind;
  final double contributionAmount;
  final String frequency; // 'Daily', 'Weekly', 'Monthly'
  final int maxMembers;
  int joinedMembersCount;
  int currentRound;
  final int totalRounds;
  double totalPot;
  String nextRecipient;
  DateTime nextDrawDate;
  bool isJoined;
  bool isCompleted;
  bool isClosed;
  final List<MemberModel> members;
  final List<ScheduleEntryModel> schedule;
  final List<String> wonMemberIds; // Track members who have won a draw
  final List<AuditEventModel> auditLogs;

  // In-Kind specific product fields
  final String? productName;
  final String? productDescription;
  final double? productValue;
  final String? productIcon; // 'tv', 'washing_machine', 'refrigerator', 'oven', 'smartphone', 'laptop'

  EkubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isInKind = false,
    required this.contributionAmount,
    required this.frequency,
    required this.maxMembers,
    required this.joinedMembersCount,
    required this.currentRound,
    required this.totalRounds,
    required this.totalPot,
    required this.nextRecipient,
    required this.nextDrawDate,
    this.isJoined = false,
    this.isCompleted = false,
    this.isClosed = false,
    required this.members,
    required this.schedule,
    List<String>? wonMemberIds,
    List<AuditEventModel>? auditLogs,
    this.productName,
    this.productDescription,
    this.productValue,
    this.productIcon,
  })  : wonMemberIds = wonMemberIds ?? [],
        auditLogs = auditLogs ?? [];

  /// Copy helper to mutate state cleanly
  EkubModel copyWith({
    bool? isJoined,
    int? joinedMembersCount,
    double? totalPot,
    int? currentRound,
    String? nextRecipient,
    bool? isCompleted,
    bool? isClosed,
    List<String>? wonMemberIds,
    List<AuditEventModel>? auditLogs,
  }) {
    return EkubModel(
      id: id,
      name: name,
      description: description,
      category: category,
      isInKind: isInKind,
      contributionAmount: contributionAmount,
      frequency: frequency,
      maxMembers: maxMembers,
      joinedMembersCount: joinedMembersCount ?? this.joinedMembersCount,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds,
      totalPot: totalPot ?? this.totalPot,
      nextRecipient: nextRecipient ?? this.nextRecipient,
      nextDrawDate: nextDrawDate,
      isJoined: isJoined ?? this.isJoined,
      isCompleted: isCompleted ?? this.isCompleted,
      isClosed: isClosed ?? this.isClosed,
      members: members,
      schedule: schedule,
      wonMemberIds: wonMemberIds ?? this.wonMemberIds,
      auditLogs: auditLogs ?? this.auditLogs,
      productName: productName,
      productDescription: productDescription,
      productValue: productValue,
      productIcon: productIcon,
    );
  }
}
