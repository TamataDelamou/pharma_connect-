import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/b2b_offer.dart';
import '../models/b2b_order.dart';
import '../models/b2b_negotiation.dart';

class MarketplaceService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Offers ----

  Future<List<B2BOffer>> getOffers({
    String? sellerPharmacyId,
    String? productId,
    String? status,
    bool onlyActive = true,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('b2b_offers')
          .select('*, sellers:seller_pharmacy_id(name)');

      if (sellerPharmacyId != null) {
        query = query.eq('seller_pharmacy_id', sellerPharmacyId);
      }
      if (productId != null) {
        query = query.eq('product_id', productId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (onlyActive) {
        query = query.eq('status', 'active');
        query = query.gt(
          'expiry_date',
          DateTime.now().toIso8601String().split('T').first,
        );
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => B2BOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load offers: $e');
    }
  }

  Future<B2BOffer?> getOffer(String id) async {
    try {
      final response = await _client
          .from('b2b_offers')
          .select('*, sellers:seller_pharmacy_id(name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return B2BOffer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load offer: $e');
    }
  }

  Future<B2BOffer> createOffer(B2BOffer offer) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = offer
          .copyWith(
            id: id,
            status: 'active',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'seller_name' || key == 'is_negotiable' || key == 'sellers',
      );

      final response = await _client
          .from('b2b_offers')
          .insert(data)
          .select()
          .single();
      return B2BOffer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }

  Future<B2BOffer> updateOffer(B2BOffer offer) async {
    try {
      final data = offer
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'seller_name' || key == 'is_negotiable' || key == 'sellers',
      );

      final response = await _client
          .from('b2b_offers')
          .update(data)
          .eq('id', offer.id)
          .select()
          .single();
      return B2BOffer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update offer: $e');
    }
  }

  Future<void> deleteOffer(String id) async {
    try {
      await _client.from('b2b_offers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete offer: $e');
    }
  }

  // Audit Module 13 (B2B, 29/08/2026, clôture) : nouvelle méthode — utilisée
  // par l'écran « Mes offres » pour avertir le vendeur avant suppression si
  // l'offre est déjà référencée par des lignes de commande existantes.
  // `b2b_order_items.offer_id` est `on delete set null` (migration de base) :
  // supprimer l'offre ne supprime jamais ces lignes, mais les détache
  // silencieusement de l'offre d'origine si l'utilisateur n'est pas prévenu.
  Future<int> countOrderItemsForOffer(String offerId) async {
    try {
      final response = await _client
          .from('b2b_order_items')
          .select('id')
          .eq('offer_id', offerId);
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to count linked order items: $e');
    }
  }

  // ---- Orders ----

  // Audit Module 13 (B2B, 29/08/2026) : `involvedPharmacyId` ajouté —
  // l'unique appelant (marketplace_home_screen.dart, onglet « Mes
  // commandes ») voulait « commandes où je suis acheteur OU vendeur », mais
  // passait `buyerPharmacyId` ET `sellerPharmacyId` avec la même valeur.
  // Deux `.eq()` successifs sur un query builder PostgREST se combinent en
  // ET, pas en OU : le filtre exigeait donc qu'une même officine soit à la
  // fois acheteuse et vendeuse de la commande, ce qui n'arrive jamais dans
  // ce module — l'onglet était vide pour tout le monde. `buyerPharmacyId`/
  // `sellerPharmacyId` restent disponibles séparément pour un futur usage
  // ne voulant qu'un seul rôle.
  Future<List<B2BOrder>> getOrders({
    String? buyerPharmacyId,
    String? sellerPharmacyId,
    String? involvedPharmacyId,
    String? status,
  }) async {
    try {
      var query = _client
          .from('b2b_orders')
          .select(
            // Audit Module 13 (B2B, 29/08/2026, clôture) : `items:order_items(*)`
            // référençait une table `order_items` qui n'existe pas — la table
            // réelle est `b2b_order_items` (voir migration de base). PostgREST
            // rejette toute requête d'embed vers une relation inexistante avec
            // une erreur 400, ce qui faisait échouer `getOrders()`/`getOrder()`
            // dans leur intégralité (pas seulement le champ `items` vide) —
            // bug distinct du bug AND/OR déjà corrigé sur ce même onglet
            // « Mes commandes », et plus sévère : la requête n'aboutissait
            // jamais, quels que soient les filtres.
            '*, buyers:buyer_pharmacy_id(name), sellers:seller_pharmacy_id(name), items:b2b_order_items(*)',
          );
      // Phase 2bis (motif transversal "filtre après .order()") : .order()
      // était appelé ci-dessus avant ces filtres conditionnels — déplacé
      // après (voir eprescription_service.dart pour la genèse du motif).

      if (involvedPharmacyId != null) {
        query = query.or(
          'buyer_pharmacy_id.eq.$involvedPharmacyId,'
          'seller_pharmacy_id.eq.$involvedPharmacyId',
        );
      } else {
        if (buyerPharmacyId != null) {
          query = query.eq('buyer_pharmacy_id', buyerPharmacyId);
        }
        if (sellerPharmacyId != null) {
          query = query.eq('seller_pharmacy_id', sellerPharmacyId);
        }
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => B2BOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<B2BOrder?> getOrder(String id) async {
    try {
      final response = await _client
          .from('b2b_orders')
          .select(
            '*, buyers:buyer_pharmacy_id(name), sellers:seller_pharmacy_id(name), items:b2b_order_items(*)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return B2BOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  Future<B2BOrder> createOrder(B2BOrder order) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = order
          .copyWith(
            id: id,
            status: 'draft',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'buyer_name' ||
            key == 'seller_name' ||
            key == 'items' ||
            key == 'buyers' ||
            key == 'sellers',
      );

      final response = await _client
          .from('b2b_orders')
          .insert(data)
          .select()
          .single();
      return B2BOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<B2BOrder> updateOrder(B2BOrder order) async {
    try {
      final data = order
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'buyer_name' ||
            key == 'seller_name' ||
            key == 'items' ||
            key == 'buyers' ||
            key == 'sellers',
      );

      final response = await _client
          .from('b2b_orders')
          .update(data)
          .eq('id', order.id)
          .select()
          .single();
      return B2BOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  Future<B2BOrder> updateOrderStatus(String id, String newStatus) async {
    try {
      final data = {
        'status': newStatus,
        if (newStatus == 'submitted')
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'confirmed')
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'delivered')
          'delivered_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('b2b_orders')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return B2BOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // ---- Order Items ----

  Future<B2BOrderItem> addOrderItem(B2BOrderItem item) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = item.copyWith(id: id, createdAt: now).toJson();
      final response = await _client
          .from('b2b_order_items')
          .insert(data)
          .select()
          .single();
      return B2BOrderItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add order item: $e');
    }
  }

  // ---- Negotiations ----

  Future<List<B2BNegotiation>> getNegotiationsForOffer(String offerId) async {
    try {
      final response = await _client
          .from('b2b_negotiations')
          .select()
          .eq('offer_id', offerId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => B2BNegotiation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load negotiations: $e');
    }
  }

  Future<B2BNegotiation> createNegotiation(B2BNegotiation negotiation) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = negotiation
          .copyWith(
            id: id,
            status: 'pending',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('b2b_negotiations')
          .insert(data)
          .select()
          .single();
      return B2BNegotiation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create negotiation: $e');
    }
  }

  Future<B2BNegotiation> updateNegotiation(B2BNegotiation negotiation) async {
    try {
      final data = negotiation
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('b2b_negotiations')
          .update(data)
          .eq('id', negotiation.id)
          .select()
          .single();
      return B2BNegotiation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update negotiation: $e');
    }
  }
}
