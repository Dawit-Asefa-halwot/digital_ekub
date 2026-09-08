import 'dart:math';
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/draw_result_model.dart';
import '../models/audit_event_model.dart';
import '../services/ekub_state_service.dart';

/// Dedicated service conducting Ekub Lucky Draws and managing winner exclusions.
class EkubDrawService {
  static final EkubDrawService instance = EkubDrawService._internal();
  EkubDrawService._internal();

  /// Conducts a random lucky draw for the specified Ekub among ELIGIBLE members only.
  ///
  /// CRITICAL WINNER RULE:
  /// Previous round winners are excluded from entering future draws, but MUST continue
  /// contributing every round until all members have won.
  DrawResultModel? runLuckyDraw(String ekubId) {
    final ekub = EkubStateService.instance.allEkubs.firstWhere((e) => e.id == ekubId);

    if (ekub.isClosed || ekub.isCompleted) {
      return null; // Closed Ekubs cannot run draws
    }

    // Filter eligible members: Must be active members who HAVE NOT won a previous round
    final eligibleMembers = ekub.members.where((m) => !ekub.wonMemberIds.contains(m.id)).toList();

    if (eligibleMembers.isEmpty) {
      return null; // All members have won or no members available
    }

    // Random selection among ELIGIBLE members
    final randomIndex = Random().nextInt(eligibleMembers.length);
    final winner = eligibleMembers[randomIndex];

    // Record winner ID in wonMemberIds
    final updatedWonIds = List<String>.from(ekub.wonMemberIds)..add(winner.id);

    // Check if ALL members have now won once -> Trigger Ekub Closure!
    final bool isClosedNow = updatedWonIds.length >= ekub.members.length;

    // Create Audit Log Event
    final auditEvent = AuditEventModel(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      ekubId: ekub.id,
      title: isClosedNow ? 'Final Round Draw & Ekub Closed' : 'Round ${ekub.currentRound} Winner Drawn',
      description: isClosedNow
          ? '🎉 Final Draw Complete! ${winner.name} won Round ${ekub.currentRound}. All members have now won once. EKUB IS CLOSED.'
          : '🎉 ${winner.name} won Round ${ekub.currentRound} draw (${ekub.isInKind ? ekub.productName : "${ekub.totalPot.toStringAsFixed(0)} ETB"}).',
      timestamp: DateTime.now(),
      icon: isClosedNow ? Icons.lock_clock_rounded : Icons.workspace_premium_rounded,
    );

    // Update Ekub in Central State
    EkubStateService.instance.updateEkubDrawResult(
      ekubId: ekubId,
      winner: winner,
      updatedWonIds: updatedWonIds,
      isClosedNow: isClosedNow,
      auditEvent: auditEvent,
    );

    return DrawResultModel(
      roundNumber: ekub.currentRound,
      ekubId: ekub.id,
      ekubName: ekub.name,
      winnerId: winner.id,
      winnerName: winner.name,
      potAmount: ekub.totalPot,
      productWon: ekub.isInKind ? ekub.productName : null,
      drawDate: DateTime.now(),
      eligibleMembersCount: eligibleMembers.length,
      isEkubClosedNow: isClosedNow,
    );
  }
}
