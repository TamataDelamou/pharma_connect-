import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/product.dart';
import 'pharmacy.dart';

class AvailabilityResult {
  final Product product;
  final List<PharmacyStock> pharmacyStocks;
  final bool hasAvailableStock;
  final int availableCount;

  AvailabilityResult({required this.product, required this.pharmacyStocks})
    : hasAvailableStock = pharmacyStocks.any((p) => p.stock > 0),
      availableCount = pharmacyStocks.where((p) => p.stock > 0).length;

  List<PharmacyStock> get availableStocks =>
      pharmacyStocks.where((p) => p.stock > 0).toList();

  List<PharmacyStock> get unavailableStocks =>
      pharmacyStocks.where((p) => p.stock <= 0).toList();

  PharmacyStock? get bestPrice => pharmacyStocks
      .where((p) => p.stock > 0)
      .fold<PharmacyStock?>(
        null,
        (best, current) =>
            best == null || current.price < best.price ? current : best,
      );

  PharmacyStock? get nearest => pharmacyStocks
      .where((p) => p.stock > 0 && p.pharmacy.distance != null)
      .fold<PharmacyStock?>(
        null,
        (best, current) =>
            best == null ||
                (current.pharmacy.distance ?? double.infinity) <
                    (best.pharmacy.distance ?? double.infinity)
            ? current
            : best,
      );
}

class PharmacyStock {
  final Pharmacy pharmacy;
  final int stock;
  final int price; // unité mineure
  final bool isAvailable;
  final DateTime lastUpdated;

  PharmacyStock({
    required this.pharmacy,
    required this.stock,
    required this.price,
    required this.isAvailable,
    required this.lastUpdated,
  });

  bool get isOutdated => DateTime.now().difference(lastUpdated).inHours >= 24;

  /// RG-REC-01 (audit Module 2, 29/08/2026) : « au-delà [de 24h sans
  /// synchronisation], le statut passe automatiquement à "à confirmer" ».
  /// `isOutdated` était déjà calculé mais jamais consulté nulle part dans le
  /// module — corrigé ici, au niveau du modèle, pour que toute vue qui
  /// consomme stockLabel/stockColor (PharmacyListTile, SearchResultCard...)
  /// hérite automatiquement du correctif plutôt que de le dupliquer.
  String get stockLabel {
    if (isOutdated) return 'À confirmer';
    if (stock <= 0) return 'Rupture';
    if (stock < 5) return 'Stock très faible';
    if (stock < 20) return 'Stock faible';
    return 'Disponible';
  }

  Color get stockColor {
    if (isOutdated) return PharmaConnectColors.accentAmber;
    if (stock <= 0) return PharmaConnectColors.accentRed;
    if (stock < 5) return PharmaConnectColors.accentAmber;
    if (stock < 20) return PharmaConnectColors.accentOrange;
    return PharmaConnectColors.accentGreen;
  }
}
