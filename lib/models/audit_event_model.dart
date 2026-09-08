import 'package:flutter/material.dart';

/// Audit Trail Log Event model for Ekub history.
class AuditEventModel {
  final String id;
  final String ekubId;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;

  AuditEventModel({
    required this.id,
    required this.ekubId,
    required this.title,
    required this.description,
    required this.timestamp,
    this.icon = Icons.history_rounded,
  });
}
