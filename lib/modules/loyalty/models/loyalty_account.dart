import 'package:equatable/equatable.dart';

class LoyaltyAccount extends Equatable {
  final String id;
  final String patientId;
  final String pharmacyId;
  final String programId;
  final int pointsBalance;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final String tier; // bronze, silver, gold, platinum
  final DateTime joinedAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;
  final String? pharmacyName;
  final String? programName;

  const LoyaltyAccount({
    required this.id,
    required this.patientId,
    required this.pharmacyId,
    required this.programId,
    this.pointsBalance = 0,
    this.totalPointsEarned = 0,
    this.totalPointsRedeemed = 0,
    this.tier = 'bronze',
    required this.joinedAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.pharmacyName,
    this.programName,
  });

  LoyaltyAccount copyWith({
    String? id,
    String? patientId,
    String? pharmacyId,
    String? programId,
    int? pointsBalance,
    int? totalPointsEarned,
    int? totalPointsRedeemed,
    String? tier,
    DateTime? joinedAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? pharmacyName,
    String? programName,
  }) {
    return LoyaltyAccount(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      programId: programId ?? this.programId,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsRedeemed: totalPointsRedeemed ?? this.totalPointsRedeemed,
      tier: tier ?? this.tier,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      programName: programName ?? this.programName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'pharmacy_id': pharmacyId,
    'program_id': programId,
    'points_balance': pointsBalance,
    'total_points_earned': totalPointsEarned,
    'total_points_redeemed': totalPointsRedeemed,
    'tier': tier,
    'joined_at': joinedAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    programId: json['program_id'] as String,
    pointsBalance: json['points_balance'] as int? ?? 0,
    totalPointsEarned: json['total_points_earned'] as int? ?? 0,
    totalPointsRedeemed: json['total_points_redeemed'] as int? ?? 0,
    tier: json['tier'] as String? ?? 'bronze',
    joinedAt: DateTime.parse(json['joined_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    pharmacyName: json['pharmacies'] != null
        ? (json['pharmacies'] as Map<String, dynamic>)['name'] as String?
        : null,
    programName: json['programs'] != null
        ? (json['programs'] as Map<String, dynamic>)['name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    pharmacyId,
    programId,
    pointsBalance,
    totalPointsEarned,
    totalPointsRedeemed,
    tier,
    joinedAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    pharmacyName,
    programName,
  ];

  String get tierLabel {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Argent';
      case 'gold':
        return 'Or';
      case 'platinum':
        return 'Platine';
      default:
        return tier;
    }
  }

  String get tierEmoji {
    switch (tier) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      default:
        return '⭐';
    }
  }

  int get pointsToNextTier {
    switch (tier) {
      case 'bronze':
        return 200 - pointsBalance;
      case 'silver':
        return 500 - pointsBalance;
      case 'gold':
        return 1000 - pointsBalance;
      default:
        return 0;
    }
  }
}
