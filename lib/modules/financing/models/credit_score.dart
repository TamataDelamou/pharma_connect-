import 'package:equatable/equatable.dart';

class CreditScore extends Equatable {
  final String id;
  final String pharmacyId;
  final int score;
  final String rating; // excellent, good, fair, poor, bad
  final DateTime lastUpdated;
  final Map<String, dynamic> factors;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const CreditScore({
    required this.id,
    required this.pharmacyId,
    required this.score,
    required this.rating,
    required this.lastUpdated,
    this.factors = const {},
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  CreditScore copyWith({
    String? id,
    String? pharmacyId,
    int? score,
    String? rating,
    DateTime? lastUpdated,
    Map<String, dynamic>? factors,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return CreditScore(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      score: score ?? this.score,
      rating: rating ?? this.rating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      factors: factors ?? this.factors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    'score': score,
    'rating': rating,
    'last_updated': lastUpdated.toIso8601String(),
    'factors': factors,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory CreditScore.fromJson(Map<String, dynamic> json) => CreditScore(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    score: json['score'] as int,
    rating: json['rating'] as String,
    lastUpdated: DateTime.parse(json['last_updated'] as String),
    factors: json['factors'] as Map<String, dynamic>? ?? {},
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    score,
    rating,
    lastUpdated,
    factors,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];

  String get ratingLabel {
    switch (rating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Bon';
      case 'fair':
        return 'Moyen';
      case 'poor':
        return 'Faible';
      case 'bad':
        return 'Mauvais';
      default:
        return rating;
    }
  }
}
