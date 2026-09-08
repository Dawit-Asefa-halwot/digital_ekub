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

  factory EkubModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toUpperCase() ?? 'POPULAR';
    String categoryName = 'Popular';
    if (typeStr == 'GROUP') categoryName = 'Group';
    if (typeStr == 'CORPORATE') categoryName = 'Corporate';
    if (typeStr == 'IN_KIND') categoryName = 'In-kind';

    final freqStr = json['frequency']?.toString().toUpperCase() ?? 'WEEKLY';
    String freqName = 'Weekly';
    if (freqStr == 'DAILY') freqName = 'Daily';
    if (freqStr == 'MONTHLY') freqName = 'Monthly';

    final membersList = (json['members'] as List?)
            ?.map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    final drawResultsList = json['drawResults'] as List?;
    final wonIds = <String>[];
    String recipientName = 'To be drawn';

    if (drawResultsList != null && drawResultsList.isNotEmpty) {
      final lastDraw = drawResultsList.last as Map<String, dynamic>;
      final winnerObj = lastDraw['winner'] as Map<String, dynamic>?;
      if (winnerObj != null && winnerObj['fullName'] != null) {
        recipientName = winnerObj['fullName'] as String;
      }
      for (final dr in drawResultsList) {
        final wId = (dr as Map<String, dynamic>)['winnerId'] as String?;
        if (wId != null) wonIds.add(wId);
      }
    }

    final scheduleList = <ScheduleEntryModel>[];
    if (drawResultsList != null) {
      for (final dr in drawResultsList) {
        final dMap = dr as Map<String, dynamic>;
        final winnerObj = dMap['winner'] as Map<String, dynamic>?;
        scheduleList.add(ScheduleEntryModel(
          roundNumber: dMap['roundNumber'] as int? ?? 1,
          date: dMap['createdAt'] != null
              ? DateTime.parse(dMap['createdAt'] as String)
              : DateTime.now(),
          recipientName: winnerObj?['fullName'] as String? ?? 'Winner',
          status: 'Completed',
        ));
      }
    }

    final statusStr = json['status']?.toString().toUpperCase() ?? 'RECRUITING';
    final isComp = statusStr == 'COMPLETED';
    final isClsd = statusStr == 'CANCELLED';

    final membersCount = json['_count']?['members'] as int? ??
        json['joinedMembersCount'] as int? ??
        membersList.length;

    final amount = (json['contributionAmount'] as num?)?.toDouble() ?? 0.0;
    final maxM = json['memberLimit'] as int? ?? json['maxMembers'] as int? ?? 10;
    final pot = (json['totalPot'] as num?)?.toDouble() ?? (amount * membersCount);

    DateTime drawDate = DateTime.now().add(const Duration(days: 7));
    if (json['nextDrawDate'] != null) {
      drawDate = DateTime.parse(json['nextDrawDate'] as String);
    }

    return EkubModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Digital Ekub',
      description: json['description'] as String? ?? '',
      category: categoryName,
      isInKind: typeStr == 'IN_KIND' || json['isInKind'] == true,
      contributionAmount: amount,
      frequency: freqName,
      maxMembers: maxM,
      joinedMembersCount: membersCount,
      currentRound: json['currentRound'] as int? ?? 1,
      totalRounds: json['totalRounds'] as int? ?? maxM,
      totalPot: pot,
      nextRecipient: recipientName,
      nextDrawDate: drawDate,
      isJoined: json['isJoined'] as bool? ?? false,
      isCompleted: isComp,
      isClosed: isClsd,
      members: membersList,
      schedule: scheduleList,
      wonMemberIds: wonIds,
      auditLogs: [],
      productName: json['productName'] as String?,
      productDescription: json['productDescription'] as String?,
      productValue: (json['productValue'] as num?)?.toDouble(),
      productIcon: json['productImageUrl'] as String? ?? json['productIcon'] as String?,
    );
  }
}
