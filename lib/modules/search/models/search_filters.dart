import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';

class SearchFilters {
  final String? category;
  final String? manufacturer;
  final bool? onlyAvailable;
  final bool? onlyGeneric;
  final bool? onlyPrescriptionRequired;
  final double? maxPrice;
  final double? minPrice;
  final bool? onlyNearby;
  final SortOption sortBy;

  const SearchFilters({
    this.category,
    this.manufacturer,
    this.onlyAvailable,
    this.onlyGeneric,
    this.onlyPrescriptionRequired,
    this.maxPrice,
    this.minPrice,
    this.onlyNearby,
    this.sortBy = SortOption.relevance,
  });

  SearchFilters copyWith({
    String? category,
    String? manufacturer,
    bool? onlyAvailable,
    bool? onlyGeneric,
    bool? onlyPrescriptionRequired,
    double? maxPrice,
    double? minPrice,
    bool? onlyNearby,
    SortOption? sortBy,
  }) {
    return SearchFilters(
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      onlyGeneric: onlyGeneric ?? this.onlyGeneric,
      onlyPrescriptionRequired:
          onlyPrescriptionRequired ?? this.onlyPrescriptionRequired,
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      onlyNearby: onlyNearby ?? this.onlyNearby,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasFilters =>
      category != null ||
      manufacturer != null ||
      onlyAvailable == true ||
      onlyGeneric == true ||
      onlyPrescriptionRequired == true ||
      maxPrice != null ||
      minPrice != null ||
      onlyNearby == true;

  int get filterCount {
    int count = 0;
    if (category != null) count++;
    if (manufacturer != null) count++;
    if (onlyAvailable == true) count++;
    if (onlyGeneric == true) count++;
    if (onlyPrescriptionRequired == true) count++;
    if (maxPrice != null) count++;
    if (minPrice != null) count++;
    if (onlyNearby == true) count++;
    return count;
  }
}

enum SortOption { relevance, priceAsc, priceDesc, nameAsc, nameDesc, distance }

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance:
        return 'Pertinence';
      case SortOption.priceAsc:
        return 'Prix croissant';
      case SortOption.priceDesc:
        return 'Prix décroissant';
      case SortOption.nameAsc:
        return 'Nom A-Z';
      case SortOption.nameDesc:
        return 'Nom Z-A';
      case SortOption.distance:
        return 'Distance';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.relevance:
        return Icons.trending_up;
      case SortOption.priceAsc:
        return Icons.arrow_upward;
      case SortOption.priceDesc:
        return Icons.arrow_downward;
      case SortOption.nameAsc:
        return Icons.sort_by_alpha;
      case SortOption.nameDesc:
        return Icons.sort_by_alpha;
      case SortOption.distance:
        return Icons.location_on;
    }
  }
}
