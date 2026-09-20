import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/pharmacy_group.dart';
import '../models/group_member.dart';
import '../models/stock_transfer.dart';

class ChainService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-7 : `transfer_create_screen.dart`
  // utilisait jusqu'ici des listes d'officines/produits codées en dur
  // (identifiants non-UUID `ph1`/`p1`...), ce qui aurait fait échouer tout
  // transfert réel à l'insertion (contrainte de clé étrangère
  // `stock_transfers.from_pharmacy_id`/`to_pharmacy_id references pharmacies(id)`).
  // Deux méthodes de lecture réelle ajoutées, même patron que
  // `CatalogService.getProducts()`.
  Future<List<Map<String, dynamic>>> getActivePharmacies() async {
    try {
      final response = await _client
          .from('pharmacies')
          .select('id, name')
          .eq('status', 'active')
          .eq('is_active', true)
          .order('name', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load pharmacies: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActiveProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('id, name')
          .order('name', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  // ---- Groups ----

  Future<List<PharmacyGroup>> getGroups({bool? isActive}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('pharmacy_groups')
          .select('*, members:group_members(id), owners:owner_id(full_name)');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => PharmacyGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  Future<PharmacyGroup?> getGroup(String id) async {
    try {
      final response = await _client
          .from('pharmacy_groups')
          .select('*, members:group_members(id), owners:owner_id(full_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PharmacyGroup.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load group: $e');
    }
  }

  Future<PharmacyGroup> createGroup(PharmacyGroup group) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = group
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
            ownerId: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'member_count' ||
            key == 'owner_name' ||
            key == 'members' ||
            key == 'owners',
      );

      final response = await _client
          .from('pharmacy_groups')
          .insert(data)
          .select()
          .single();
      return PharmacyGroup.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  Future<PharmacyGroup> updateGroup(PharmacyGroup group) async {
    try {
      final data = group
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'member_count' ||
            key == 'owner_name' ||
            key == 'members' ||
            key == 'owners',
      );

      final response = await _client
          .from('pharmacy_groups')
          .update(data)
          .eq('id', group.id)
          .select()
          .single();
      return PharmacyGroup.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _client.from('pharmacy_groups').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // ---- Group Members ----

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _client
          .from('group_members')
          .select('*, pharmacies:pharmacy_id(name, address, city)')
          .eq('group_id', groupId)
          .eq('is_active', true)
          .order('joined_at', ascending: true);
      return (response as List)
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load group members: $e');
    }
  }

  Future<GroupMember> addMember(GroupMember member) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = member
          .copyWith(
            id: id,
            joinedAt: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'pharmacy_name' ||
            key == 'pharmacy_address' ||
            key == 'pharmacy_city' ||
            key == 'pharmacies',
      );

      final response = await _client
          .from('group_members')
          .insert(data)
          .select()
          .single();
      return GroupMember.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  Future<GroupMember> updateMember(GroupMember member) async {
    try {
      final data = member
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'pharmacy_name' ||
            key == 'pharmacy_address' ||
            key == 'pharmacy_city' ||
            key == 'pharmacies',
      );

      final response = await _client
          .from('group_members')
          .update(data)
          .eq('id', member.id)
          .select()
          .single();
      return GroupMember.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update member: $e');
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      await _client
          .from('group_members')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // ---- Stock Transfers ----

  Future<List<StockTransfer>> getTransfers({
    String? groupId,
    String? fromPharmacyId,
    String? toPharmacyId,
    String? status,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client.from('stock_transfers').select(
            '*, from_pharmacies:from_pharmacy_id(name), to_pharmacies:to_pharmacy_id(name), items:transfer_items(*)',
          );

      if (groupId != null) {
        query = query.eq('group_id', groupId);
      }
      if (fromPharmacyId != null) {
        query = query.eq('from_pharmacy_id', fromPharmacyId);
      }
      if (toPharmacyId != null) {
        query = query.eq('to_pharmacy_id', toPharmacyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('transfer_date', ascending: false);
      return (response as List)
          .map((e) => StockTransfer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transfers: $e');
    }
  }

  Future<StockTransfer?> getTransfer(String id) async {
    try {
      final response = await _client
          .from('stock_transfers')
          .select(
            '*, from_pharmacies:from_pharmacy_id(name), to_pharmacies:to_pharmacy_id(name), items:transfer_items(*)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return StockTransfer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load transfer: $e');
    }
  }

  Future<StockTransfer> createTransfer(StockTransfer transfer) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = transfer
          .copyWith(
            id: id,
            status: 'pending',
            transferDate: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'from_pharmacy_name' ||
            key == 'to_pharmacy_name' ||
            key == 'items' ||
            key == 'from_pharmacies' ||
            key == 'to_pharmacies',
      );

      final response = await _client
          .from('stock_transfers')
          .insert(data)
          .select()
          .single();
      return StockTransfer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create transfer: $e');
    }
  }

  Future<StockTransfer> updateTransfer(StockTransfer transfer) async {
    try {
      final data = transfer
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'from_pharmacy_name' ||
            key == 'to_pharmacy_name' ||
            key == 'items' ||
            key == 'from_pharmacies' ||
            key == 'to_pharmacies',
      );

      final response = await _client
          .from('stock_transfers')
          .update(data)
          .eq('id', transfer.id)
          .select()
          .single();
      return StockTransfer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update transfer: $e');
    }
  }

  Future<StockTransfer> updateTransferStatus(
    String id,
    String newStatus, {
    DateTime? receivedDate,
  }) async {
    try {
      final data = {
        'status': newStatus,
        if (receivedDate != null)
          'received_date': receivedDate.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('stock_transfers')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return StockTransfer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update transfer status: $e');
    }
  }

  Future<void> deleteTransfer(String id) async {
    try {
      await _client.from('stock_transfers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete transfer: $e');
    }
  }

  // ---- Transfer Items ----

  Future<TransferItem> addTransferItem(TransferItem item) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = item
          .copyWith(id: id, createdAt: now, updatedAt: now)
          .toJson();
      final response = await _client
          .from('transfer_items')
          .insert(data)
          .select()
          .single();
      return TransferItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add transfer item: $e');
    }
  }

  Future<void> removeTransferItem(String id) async {
    try {
      await _client.from('transfer_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to remove transfer item: $e');
    }
  }
}
