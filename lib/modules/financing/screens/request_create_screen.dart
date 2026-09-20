import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/tertiary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/financing_provider.dart';
import '../models/financing_request.dart';

class RequestCreateScreen extends StatefulWidget {
  final String? b2bOrderId;

  const RequestCreateScreen({super.key, this.b2bOrderId});

  @override
  State<RequestCreateScreen> createState() => _RequestCreateScreenState();
}

class _RequestCreateScreenState extends State<RequestCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _periodController = TextEditingController(text: '3');
  final _notesController = TextEditingController();

  bool _isLoading = false;

  // Chargement du score de crédit dès l'ouverture (audit Module 14,
  // 29/08/2026, amélioration UX) : jusqu'ici `provider.creditScore` n'était
  // affiché ici que par coïncidence, si un autre écran (le tableau de bord)
  // l'avait déjà chargé avant la navigation — jamais si l'officine arrivait
  // directement sur cet écran. Le champ n'apparaissait donc pas de façon
  // fiable alors qu'il permet à l'officine d'évaluer ses chances avant de
  // soumettre une demande.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      if (pharmacyId != null) {
        context.read<FinancingProvider>().loadCreditScore(pharmacyId);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _periodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancingProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                      '💰 Demander un financement',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassInput(
                              label: 'Montant (GNF)',
                              hint: 'Ex: 1 000 000',
                              controller: _amountController,
                              prefixIcon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer un montant';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Montant invalide';
                                }
                                if (int.parse(value) <= 0) {
                                  return 'Le montant doit être supérieur à 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Motif (optionnel)',
                              hint: 'Ex: Réapprovisionnement stock',
                              controller: _purposeController,
                              prefixIcon: Icons.description,
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Durée (mois)',
                              hint: '3',
                              controller: _periodController,
                              prefixIcon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Durée requise';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Durée invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            GlassInput(
                              label: 'Notes (optionnel)',
                              hint: 'Informations complémentaires',
                              controller: _notesController,
                              prefixIcon: Icons.note_add,
                              keyboardType: TextInputType.multiline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Credit score info
                      if (provider.creditScore != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _scoreColor(
                              provider.creditScore!.score,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _scoreColor(
                                provider.creditScore!.score,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: _scoreColor(provider.creditScore!.score),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Votre score de crédit : ${provider.creditScore!.score} (${provider.creditScore!.ratingLabel})',
                                  style: TextStyle(
                                    color: _scoreColor(
                                      provider.creditScore!.score,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: _isLoading ? 'Envoi...' : 'Soumettre la demande',
                        isLoading: _isLoading,
                        onPressed: _submitRequest,
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Annuler',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 800) return PharmaConnectColors.accentGreen;
    if (score >= 700) return PharmaConnectColors.accentCyan;
    if (score >= 600) return PharmaConnectColors.accentAmber;
    if (score >= 500) return PharmaConnectColors.accentOrange;
    return PharmaConnectColors.accentRed;
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Bug corrigé (audit Module 14, 29/08/2026) : utilisait
    // `SupabaseService().currentUser?.id` (identifiant UTILISATEUR) comme
    // `pharmacyId` (identifiant OFFICINE) — même confusion que C43. La
    // RLS (`financing_requests_insert_own_pharmacy`) exige désormais
    // `is_pharmacy_staff(pharmacy_id)`, qui aurait rejeté silencieusement
    // toute soumission utilisant l'identifiant utilisateur.
    final pharmacyId = context.read<AuthProvider>().pharmacyId;
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte non rattaché à une officine vérifiée — impossible de '
            'soumettre une demande de financement',
          ),
        ),
      );
      return;
    }

    final amount = int.parse(_amountController.text.trim());
    final period = int.parse(_periodController.text.trim());

    setState(() => _isLoading = true);

    final request = FinancingRequest(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharmacyId,
      b2bOrderId: widget.b2bOrderId,
      amount: amount,
      purpose: _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : null,
      repaymentPeriodMonths: period,
      interestRate: 5.0,
      status: 'pending',
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final success = await context.read<FinancingProvider>().saveRequest(
      request,
    );
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande soumise avec succès'),
          backgroundColor: PharmaConnectColors.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<FinancingProvider>().error ?? 'Erreur'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
