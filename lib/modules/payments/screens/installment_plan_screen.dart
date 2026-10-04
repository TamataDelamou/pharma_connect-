import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/installment.dart';
import '../providers/payment_provider.dart';
import '../../../core/theme/palette.dart';

class InstallmentPlanScreen extends StatefulWidget {
  final String transactionId;

  const InstallmentPlanScreen({super.key, required this.transactionId});

  @override
  State<InstallmentPlanScreen> createState() => _InstallmentPlanScreenState();
}

class _InstallmentPlanScreenState extends State<InstallmentPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadInstallment(widget.transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final installment = provider.currentInstallment;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (installment == null) {
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
                        "Plan d'échelonnement",
                        style: context.text.heading2,
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
                child: Center(
                  child: Text(
                    'Aucun échéancier trouvé',
                    style: context.text.body2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      "Plan d'échelonnement",
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 8),
            Text('Résumé du plan de paiement', style: context.text.body2),
            const SizedBox(height: 24),

            // Résumé
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total à payer', style: context.text.label),
                            Text(
                              CurrencyFormatter.format(installment.totalAmount),
                              style: context.text.kpiSmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Restant', style: context.text.label),
                            Text(
                              CurrencyFormatter.format(
                                installment.remainingAmount,
                              ),
                              style: context.text.kpiSmall.copyWith(
                                color: context.palette.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Échéances', style: context.text.label),
                            Text(
                              '${installment.paidCount}/${installment.numberOfPayments}',
                              style: context.text.kpiSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: installment.paidCount / installment.numberOfPayments,
                    color: context.palette.primary,
                    backgroundColor: context.palette.border,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des échéances
            Text('Échéances', style: context.text.heading3),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: installment.payments.length,
                itemBuilder: (context, index) {
                  final payment = installment.payments[index];
                  final isPaid =
                      payment.status == InstallmentPaymentStatus.paid;
                  final isLate =
                      payment.status == InstallmentPaymentStatus.late;
                  final isPending =
                      payment.status == InstallmentPaymentStatus.pending;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? context.palette.success.withValues(alpha: 0.08)
                          : isLate
                          ? context.palette.danger.withValues(alpha: 0.08)
                          : context.palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid
                            ? context.palette.success.withValues(alpha: 0.2)
                            : isLate
                            ? context.palette.danger.withValues(alpha: 0.2)
                            : context.palette.surface,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isPaid
                                ? context.palette.success
                                : isLate
                                ? context.palette.danger
                                : context.palette.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Échéance #${payment.number}',
                                style: context.text.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDate(payment.dueDate),
                                style: context.text.body2,
                              ),
                              if (isLate) ...[
                                Text(
                                  '⚠️ En retard',
                                  style: TextStyle(
                                    color: context.palette.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(payment.amount),
                              style: context.text.body1.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? context.palette.success.withValues(
                                        alpha: 0.15,
                                      )
                                    : isLate
                                    ? context.palette.danger.withValues(
                                        alpha: 0.15,
                                      )
                                    : context.palette.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isPaid
                                      ? context.palette.success
                                      : isLate
                                      ? context.palette.danger
                                      : context.palette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          PrimaryButton(
                            label: 'Payer',
                            onPressed: () async {
                              final success = await provider.payInstallment(
                                widget.transactionId,
                                payment.number,
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Échéance payée !'),
                                    backgroundColor: context.palette.success,
                                  ),
                                );
                              }
                            },
                            width: 80,
                          ),
                        ],
                      ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
