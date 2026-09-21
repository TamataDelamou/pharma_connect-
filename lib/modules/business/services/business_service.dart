import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/business_company.dart';
import '../models/business_contract.dart';

class BusinessService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Companies ----

  Future<List<BusinessCompany>> getCompanies({
    String? type,
    String? status,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('business_companies')
          .select();

      if (type != null) {
        query = query.eq('type', type);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'legal_name.ilike.%$searchQuery%,'
          'city.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((e) => BusinessCompany.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load companies: $e');
    }
  }

  Future<BusinessCompany?> getCompany(String id) async {
    try {
      final response = await _client
          .from('business_companies')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return BusinessCompany.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load company: $e');
    }
  }

  Future<BusinessCompany> createCompany(BusinessCompany company) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = company
          .copyWith(
            id: id,
            status: company.status ?? 'pending',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('business_companies')
          .insert(data)
          .select()
          .single();
      return BusinessCompany.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  Future<BusinessCompany> updateCompany(BusinessCompany company) async {
    try {
      final data = company
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('business_companies')
          .update(data)
          .eq('id', company.id)
          .select()
          .single();
      return BusinessCompany.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _client.from('business_companies').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  // ---- Contracts ----

  Future<List<BusinessContract>> getContracts({
    String? companyId,
    String? status,
  }) async {
    try {
      var query = _client
          .from('business_contracts')
          .select();

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('start_date', ascending: false);
      return (response as List)
          .map((e) => BusinessContract.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load contracts: $e');
    }
  }

  Future<BusinessContract?> getContract(String id) async {
    try {
      final response = await _client
          .from('business_contracts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return BusinessContract.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load contract: $e');
    }
  }

  Future<BusinessContract> createContract(BusinessContract contract) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = contract
          .copyWith(
            id: id,
            status: contract.status ?? 'draft',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('business_contracts')
          .insert(data)
          .select()
          .single();
      return BusinessContract.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create contract: $e');
    }
  }

  Future<BusinessContract> updateContract(BusinessContract contract) async {
    try {
      final data = contract
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('business_contracts')
          .update(data)
          .eq('id', contract.id)
          .select()
          .single();
      return BusinessContract.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update contract: $e');
    }
  }

  Future<void> deleteContract(String id) async {
    try {
      await _client.from('business_contracts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete contract: $e');
    }
  }
}
