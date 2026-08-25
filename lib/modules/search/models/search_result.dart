import '../../../shared/models/product.dart';
import 'availability_result.dart';

class SearchResult {
  final Product product;
  final AvailabilityResult? availability;
  final double relevanceScore;
  final List<String> matchedTerms;

  SearchResult({
    required this.product,
    this.availability,
    this.relevanceScore = 0,
    this.matchedTerms = const [],
  });

  bool get isAvailable => availability?.hasAvailableStock ?? false;
  int get availableCount => availability?.availableCount ?? 0;
  int? get bestPrice => availability?.bestPrice?.price;
  String? get nearestPharmacy => availability?.nearest?.pharmacy.name;

  SearchResult copyWith({
    Product? product,
    AvailabilityResult? availability,
    double? relevanceScore,
    List<String>? matchedTerms,
  }) {
    return SearchResult(
      product: product ?? this.product,
      availability: availability ?? this.availability,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      matchedTerms: matchedTerms ?? this.matchedTerms,
    );
  }
}
