/// Result model of an Ekub Lucky Draw.
class DrawResultModel {
  final int roundNumber;
  final String ekubId;
  final String ekubName;
  final String winnerId;
  final String winnerName;
  final double potAmount;
  final String? productWon;
  final DateTime drawDate;
  final int eligibleMembersCount;
  final bool isEkubClosedNow;

  DrawResultModel({
    required this.roundNumber,
    required this.ekubId,
    required this.ekubName,
    required this.winnerId,
    required this.winnerName,
    required this.potAmount,
    this.productWon,
    required this.drawDate,
    required this.eligibleMembersCount,
    this.isEkubClosedNow = false,
  });
}
