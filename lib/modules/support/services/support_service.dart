import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket.dart';
import '../models/ticket_response.dart';
import '../models/support_category.dart';

class SupportService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Categories ----

  Future<List<SupportCategory>> getCategories() async {
    try {
      final response = await _client
          .from('support_categories')
          .select()
          .eq('is_active', true)
          .order('name');
      return (response as List)
          .map((e) => SupportCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // ---- Tickets ----

  Future<List<SupportTicket>> getTickets({
    String? patientId,
    String? assignedTo,
    String? status,
    String? priority,
    bool? isOpen,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif. Le `.in(` de la
      // dernière condition ci-dessous reste un défaut DISTINCT (mot réservé
      // Dart, même famille que PRE-1) — signalé, non corrigé ici, hors
      // mandat de cette phase transversale.
      var query = _client
          .from('support_tickets')
          .select(
            '*, patients:patient_id(full_name, phone), assignees:assigned_to(full_name), categories:category_id(name), responses:responses(id), feedbacks:feedback(id)',
          );

      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }
      if (assignedTo != null) {
        query = query.eq('assigned_to', assignedTo);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (isOpen != null && isOpen) {
        query = query.inFilter('status', [
          'new',
          'in_progress',
          'waiting_for_patient',
        ]);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }

  Future<SupportTicket?> getTicket(String id) async {
    try {
      final response = await _client
          .from('support_tickets')
          .select(
            '*, patients:patient_id(full_name, phone), assignees:assigned_to(full_name), categories:category_id(name), responses:responses(id), feedbacks:feedback(id)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return SupportTicket.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load ticket: $e');
    }
  }

  Future<SupportTicket> createTicket(SupportTicket ticket) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = ticket
          .copyWith(
            id: newId,
            status: 'new',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'assignee_name' ||
            key == 'category_name' ||
            key == 'response_count' ||
            key == 'has_feedback' ||
            key == 'patients' ||
            key == 'assignees' ||
            key == 'categories' ||
            key == 'responses' ||
            key == 'feedbacks',
      );

      final response = await _client
          .from('support_tickets')
          .insert(data)
          .select()
          .single();
      return SupportTicket.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<SupportTicket> updateTicket(SupportTicket ticket) async {
    try {
      final data = ticket
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'assignee_name' ||
            key == 'category_name' ||
            key == 'response_count' ||
            key == 'has_feedback' ||
            key == 'patients' ||
            key == 'assignees' ||
            key == 'categories' ||
            key == 'responses' ||
            key == 'feedbacks',
      );

      final response = await _client
          .from('support_tickets')
          .update(data)
          .eq('id', ticket.id)
          .select()
          .single();
      return SupportTicket.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  Future<SupportTicket> updateTicketStatus(
    String id,
    String newStatus, {
    String? resolutionNote,
  }) async {
    try {
      final data = {
        'status': newStatus,
        if (newStatus == 'resolved')
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'closed')
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        if (resolutionNote != null) 'resolution_note': resolutionNote,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('support_tickets')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return SupportTicket.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      await _client.from('support_tickets').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  // ---- Responses ----

  Future<List<TicketResponse>> getResponsesForTicket(String ticketId) async {
    try {
      final response = await _client
          .from('support_responses')
          .select('*, authors:author_id(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load responses: $e');
    }
  }

  Future<TicketResponse> addResponse(TicketResponse response) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = response
          .copyWith(id: newId, createdAt: now, updatedAt: now)
          .toJson();
      data.removeWhere(
        (key, value) => key == 'author_name' || key == 'authors',
      );

      final result = await _client
          .from('support_responses')
          .insert(data)
          .select()
          .single();
      return TicketResponse.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add response: $e');
    }
  }

  Future<void> deleteResponse(String id) async {
    try {
      await _client.from('support_responses').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete response: $e');
    }
  }

  // ---- Feedback ----

  Future<void> submitFeedback({
    required String ticketId,
    required String patientId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.from('support_feedback').insert({
        'ticket_id': ticketId,
        'patient_id': patientId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
