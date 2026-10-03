import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/triage_ai_provider.dart';

class TriageAIScreen extends StatefulWidget {
  final String triagePatientId;

  const TriageAIScreen({super.key, required this.triagePatientId});

  @override
  State<TriageAIScreen> createState() => _TriageAIScreenState();
}

class _TriageAIScreenState extends State<TriageAIScreen> {
  final _symptomController = TextEditingController();
  bool _isAnalyzed = false;
  // Audit Module 17 (TRI, 30/08/2026), correctif fonctionnel : remontés
  // depuis des variables locales de `_buildFeedbackSection` (réinitialisées
  // à `null` à CHAQUE reconstruction du widget, sans jamais déclencher de
  // `setState`) — le formulaire de feedback ne pouvait donc jamais être
  // rempli : sélectionner un élément dans un menu déroulant ne mettait à
  // jour qu'une variable locale vouée à disparaître, le bouton « Envoyer le
  // feedback » restait inconditionnellement désactivé (`selectedPriority`/
  // `selectedDepartment` toujours `null` au moment où sa condition
  // `onPressed` était évaluée).
  int? _feedbackPriority;
  String? _feedbackDepartment;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageAIProvider>();

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
                      '🧠 Triage intelligent',
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Step 1: Symptoms input
                    if (!_isAnalyzed) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1️⃣ Décrivez les symptômes',
                              style: PharmaConnectTypography.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Décrivez les symptômes du patient de manière détaillée',
                              style: PharmaConnectTypography.body2,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _symptomController,
                              decoration: const InputDecoration(
                                hintText: 'Ex: Douleur thoracique intense...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'L\'IA analyse les symptômes pour déterminer la priorité et orienter le patient',
                                    style: PharmaConnectTypography.micro
                                        .copyWith(
                                          color:
                                              PharmaConnectColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: provider.isAnalyzing
                                  ? 'Analyse en cours...'
                                  : 'Analyser',
                              isLoading: provider.isAnalyzing,
                              onPressed: () async {
                                final text = _symptomController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Veuillez décrire les symptômes',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await provider.analyzeSymptoms(
                                    triagePatientId: widget.triagePatientId,
                                    symptoms: text,
                                  );
                                  setState(() => _isAnalyzed = true);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Step 2: Results
                    if (_isAnalyzed && provider.currentAnalysis != null) ...[
                      const SizedBox(height: 16),
                      _buildResults(provider),
                    ],

                    // Step 3: Feedback (for doctors)
                    if (_isAnalyzed && provider.currentAnalysis != null) ...[
                      const SizedBox(height: 16),
                      _buildFeedbackSection(provider),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(TriageAIProvider provider) {
    final analysis = provider.currentAnalysis!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          glow: analysis.isCritical,
          glowColor: analysis.isCritical
              ? PharmaConnectColors.accentRed
              : _priorityColor(analysis.priorityScore),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _priorityColor(
                    analysis.priorityScore,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _priorityColor(
                      analysis.priorityScore,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      analysis.priorityLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _priorityColor(analysis.priorityScore),
                      ),
                    ),
                    const Spacer(),
                    if (analysis.isCritical)
                      const Icon(
                        Icons.warning_amber,
                        color: PharmaConnectColors.accentRed,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details
              _buildInfoRow(
                'Service suggéré',
                analysis.suggestedDepartment ?? 'Non déterminé',
              ),
              const Divider(color: Colors.white12),
              _buildInfoRow('Symptômes analysés', analysis.symptoms),

              if (analysis.analysisDetails['matched_keywords'] != null) ...[
                const Divider(color: Colors.white12),
                _buildInfoRow(
                  'Mots-clés détectés',
                  (analysis.analysisDetails['matched_keywords'] as List).join(
                    ', ',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: analysis.isCritical
                    ? '🚑 Appeler les urgences'
                    : 'Valider l\'orientation',
                icon: analysis.isCritical ? Icons.emergency : Icons.check,
                onPressed: () {
                  // Navigate to patient detail with suggested department
                  context.pop(analysis);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isAnalyzed = false);
                  provider.clearAnalysis();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réanalyser'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(TriageAIProvider provider) {
    final analysis = provider.currentAnalysis!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3️⃣ Feedback (pour les médecins)',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Aidez à améliorer l\'IA en fournissant votre évaluation réelle',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 12),

          // Priority feedback
          DropdownButtonFormField<int>(
            value: _feedbackPriority,
            decoration: const InputDecoration(labelText: 'Priorité réelle'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 - Critique')),
              DropdownMenuItem(value: 2, child: Text('2 - Urgent')),
              DropdownMenuItem(value: 3, child: Text('3 - Modéré')),
              DropdownMenuItem(value: 4, child: Text('4 - Léger')),
              DropdownMenuItem(value: 5, child: Text('5 - Non urgent')),
            ],
            onChanged: (value) => setState(() => _feedbackPriority = value),
          ),
          const SizedBox(height: 8),

          // Department feedback
          DropdownButtonFormField<String>(
            value: _feedbackDepartment,
            decoration: const InputDecoration(labelText: 'Service réel'),
            items: const [
              DropdownMenuItem(
                value: 'Cardiologie',
                child: Text('Cardiologie'),
              ),
              DropdownMenuItem(
                value: 'Traumatologie',
                child: Text('Traumatologie'),
              ),
              DropdownMenuItem(value: 'Urgences', child: Text('Urgences')),
              DropdownMenuItem(value: 'Chirurgie', child: Text('Chirurgie')),
              DropdownMenuItem(
                value: 'Généraliste',
                child: Text('Généraliste'),
              ),
              DropdownMenuItem(
                value: 'Pneumologie',
                child: Text('Pneumologie'),
              ),
              DropdownMenuItem(
                value: 'Dermatologie',
                child: Text('Dermatologie'),
              ),
            ],
            onChanged: (value) => setState(() => _feedbackDepartment = value),
          ),
          const SizedBox(height: 12),

          PrimaryButton(
            label: 'Envoyer le feedback',
            onPressed: _feedbackPriority != null && _feedbackDepartment != null
                ? () async {
                    await provider.submitFeedback(
                      analysisId: analysis.id,
                      actualPriority: _feedbackPriority!,
                      actualDepartment: _feedbackDepartment!,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback enregistré, merci !'),
                          backgroundColor: PharmaConnectColors.accentGreen,
                        ),
                      );
                    }
                  }
                : null,
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
            width: 120,
            child: Text(label, style: PharmaConnectTypography.label),
          ),
          Expanded(child: Text(value, style: PharmaConnectTypography.body1)),
        ],
      ),
    );
  }

  Color _priorityColor(int score) {
    switch (score) {
      case 1:
        return PharmaConnectColors.accentRed;
      case 2:
        return PharmaConnectColors.accentOrange;
      case 3:
        return PharmaConnectColors.accentAmber;
      case 4:
        return PharmaConnectColors.accentCyan;
      case 5:
        return PharmaConnectColors.accentGreen;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
