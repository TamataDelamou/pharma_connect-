import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/demand_forecast.dart';
import '../models/stock_item.dart';

class ForecastService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Generate Demand Forecast ----

  Future<List<DemandForecast>> generateDemandForecast({
    required String productId,
    required String pharmacyId,
    int days = 14,
  }) async {
    // Get historical sales
    final sales = await _getHistoricalSales(productId, pharmacyId);

    // Calculate average daily demand
    final avgDaily = sales.isEmpty
        ? 10
        : sales.reduce((a, b) => a + b) / sales.length;

    // Generate forecasts
    final forecasts = <DemandForecast>[];
    final now = DateTime.now();

    // Get product name
    final product = await _client
        .from('products')
        .select('name')
        .eq('id', productId)
        .single();
    final productName =
        (product as Map<String, dynamic>)['name'] as String? ?? 'Produit';

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i + 1));
      final dayOfWeek = date.weekday;

      // Adjust for day of week (higher demand on weekends)
      var factor = 1.0;
      if (dayOfWeek == 6 || dayOfWeek == 7) {
        factor = 1.3 + _random.nextDouble() * 0.3;
      } else {
        factor = 0.8 + _random.nextDouble() * 0.4;
      }

      // Add some randomness
      final noise = 0.85 + _random.nextDouble() * 0.3;
      final predicted = (avgDaily * factor * noise).round();

      final id = _uuid.v4();
      final forecast = DemandForecast(
        id: id,
        productId: productId,
        pharmacyId: pharmacyId,
        productName: productName,
        forecastDate: date,
        predictedDemand: predicted,
        lowerBound: (predicted * 0.8).round(),
        upperBound: (predicted * 1.2).round(),
        confidenceLevel: 0.85,
        modelVersion: 'v2.0',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await _saveForecast(forecast);
      forecasts.add(forecast);
    }

    return forecasts;
  }

  // Audit Module 11 (29/08/2026) : `stock_movements` (voir
  // 20260827000600_stock.sql) n'a ni colonne `product_id`, ni `pharmacy_id`,
  // ni `movement_type`, ni `created_at` — seulement `stock_item_id`, `type`
  // et `timestamp`. L'ancienne requête filtrait sur des colonnes inexistantes
  // et échouait systématiquement (exception absorbée silencieusement par le
  // catch ci-dessous), forçant `generateDemandForecast` à toujours retomber
  // sur la moyenne par défaut codée en dur (10/jour) au lieu de la vraie
  // vélocité de vente — la prévision n'exploitait donc jamais de données
  // réelles, quel que soit l'historique. Corrigé en résolvant d'abord le
  // `stock_item_id` (pharmacy_id × product_id, unique — voir
  // stock_items.unique(pharmacy_id, product_id)) puis en filtrant les
  // mouvements de type 'sale' dessus.
  Future<List<double>> _getHistoricalSales(
    String productId,
    String pharmacyId,
  ) async {
    try {
      final stockItemRow = await _client
          .from('stock_items')
          .select('id')
          .eq('product_id', productId)
          .eq('pharmacy_id', pharmacyId)
          .maybeSingle();
      if (stockItemRow == null) return [];
      final stockItemId = (stockItemRow as Map<String, dynamic>)['id'] as String;

      final response = await _client
          .from('stock_movements')
          .select('quantity, timestamp')
          .eq('stock_item_id', stockItemId)
          .eq('type', 'sale')
          .order('timestamp', ascending: false)
          .limit(30);

      // quantity est négatif pour une sortie (vente) — voir
      // stock_movement.dart : "quantity positif = entrée, négatif = sortie".
      return (response as List)
          .map(
            (e) =>
                ((e as Map<String, dynamic>)['quantity'] as num)
                    .abs()
                    .toDouble(),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<DemandForecast> _saveForecast(DemandForecast forecast) async {
    try {
      final response = await _client
          .from('demand_forecasts')
          .insert(forecast.toJson())
          .select()
          .single();
      return DemandForecast.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return forecast;
    }
  }

  // Audit Module 11 (29/08/2026) : manquait — le provider appelait `_client`
  // directement sans jamais l'importer/le déclarer (erreur de compilation,
  // voir forecast_provider.dart). Réintroduit ici, côté service, pour rester
  // cohérent avec le reste de l'app (le provider ne doit jamais parler
  // directement à Supabase).
  Future<List<DemandForecast>> getForecasts(String pharmacyId) async {
    final response = await _client
        .from('demand_forecasts')
        .select()
        .eq('pharmacy_id', pharmacyId)
        .order('forecast_date', ascending: true);
    return (response as List)
        .map((e) => DemandForecast.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Reorder Alerts ----

  // Audit Module 11 (29/08/2026) : `.select()` (sans argument) sur
  // `stock_items` ne renvoie pas la relation `product` imbriquée que
  // `StockItem.fromJson` exige (`json['product']` serait absent) — cet appel
  // aurait levé une exception dès le premier item. Alignée sur la requête
  // jointe déjà utilisée par `StockService` (`_stockItemSelect`).
  static const _stockItemSelect =
      '*, product:products(*, category:categories(name), manufacturer:manufacturers(name)), batches:stock_batches(*)';

  Future<List<ReorderAlert>> checkReorderAlerts(String pharmacyId) async {
    try {
      final items = await _client
          .from('stock_items')
          .select(_stockItemSelect)
          .eq('pharmacy_id', pharmacyId);

      final alerts = <ReorderAlert>[];

      for (final item in items as List) {
        final stockItem = StockItem.fromJson(item as Map<String, dynamic>);
        final reorderPoint = _calculateReorderPoint(stockItem);

        if (stockItem.totalQuantity <= reorderPoint) {
          // Audit Module 11 (29/08/2026) : aucune protection anti-doublon —
          // chaque appel (à chaque ouverture de l'écran) réinsérait une
          // nouvelle ligne `reorder_alerts` pour le même produit, exactement
          // le même défaut déjà corrigé pour `alerts` au Module 10 (voir
          // C35/D6, 8ème occurrence). Corrigé en vérifiant d'abord qu'aucune
          // alerte 'pending' n'existe déjà pour ce produit/officine.
          final existing = await _client
              .from('reorder_alerts')
              .select('id')
              .eq('pharmacy_id', pharmacyId)
              .eq('product_id', stockItem.product.id)
              .eq('status', 'pending')
              .maybeSingle();
          if (existing != null) continue;

          final alert = ReorderAlert(
            id: _uuid.v4(),
            pharmacyId: pharmacyId,
            productId: stockItem.product.id,
            productName: stockItem.product.name,
            currentStock: stockItem.totalQuantity,
            reorderPoint: reorderPoint,
            quantityToOrder: (reorderPoint * 2 - stockItem.totalQuantity)
                .round(),
            status: 'pending',
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

          await _saveReorderAlert(alert);
          alerts.add(alert);
        }
      }

      return alerts;
    } catch (e) {
      throw Exception('Failed to check reorder alerts: $e');
    }
  }

  // Audit Module 11 (29/08/2026) : liste les alertes déjà générées, sans
  // recalculer/réinsérer — utilisé par l'écran « Commande recommandée »
  // (arbitrage D17) pour afficher l'état courant sans effet de bord.
  Future<List<ReorderAlert>> getPendingReorderAlerts(String pharmacyId) async {
    final response = await _client
        .from('reorder_alerts')
        .select()
        .eq('pharmacy_id', pharmacyId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => ReorderAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Audit Module 11 (29/08/2026), arbitrage D17 : validation par le
  // pharmacien d'une proposition de commande — passe l'alerte à 'ordered'
  // avec la quantité éventuellement corrigée. RG-IA-01 : ceci ne transmet
  // RIEN à un fournisseur (aucune intégration fournisseur n'existe dans le
  // projet, voir rapport d'audit Module 11 §D18) — c'est une validation
  // interne, pas une commande automatique.
  Future<bool> validateReorder({
    required String alertId,
    required int quantityToOrder,
  }) async {
    try {
      await _client
          .from('reorder_alerts')
          .update({
            'quantity_to_order': quantityToOrder,
            'status': 'ordered',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', alertId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> dismissReorder(String alertId) async {
    try {
      await _client
          .from('reorder_alerts')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', alertId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Audit Module 11 (29/08/2026) : ignorait `StockItem.thresholdLow`/
  // `thresholdCritical` (déjà en base depuis le Module 4, désormais
  // paramétrables par le pharmacien depuis le Module 10 — voir D15) au
  // profit d'une formule arbitraire déconnectée (`totalQuantity * 0.2 + 5`).
  // Alignée sur le seuil réel du produit pour rester cohérente avec le reste
  // de l'app plutôt que d'introduire une deuxième notion de seuil.
  int _calculateReorderPoint(StockItem item) {
    return item.thresholdLow;
  }

  Future<void> _saveReorderAlert(ReorderAlert alert) async {
    await _client.from('reorder_alerts').insert(alert.toJson());
  }

  // ---- Scenario Simulation ----

  Future<Map<String, dynamic>> simulateScenario({
    required String pharmacyId,
    required String name,
    required Map<String, dynamic> parameters,
  }) async {
    // Simulate different scenarios
    // - High demand scenario (20% increase)
    // - Low demand scenario (20% decrease)
    // - Supply disruption scenario (50% reduction)

    await Future.delayed(const Duration(seconds: 1));

    final baseDemand = 100.0;
    final scenarios = {
      'normal': {'demand': baseDemand, 'stock_level': 85, 'risk': 'low'},
      'high_demand': {
        'demand': baseDemand * 1.2,
        'stock_level': 65,
        'risk': 'medium',
      },
      'low_demand': {
        'demand': baseDemand * 0.8,
        'stock_level': 95,
        'risk': 'low',
      },
      'supply_disruption': {
        'demand': baseDemand * 1.1,
        'stock_level': 40,
        'risk': 'high',
      },
    };

    // Phase 4 (module stock/IA) : `scenarios[name] ?? scenarios['normal']`
    // reste statiquement nullable (Map<String, Object>?, l'opérateur [] ne
    // sait pas que 'normal' existe forcément dans ce literal) alors que la
    // méthode retourne Future<Map<String, dynamic>> non-nullable - défaut
    // de compilation, jamais détecté faute de compilateur exécuté à la
    // clôture du Module 11/IA. 'normal' est garanti présent dans le
    // literal ci-dessus, `!` est donc sûr.
    final selected = scenarios[name] ?? scenarios['normal']!;

    // Save simulation
    await _client.from('scenario_simulations').insert({
      'pharmacy_id': pharmacyId,
      'name': name,
      'parameters': parameters,
      'results': selected,
      'status': 'completed',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'created_by': SupabaseService().currentUser?.id,
    });

    return selected;
  }
}
