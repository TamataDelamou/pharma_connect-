import 'package:equatable/equatable.dart';

/// Audit Module 28 (BI), Étape 3 (05/09/2026), BI-7 : `patientId` renommé
/// `ownerId` (la colonne référence en base n'importe quel profil, jamais
/// restreinte à un patient — nom trompeur hérité) et ajout de `scope`/
/// `pharmacyId` pour porter la distinction cahier "Tableau de bord
/// officine/réseau" plutôt qu'un système strictement individuel. Voir
/// 20260905070000_analytics_module_fixes.sql pour le correctif RLS
/// correspondant.
class UserDashboard extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final List<UserDashboardPanel> panels;
  final bool isDefault;
  final String scope; // 'personal' | 'officine' | 'reseau'
  final String? pharmacyId; // requis si scope == 'officine', sinon null
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const UserDashboard({
    required this.id,
    required this.ownerId,
    required this.name,
    this.panels = const [],
    this.isDefault = false,
    this.scope = 'personal',
    this.pharmacyId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  bool get isOfficine => scope == 'officine';
  bool get isReseau => scope == 'reseau';
  bool get isPersonal => scope == 'personal';

  UserDashboard copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<UserDashboardPanel>? panels,
    bool? isDefault,
    String? scope,
    String? pharmacyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return UserDashboard(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      panels: panels ?? this.panels,
      isDefault: isDefault ?? this.isDefault,
      scope: scope ?? this.scope,
      pharmacyId: pharmacyId ?? this.pharmacyId,
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
    'owner_id': ownerId,
    'name': name,
    'layout': {'panels': panels.map((p) => p.toJson()).toList()},
    'is_default': isDefault,
    'scope': scope,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory UserDashboard.fromJson(Map<String, dynamic> json) => UserDashboard(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,
    name: json['name'] as String,
    panels: (json['layout'] as Map<String, dynamic>?)?['panels'] != null
        ? (json['layout'] as Map<String, dynamic>)['panels']
              .map(
                (p) => UserDashboardPanel.fromJson(p as Map<String, dynamic>),
              )
              .toList()
              .cast<UserDashboardPanel>()
        : [],
    isDefault: json['is_default'] as bool? ?? false,
    scope: json['scope'] as String? ?? 'personal',
    pharmacyId: json['pharmacy_id'] as String?,
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
    ownerId,
    name,
    panels,
    isDefault,
    scope,
    pharmacyId,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}

class UserDashboardPanel extends Equatable {
  final String id;
  final String widgetId;
  final int position;
  final int colSpan;
  final int rowSpan;
  final Map<String, dynamic> config;

  const UserDashboardPanel({
    required this.id,
    required this.widgetId,
    this.position = 0,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.config = const {},
  });

  UserDashboardPanel copyWith({
    String? id,
    String? widgetId,
    int? position,
    int? colSpan,
    int? rowSpan,
    Map<String, dynamic>? config,
  }) {
    return UserDashboardPanel(
      id: id ?? this.id,
      widgetId: widgetId ?? this.widgetId,
      position: position ?? this.position,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      config: config ?? this.config,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'widget_id': widgetId,
    'position': position,
    'col_span': colSpan,
    'row_span': rowSpan,
    'config': config,
  };

  factory UserDashboardPanel.fromJson(Map<String, dynamic> json) =>
      UserDashboardPanel(
        id: json['id'] as String,
        widgetId: json['widget_id'] as String,
        position: json['position'] as int? ?? 0,
        colSpan: json['col_span'] as int? ?? 1,
        rowSpan: json['row_span'] as int? ?? 1,
        config: json['config'] as Map<String, dynamic>? ?? {},
      );

  @override
  List<Object?> get props => [id, widgetId, position, colSpan, rowSpan, config];
}
