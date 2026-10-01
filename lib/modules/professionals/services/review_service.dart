import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/professional_review.dart';

class ReviewService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Reviews ----

  Future<List<ProfessionalReview>> getProfessionalReviews(
    String professionalId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('professional_reviews')
          .select('*, patients:patient_id(full_name)')
          .eq('professional_id', professionalId)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((e) => ProfessionalReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<ProfessionalReview> createReview(ProfessionalReview review) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = review
          .copyWith(
            id: id,
            status: 'pending',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'professional_name' ||
            key == 'user_voted_helpful',
      );

      final response = await _client
          .from('professional_reviews')
          .insert(data)
          .select()
          .single();
      return ProfessionalReview.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  Future<void> voteHelpful(String reviewId, bool isHelpful) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _client.from('review_helpful_votes').upsert({
        'review_id': reviewId,
        'patient_id': userId,
        'is_helpful': isHelpful,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (isHelpful) {
        await _client.rpc(
          'increment_review_helpful',
          params: {'review_id': reviewId},
        );
      } else {
        await _client.rpc(
          'increment_review_not_helpful',
          params: {'review_id': reviewId},
        );
      }
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// C220 / D65 : note moyenne et nombre d'avis publics (professionnels
  /// vérifiés) ; nombres de consultations et de patients renseignés
  /// seulement pour le professionnel lui-même et GSG (null sinon).
  Future<Map<String, dynamic>> getStats(String professionalId) async {
    try {
      final response = await _client
          .from('professional_stats_public')
          .select()
          .eq('professional_id', professionalId)
          .maybeSingle();
      if (response == null) {
        return {'total_reviews': 0, 'avg_rating': 0.0};
      }
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'total_reviews': 0, 'avg_rating': 0.0};
    }
  }

  // ---- Moderation (Staff) ----

  Future<List<ProfessionalReview>> getPendingReviews() async {
    try {
      final response = await _client
          .from('professional_reviews')
          .select(
            '*, patients:patient_id(full_name), professionals:professional_id(full_name)',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => ProfessionalReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pending reviews: $e');
    }
  }

  Future<void> moderateReview(String id, String status, {String? notes}) async {
    try {
      await _client
          .from('professional_reviews')
          .update({
            'status': status,
            'moderation_notes': notes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'updated_by': SupabaseService().currentUser?.id,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to moderate review: $e');
    }
  }

  Future<void> deleteReview(String id) async {
    try {
      await _client.from('professional_reviews').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}
