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
