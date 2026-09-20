import 'package:equatable/equatable.dart';

class AnalyticsPanel extends Equatable {
  final String id;
  final String type; // 'kpi', 'chart', 'table', 'list'
  final String title;
  final Map<String, dynamic> config; // Chart config, query params, etc.
  final int position;

  const AnalyticsPanel({
    required this.id,
    required this.type,
    required this.title,
    this.config = const {},
    this.position = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'config': config,
    'position': position,
  };

  factory AnalyticsPanel.fromJson(Map<String, dynamic> json) => AnalyticsPanel(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    config: json['config'] as Map<String, dynamic>? ?? {},
    position: json['position'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, type, title, config, position];
}

class AnalyticsDashboard extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<AnalyticsPanel> panels;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const AnalyticsDashboard({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.panels = const [],
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  AnalyticsDashboard copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<AnalyticsPanel>? panels,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) => AnalyticsDashboard(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description ?? this.description,
    panels: panels ?? this.panels,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    if (description != null) 'description': description,
    'layout': {'panels': panels.map((p) => p.toJson()).toList()},
    'is_default': isDefault,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) =>
      AnalyticsDashboard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        panels: (json['layout'] as Map<String, dynamic>?)?['panels'] != null
            ? (json['layout'] as Map<String, dynamic>)['panels']
                  .map(
                    (p) => AnalyticsPanel.fromJson(p as Map<String, dynamic>),
                  )
                  .toList()
                  .cast<AnalyticsPanel>()
            : [],
        isDefault: json['is_default'] as bool? ?? false,
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
    userId,
    name,
    description,
    panels,
    isDefault,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}
