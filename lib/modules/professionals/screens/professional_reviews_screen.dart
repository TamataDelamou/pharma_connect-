import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../services/review_service.dart';
import '../models/professional_review.dart';

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
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⭐ Avis des patients',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Donner mon avis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
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
                    '⭐ ${(_stats['avg_rating'] as double? ?? 0.0).toStringAsFixed(1)}/5',
                    'Note moyenne',
                    PharmaConnectColors.accentAmber,
                  ),
                  _buildStatItem(
                    '${_stats['total_reviews'] ?? 0}',
                    'Avis',
                    PharmaConnectColors.accentCyan,
                  ),
                  _buildStatItem(
                    '${_stats['total_patients'] ?? 0}',
                    'Patients',
                    PharmaConnectColors.accentGreen,
                  ),
                  _buildStatItem(
                    '${_stats['total_consultations'] ?? 0}',
                    'Consultations',
                    PharmaConnectColors.accentPurple,
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PharmaConnectColors.accentRed,
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
                  ? const Center(
                      child: Text(
                        'Aucun avis pour le moment',
                        style: PharmaConnectTypography.body2,
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
                                      style: PharmaConnectTypography.body1
                                          .copyWith(
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
                                    style: PharmaConnectTypography.body2,
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: PharmaConnectTypography.micro,
                                    ),
                                    if (review.isVerified) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PharmaConnectColors.accentGreen
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Vérifié',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                PharmaConnectColors.accentGreen,
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
                                          style: PharmaConnectTypography.micro,
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
                                          style: PharmaConnectTypography.micro,
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
        Text(label, style: PharmaConnectTypography.micro),
      ],
    );
  }

  void _showReviewDialog() {
    int rating = 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
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
                      color: PharmaConnectColors.accentAmber,
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
                      const SnackBar(
                        content: Text('Avis soumis avec succès !'),
                        backgroundColor: PharmaConnectColors.accentGreen,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
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
