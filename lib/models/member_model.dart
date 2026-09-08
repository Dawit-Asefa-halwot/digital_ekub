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
}
