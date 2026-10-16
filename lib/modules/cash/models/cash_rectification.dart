import 'package:equatable/equatable.dart';

/// C273 (c) : rectification rattachée à une caisse fermée, par le titulaire,
/// motif obligatoire (`cash_drawer_rectifications`). La session n'est jamais
/// modifiée ; la dernière rectification (plus grand [seq]) fait foi.
class CashRectification extends Equatable {
  final String id;
  final int seq;
  final String sessionId;

  /// Montant compté retenu avant cette rectification (fermeture ou
  /// rectification précédente).
  final int previousCountedBalance;
  final int countedBalance;

  /// Solde attendu figé à la fermeture.
  final int expectedBalance;

  /// Écart après cette rectification (compté - attendu).
  final int difference;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  const CashRectification({
    required this.id,
    required this.seq,
    required this.sessionId,
    required this.previousCountedBalance,
    required this.countedBalance,
    required this.expectedBalance,
    required this.difference,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  factory CashRectification.fromJson(Map<String, dynamic> json) =>
      CashRectification(
        id: json['id'] as String,
        seq: (json['seq'] as num).toInt(),
        sessionId: json['cash_drawer_session_id'] as String,
        previousCountedBalance: json['previous_counted_balance'] as int,
        countedBalance: json['counted_balance'] as int,
        expectedBalance: json['expected_balance'] as int,
        difference: json['difference'] as int,
        reason: json['reason'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    seq,
    sessionId,
    previousCountedBalance,
    countedBalance,
    expectedBalance,
    difference,
    reason,
    createdBy,
    createdAt,
  ];
}
