import 'package:equatable/equatable.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';

class Customer extends Equatable {
  final String id;
  final String? profileId;
  final String pharmacyId;
  final String code;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final int creditLimit;
  final int balance;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const Customer({
    required this.id,
    this.profileId,
    required this.pharmacyId,
    required this.code,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.creditLimit = 0,
    this.balance = 0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  Customer copyWith({
    String? id,
    String? profileId,
    String? pharmacyId,
    String? code,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? city,
    int? creditLimit,
    int? balance,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return Customer(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      code: code ?? this.code,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (profileId != null) 'profile_id': profileId,
    'pharmacy_id': pharmacyId,
    'code': code,
    'first_name': firstName,
    'last_name': lastName,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    'credit_limit': creditLimit,
    'balance': balance,
    'is_active': isActive,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    profileId: json['profile_id'] as String?,
    pharmacyId: json['pharmacy_id'] as String,
    code: json['code'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    creditLimit: json['credit_limit'] as int? ?? 0,
    balance: json['balance'] as int? ?? 0,
    isActive: json['is_active'] as bool? ?? true,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    profileId,
    pharmacyId,
    code,
    firstName,
    lastName,
    phone,
    email,
    address,
    city,
    creditLimit,
    balance,
    isActive,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get fullName => '$firstName $lastName';

  String get balanceLabel {
    if (balance > 0) return '💰 ${CurrencyFormatter.format(balance)}';
    if (balance < 0) return '🔴 ${CurrencyFormatter.format(balance)}';
    return '⚪ ${CurrencyFormatter.format(balance)}';
  }
}
