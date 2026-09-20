import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/async_message.dart';

class MessagingService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  Future<List<AsyncMessage>> getMessages({
    required String patientId,
    required String professionalId,
    String? consultationId,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('async_messages')
          .select('*, senders:sender_id(full_name)')
          .eq('patient_id', patientId)
          .eq('professional_id', professionalId);

      if (consultationId != null) {
        query = query.eq('consultation_id', consultationId);
      }

      final response = await query.order('created_at', ascending: true);
      return (response as List)
          .map((e) => AsyncMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<AsyncMessage> sendMessage({
    required String patientId,
    required String professionalId,
    required String message,
    String? consultationId,
    List<String>? attachments,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final userId = SupabaseService().currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = {
        'id': id,
        'consultation_id': consultationId,
        'patient_id': patientId,
        'professional_id': professionalId,
        'sender_id': userId,
        'message': message,
        'attachments': attachments ?? [],
        'is_read': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': userId,
        'updated_by': userId,
      };

      final response = await _client
          .from('async_messages')
          .insert(data)
          .select()
          .single();

      return AsyncMessage.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _client
          .from('async_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Future<int> getUnreadCount({
    required String patientId,
    required String professionalId,
  }) async {
    try {
      final response = await _client
          .from('async_messages')
          .select('id', count: CountOption.exact)
          .eq('patient_id', patientId)
          .eq('professional_id', professionalId)
          .eq('is_read', false)
          .neq('sender_id', SupabaseService().currentUser?.id);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteMessage(String id) async {
    try {
      await _client.from('async_messages').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
