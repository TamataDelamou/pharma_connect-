import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../services/review_service.dart';
import '../models/professional_review.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class ProfessionalReviewsScreen extends StatefulWidget {
  final String professionalId;

  const ProfessionalReviewsScreen({super.key, required this.professionalId});

  @override
  State<ProfessionalReviewsScreen> createState() =>
      _ProfessionalReviewsScreenState();
}

class _ProfessionalReviewsScreenState extends State<ProfessionalReviewsScreen> {
  final ReviewService _service = ReviewService();
  List<ProfessionalReview> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getProfessionalReviews(widget.professionalId),
        _service.getStats(widget.professionalId),
      ]);
      _reviews = results[0] as List<ProfessionalReview>;
      _stats = results[1] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⭐ Avis des patients',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Donner mon avis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats summary
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '⭐ ${((_stats['avg_rating'] as num?) ?? 0).toDouble().toStringAsFixed(1)}/5',
                    'Note moyenne',
                    context.palette.warningStrong,
                  ),
                  _buildStatItem(
                    '${_stats['total_reviews'] ?? 0}',
                    'Avis',
                    context.palette.primary,
                  ),
                  // C220 / D65 : patients et consultations visibles du seul
                  // professionnel concerné et de GSG (null pour les autres).
                  if (_stats['total_patients'] != null)
                    _buildStatItem(
                      '${_stats['total_patients']}',
                      'Patients',
                      context.palette.success,
                    ),
                  if (_stats['total_consultations'] != null)
                    _buildStatItem(
                      '${_stats['total_consultations']}',
                      'Consultations',
                      context.palette.secondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reviews list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: _loadData,
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : _reviews.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun avis pour le moment',
                        style: context.text.body2,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        // Phase 3 (module professionals) : GlassCard
                        // (widget partagé, lib/core/widgets/cards/) n'expose
                        // pas de paramètre `margin` - défaut de compilation.
                        // Enveloppé dans un Padding plutôt que d'étendre le
                        // widget partagé pour un seul appelant.
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review.patientName ?? 'Patient anonyme',
                                      style: context.text.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      review.ratingDisplay,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (review.reviewText != null)
                                  Text(
                                    review.reviewText!,
                                    style: context.text.body2,
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: context.text.micro,
                                    ),
                                    if (review.isVerified) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.palette.success
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Vérifié',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: context.palette.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // Helpful buttons
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_up_outlined,
                                            size: 16,
                                          ),
                                          onPressed: () async {
                                            await _service.voteHelpful(
                                              review.id,
                                              true,
                                            );
                                            _loadData();
                                          },
                                        ),
                                        Text(
                                          '${review.helpfulCount}',
                                          style: context.text.micro,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_down_outlined,
                                            size: 16,
                                          ),
                                          onPressed: () async {
                                            await _service.voteHelpful(
                                              review.id,
                                              false,
                                            );
                                            _loadData();
                                          },
                                        ),
                                        Text(
                                          '${review.notHelpfulCount}',
                                          style: context.text.micro,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: context.text.micro),
      ],
    );
  }

  void _showReviewDialog() {
    final palette = context.palette;
    int rating = 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.background,
        title: const Text('Donner mon avis'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: context.palette.warningStrong,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Partagez votre expérience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: rating > 0
                ? () async {
                    Navigator.pop(ctx);
                    final review = ProfessionalReview(
                      id: '',
                      professionalId: widget.professionalId,
                      patientId: SupabaseService().currentUser!.id,
                      rating: rating,
                      reviewText: controller.text.trim(),
                      isVerified: false,
                      isAnonymous: false,
                      helpfulCount: 0,
                      notHelpfulCount: 0,
                      status: 'pending',
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                    );
                    await _service.createReview(review);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Avis soumis avec succès !'),
                        backgroundColor: palette.success,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
