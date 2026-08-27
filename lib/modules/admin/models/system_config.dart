class SystemConfig {
  final String id;
  final String key;
  final String value;
  final String category;
  final String? description;
  final bool isEditable;
  final DateTime updatedAt;
  final String updatedBy;

  const SystemConfig({
    required this.id,
    required this.key,
    required this.value,
    required this.category,
    this.description,
    this.isEditable = true,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) => SystemConfig(
    id: json['id'] as String,
    key: json['key'] as String,
    value: json['value'] as String,
    category: json['category'] as String,
    description: json['description'] as String?,
    isEditable: json['is_editable'] as bool? ?? true,
    updatedAt: DateTime.parse(json['updated_at'] as String),
    updatedBy: json['updated_by'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'value': value,
    'category': category,
    'description': description,
    'is_editable': isEditable,
    'updated_at': updatedAt.toIso8601String(),
    'updated_by': updatedBy,
  };

  SystemConfig copyWith({
    String? id,
    String? key,
    String? value,
    String? category,
    String? description,
    bool? isEditable,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemConfig(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      category: category ?? this.category,
      description: description ?? this.description,
      isEditable: isEditable ?? this.isEditable,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
