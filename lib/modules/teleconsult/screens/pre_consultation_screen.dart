import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/pre_consultation_provider.dart';

/// ⚠️ AUDIT MODULE 15 (CNS, 29/08/2026) — NE PAS ROUTER SANS ARBITRAGE.
///
/// Cet écran, son provider (`PreConsultationProvider`) et son service
/// (`PreConsultationAIService`) reposent sur une IA entièrement factice
/// (`analyzeSymptoms()` — voir le commentaire « Mock AI » dans
/// `pre_consultation_ai_service.dart`) : elle génère via `Random()` des
/// « possible_conditions », un niveau d'urgence et une spécialité suggérée,
/// affichés au patient avec un bandeau « URGENCE - Consultez immédiatement ».
/// Ce comportement contreviendrait à RG-CNS-01 (l'assistant ne formule
/// JAMAIS de diagnostic) et RG-CNS-02 (tout contenu généré doit s'appuyer
/// exclusivement sur du contenu validé par un pharmacien référent,
/// versionné) si ce sous-système était exposé tel quel comme faisant partie
/// du Module CNS — voir le rapport d'audit Module 15, §3, et le registre
/// (D26). Décision du porteur du projet (AskUserQuestion, 29/08/2026) :
/// corriger uniquement ce qui empêchait la compilation (accès à un champ
/// privé depuis un autre fichier, syntaxe de collection invalide — voir
/// `pre_consultation_provider.dart`), sans reconsidérer le contenu ni le
/// statut d'exposition. Cet écran reste donc volontairement NON routé dans
/// `app_router.dart` (aucune entrée de navigation) — ne pas l'y ajouter
/// sans nouvel arbitrage explicite.
class PreConsultationScreen extends StatefulWidget {
  const PreConsultationScreen({super.key});

  @override
  State<PreConsultationScreen> createState() => _PreConsultationScreenState();
}

class _PreConsultationScreenState extends State<PreConsultationScreen> {
  final _symptomController = TextEditingController();
  String? _selectedSymptom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<PreConsultationProvider>().startSession(userId);
      }
    });
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreConsultationProvider>();
    final session = provider.currentSession;

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
                      '🤖 Assistant pré-consultation',
                      style: PharmaConnectTypography.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
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
                          Text(
                            provider.error!,
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: () {
                              provider.clearError();
                              final userId = SupabaseService().currentUser?.id;
                              if (userId != null) {
                                provider.startSession(userId);
                              }
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : session == null
                  ? const SizedBox.shrink()
                  : session.status == 'completed' &&
                        provider.analysisResult != null
                  ? _buildResults(provider)
                  : _buildQuestionFlow(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionFlow(PreConsultationProvider provider) {
    // Audit Module 15 (CNS, 29/08/2026) : `currentNode` vient désormais du
    // provider (getter public dérivé, voir pre_consultation_provider.dart)
    // — l'ancien code accédait au champ privé `provider._currentNodeId`
    // depuis cet autre fichier (erreur de compilation, portée de
    // bibliothèque en Dart) via un `firstWhere(orElse: ...)` dont le
    // callback pouvait retourner `null`, incompatible avec la signature non
    // nullable attendue.
    final currentNode = provider.currentNode;

    if (currentNode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Audit Module 15 (CNS, 29/08/2026) : extrait hors du spread de liste —
    // une déclaration de variable locale (`final options = ...;`) n'est pas
    // un élément de collection valide à l'intérieur d'un `...[ ... ]`,
    // c'était une erreur de syntaxe empêchant la compilation de tout le
    // fichier (et donc de l'application entière).
    final options = currentNode.isLeaf
        ? const <dynamic>[]
        : (currentNode.options['options'] as List?) ?? const <dynamic>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💬 ${currentNode.question}',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 16),
                if (currentNode.isLeaf) ...[
                  Text(
                    'Résultat : ${currentNode.leafResult ?? 'Consultation recommandée'}',
                    style: PharmaConnectTypography.body1,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Terminer',
                    onPressed: () async {
                      await provider.selectOption(
                        currentNode.id,
                        _selectedSymptom ?? 'Non spécifié',
                      );
                    },
                  ),
                ] else ...[
                  // Display options
                  ...options.map((opt) {
                    final label = opt['label'] as String? ?? '';
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSymptom = label);
                        provider.selectOption(currentNode.id, label);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: _selectedSymptom == label
                              ? PharmaConnectColors.accentCyan.withValues(
                                  alpha: 0.1,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedSymptom == label
                                ? PharmaConnectColors.accentCyan
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(label, style: PharmaConnectTypography.body1),
                            const Spacer(),
                            if (_selectedSymptom == label)
                              const Icon(
                                Icons.check_circle,
                                color: PharmaConnectColors.accentCyan,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Suivant',
                    onPressed: _selectedSymptom != null
                        ? () => provider.selectOption(
                            currentNode.id,
                            _selectedSymptom!,
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progression : ${provider.decisionTree.indexOf(currentNode) + 1}/${provider.decisionTree.length}',
            style: PharmaConnectTypography.micro,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(PreConsultationProvider provider) {
    final analysis = provider.analysisResult!;
    final session = provider.currentSession!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.isCritical)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: PharmaConnectColors.accentRed,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '⚠️ URGENCE - Consultez immédiatement',
                      style: TextStyle(
                        color: PharmaConnectColors.accentRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Analyse préliminaire',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Spécialité suggérée',
                  analysis['specialty_suggestion'] ?? 'Non déterminée',
                ),
                const Divider(color: Colors.white12),
                _buildInfoRow(
                  'Niveau d\'urgence',
                  _urgencyLabel(analysis['urgency_level'] ?? 3),
                ),
                const Divider(color: Colors.white12),
                _buildInfoRow(
                  'Severité',
                  analysis['symptoms_analysis']['severity'] ?? 'Non évaluée',
                ),
                if (analysis['symptoms_analysis']['possible_conditions'] !=
                    null) ...[
                  const Divider(color: Colors.white12),
                  _buildInfoRow(
                    'Conditions possibles',
                    (analysis['symptoms_analysis']['possible_conditions']
                            as List)
                        .join(', '),
                  ),
                ],
                if (analysis['suggested_actions'] != null) ...[
                  const Divider(color: Colors.white12),
                  _buildInfoRow(
                    'Actions recommandées',
                    (analysis['suggested_actions'] as List).join(' • '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📄 Résumé pour le médecin',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  session.summary ?? 'Résumé généré automatiquement.',
                  style: PharmaConnectTypography.body2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Prendre rendez-vous',
                  icon: Icons.calendar_today,
                  onPressed: () {
                    // Navigate to booking with the suggested specialty
                    context.push(
                      '/teleconsult/book',
                      extra: {
                        'specialty': analysis['specialty_suggestion'],
                        'symptoms': session.symptoms,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.clearSession();
                    context.pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Fermer'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  String _urgencyLabel(int level) {
    switch (level) {
      case 1:
        return '⚠️ Critique - Immédiat';
      case 2:
        return '🔴 Urgent';
      case 3:
        return '🟠 Modéré';
      case 4:
        return '🟡 Léger';
      case 5:
        return '🟢 Non urgent';
      default:
        return 'Non déterminé';
    }
  }
}
