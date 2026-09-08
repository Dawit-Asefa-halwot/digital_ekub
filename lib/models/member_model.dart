/// Member model representing a participant in an Ekub.
class MemberModel {
  final String id;
  final String name;
  final int turnNumber;
  final bool hasReceivedPot;
  final String paymentStatus; // 'Paid' or 'Pending'
  final double amountContributed;

  MemberModel({
    required this.id,
    required this.name,
    required this.turnNumber,
    this.hasReceivedPot = false,
    this.paymentStatus = 'Pending',
    this.amountContributed = 0.0,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final userName = user?['fullName'] as String? ?? json['name'] as String? ?? 'Member';
    return MemberModel(
      id: json['userId'] as String? ?? json['id'] as String? ?? '',
      name: userName,
      turnNumber: json['turnNumber'] as int? ?? 1,
      hasReceivedPot: json['hasReceivedPot'] as bool? ?? false,
      paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
      amountContributed: (json['amountContributed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
