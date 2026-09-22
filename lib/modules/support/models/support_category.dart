import 'package:equatable/equatable.dart';

class SupportCategory extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? icon;
  final bool isActive;

  const SupportCategory({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory SupportCategory.fromJson(Map<String, dynamic> json) =>
      SupportCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name, code, description, icon, isActive];
}
