import 'package:equatable/equatable.dart';

class KnowledgeArticle extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? category;
  final List<String> keywords;
  final bool isActive;
  final int viewCount;
  final int helpfulCount;
  final int notHelpfulCount;

  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.keywords = const [],
    this.isActive = true,
    this.viewCount = 0,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
  });

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) =>
      KnowledgeArticle(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        category: json['category'] as String?,
        keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
        isActive: json['is_active'] as bool? ?? true,
        viewCount: json['view_count'] as int? ?? 0,
        helpfulCount: json['helpful_count'] as int? ?? 0,
        notHelpfulCount: json['not_helpful_count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    category,
    keywords,
    isActive,
    viewCount,
    helpfulCount,
    notHelpfulCount,
  ];
}
