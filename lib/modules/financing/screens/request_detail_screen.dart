import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments/models/payment_method.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/financing_provider.dart';
import '../models/financing_request.dart';
import '../models/financing_repayment.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancingProvider>().loadRequest(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancingProvider>();
    final request = provider.selectedRequest;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (request == null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.error ?? 'Demande introuvable',
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    // `isOwner` (audit Module 14, 29/08/2026) : comparait `pharmacy_id`
    // (identifiant OFFICINE) à `SupabaseService().currentUser?.id`
    // (identifiant UTILISATEUR) — les deux ne coïncident jamais, même
    // confusion que C43 déjà rencontrée dans d'autres modules. La bonne
    // source est `AuthProvider.pharmacyId`, renseigné après vérification de
    // licence (RG-AUT-01).
    final isOwner =
        auth.pharmacyId != null && request.pharmacyId == auth.pharmacyId;
    // `isStaff` (audit Module 14, 29/08/2026) : était figé à `false`, ce qui
    // rendait tout le circuit Approuver/Rejeter/Décaisser définitivement
    // inatteignable depuis l'UI, quel que soit l'utilisateur connecté.
    // Reflète désormais `AuthProvider.isGsgAdmin`, lui-même une lecture
    // best-effort de `public.admin_users` — la même source que la RLS
    // `is_gsg_admin()` qui protège réellement ces actions côté serveur.
    final isStaff = auth.isGsgAdmin;

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
                      'Détail de la demande',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    request.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Montant',
                            CurrencyFormatter.format(request.amount),
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Durée',
                            '${request.repaymentPeriodMonths} mois',
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          _buildInfoRow(
                            'Taux d\'intérêt',
                            '${request.interestRate.toStringAsFixed(1)}%',
                          ),
                          Divider(color: context.palette.veil(0.12)),
                          if (request.purpose != null)
                            _buildInfoRow('Motif', request.purpose!),
                          if (request.notes != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow('Notes', request.notes!),
                          ],
                          if (request.approvedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Approuvé le',
                              _formatDate(request.approvedAt!),
                            ),
                          ],
                          if (request.disbursedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Décaissé le',
                              _formatDate(request.disbursedAt!),
                            ),
                          ],
                          if (request.completedAt != null) ...[
                            Divider(color: context.palette.veil(0.12)),
                            _buildInfoRow(
                              'Terminé le',
                              _formatDate(request.completedAt!),
                            ),
                          ],
                          _buildInfoRow(
                            'Total à rembourser',
                            CurrencyFormatter.format(
                              request.totalRepaymentAmount.round(),
                            ),
                          ),
                          _buildInfoRow(
                            'Mensualité',
                            CurrencyFormatter.format(
                              request.monthlyPayment.round(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Repayments schedule
                    if (provider.repayments.isNotEmpty) ...[
                      Text(
                        '📅 Échéancier de remboursement',
                        style: context.text.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.repayments.map((repayment) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: _repaymentStatusColor(
                              repayment.status,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _repaymentStatusColor(
                                repayment.status,
                              ).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _repaymentStatusColor(
                                    repayment.status,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Échéance ${_formatDate(repayment.dueDate)}',
                                      style: context.text.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(repayment.amount)} - ${repayment.statusLabel}',
                                      style: TextStyle(
                                        color: _repaymentStatusColor(
                                          repayment.status,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // C239 : règlement par le portefeuille GSG,
                              // masqué pour le pilote (`PilotConfig`).
                              if (PaymentMethod.gsgWallet.isEnabled &&
                                  repayment.status == 'pending' &&
                                  request.status == 'active' &&
                                  isOwner) ...[
                                PrimaryButton(
                                  label: 'Payer',
                                  onPressed: () => _payRepayment(
                                    context,
                                    request,
                                    repayment,
                                  ),
                                  height: 30,
                                  width: 80,
                                  fontSize: 12,
                                ),
                              ],
                              if (repayment.status == 'paid')
                                Icon(
                                  Icons.check_circle,
                                  color: context.palette.success,
                                ),
                              if (repayment.isOverdue)
                                Icon(
                                  Icons.warning_amber,
                                  color: context.palette.danger,
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions (staff only)
                    if (isStaff && request.status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Approuver',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                final success = await provider
                                    .updateRequestStatus(
                                      request.id,
                                      'approved',
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Demande approuvée'),
                                      backgroundColor: context.palette.success,
                                    ),
                                  );
                                  provider.loadRequest(widget.requestId);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Rejeter',
                              icon: Icons.close,
                              onPressed: () async {
                                final success = await provider
                                    .updateRequestStatus(
                                      request.id,
                                      'rejected',
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Demande rejetée'),
                                    ),
                                  );
                                  provider.loadRequest(widget.requestId);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isStaff && request.status == 'approved') ...[
                      PrimaryButton(
                        label: 'Décaisser',
                        icon: Icons.attach_money,
                        onPressed: () async {
                          final success = await provider.updateRequestStatus(
                            request.id,
                            'active',
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fonds décaissés'),
                                backgroundColor: context.palette.success,
                              ),
                            );
                            provider.loadRequest(widget.requestId);
                          }
                        },
                      ),
                    ],

                    if (request.status == 'completed') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.success.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: context.palette.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demande terminée le ${_formatDate(request.completedAt ?? DateTime.now())}',
                                style: TextStyle(
                                  color: context.palette.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (request.status == 'rejected') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.palette.danger.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.block, color: context.palette.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demande rejetée',
                                style: TextStyle(color: context.palette.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (request.status == 'active' ||
                        request.status == 'completed') ...[
                      const SizedBox(height: 16),
                      // Progress bar
                      Text(
                        'Progression du remboursement',
                        style: context.text.label,
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: context.palette.veil(0.24),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: provider.repayments.isNotEmpty
                                ? (provider.repayments
                                          .where((r) => r.status == 'paid')
                                          .length /
                                      provider.repayments.length)
                                : 0,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: context.palette.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${provider.repayments.where((r) => r.status == 'paid').length}/${provider.repayments.length} payés',
                            style: context.text.micro,
                          ),
                          Text(
                            '${((provider.repayments.where((r) => r.status == 'paid').length / (provider.repayments.length > 0 ? provider.repayments.length : 1)) * 100).toStringAsFixed(0)}%',
                            style: context.text.micro.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.palette.success,
                            ),
                          ),
                        ],
                      ),
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

  /// Rewiring du bouton "Payer" (audit Module 14, 29/08/2026) : appelait
  /// jusqu'ici directement `FinancingProvider.payRepayment`, qui se
  /// contentait de marquer l'échéance `paid` sans qu'aucun argent ne
  /// circule réellement — aucun débit du portefeuille GSG, aucune
  /// `Transaction` créée, `financing_repayments.transaction_id` toujours
  /// nul. Débite désormais réellement le portefeuille via
  /// `PaymentProvider.initiatePayment` (même mécanisme déjà utilisé pour
  /// les paiements de commande, `reservation_checkout_screen.dart`) avant
  /// de marquer l'échéance payée, et lie la transaction créée à l'échéance.
  /// Simulation client de la confirmation (posture déjà assumée pour les
  /// paiements de commande, voir précédent D12-D13) : accepté pour ce MVP,
  /// pas une régression propre à ce module.
  Future<void> _payRepayment(
    BuildContext context,
    FinancingRequest request,
    FinancingRepayment repayment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Débiter ${CurrencyFormatter.format(repayment.amount)} de votre '
          'portefeuille GSG pour régler cette échéance ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId == null) return;

    final paymentProvider = context.read<PaymentProvider>();
    final transaction = await paymentProvider.initiatePayment(
      userId: userId,
      userPhone: auth.userPhone ?? '',
      amount: repayment.amount,
      method: PaymentMethod.gsgWallet,
      pharmacyId: request.pharmacyId,
      pharmacyName: request.pharmacyName,
    );

    if (transaction == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement échoué : ${paymentProvider.error ?? "erreur inconnue"}',
            ),
            backgroundColor: context.palette.danger,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final financingProvider = context.read<FinancingProvider>();
    final success = await financingProvider.payRepayment(
      repayment.id,
      transactionId: transaction.id,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement effectué'),
          backgroundColor: context.palette.success,
        ),
      );
      financingProvider.loadRequest(widget.requestId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // Le portefeuille a déjà été débité à ce stade (transaction
            // créée avec succès) : l'échéance sera à régulariser
            // manuellement, l'utilisateur ne doit pas relancer un second
            // débit en pensant que rien ne s'est passé.
            'Le paiement a été débité mais l\'échéance n\'a pas pu être mise à jour : '
            '${financingProvider.error ?? "erreur inconnue"}. Contactez le support.',
          ),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.label)),
          Expanded(child: Text(value, style: context.text.body1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return context.palette.warning;
      case 'approved':
        return context.palette.primary;
      case 'rejected':
        return context.palette.danger;
      case 'active':
        return context.palette.secondary;
      case 'completed':
        return context.palette.success;
      case 'defaulted':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }

  Color _repaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return context.palette.warning;
      case 'paid':
        return context.palette.success;
      case 'overdue':
        return context.palette.danger;
      case 'defaulted':
        return context.palette.danger;
      default:
        return context.palette.textSecondary;
    }
  }
}
