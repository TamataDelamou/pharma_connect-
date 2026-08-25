import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_method_selector.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String? reservationId;
  final String? deliveryId;
  final String? pharmacyName;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.reservationId,
    this.deliveryId,
    this.pharmacyName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.orangeMoney;
  bool _useCashback = true;
  bool _isProcessing = false;

  final List<PaymentMethod> _availableMethods = [
    PaymentMethod.orangeMoney,
    PaymentMethod.mtnMomo,
    PaymentMethod.moovMoney,
    PaymentMethod.gsgWallet,
    PaymentMethod.bankCard,
    PaymentMethod.cashOnDelivery,
    PaymentMethod.installment,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final int cashbackAmount = (widget.amount * 2) ~/ 100;
    final int finalAmount = _useCashback
        ? widget.amount - cashbackAmount
        : widget.amount;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                    'Paiement',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé de la commande',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (widget.pharmacyName != null) ...[
                            Text('Pharmacie : ${widget.pharmacyName}'),
                          ],
                          if (widget.reservationId != null) ...[
                            Text('Réservation : #${widget.reservationId}'),
                          ],
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: PharmaConnectTypography.body1,
                              ),
                              Text(
                                CurrencyFormatter.format(widget.amount),
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_useCashback && cashbackAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cashback (2%)',
                                  style: PharmaConnectTypography.body2.copyWith(
                                    color: PharmaConnectColors.accentGreen,
                                  ),
                                ),
                                Text(
                                  '- ${CurrencyFormatter.format(cashbackAmount)}',
                                  style: PharmaConnectTypography.body2.copyWith(
                                    color: PharmaConnectColors.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'À payer',
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(finalAmount),
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: PharmaConnectColors.accentCyan,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Choix du moyen de paiement
                    PaymentMethodSelector(
                      availableMethods: _availableMethods,
                      selectedMethod: _selectedMethod,
                      onMethodSelected: (method) {
                        setState(() => _selectedMethod = method);
                      },
                      showCashback: true,
                    ),
                    const SizedBox(height: 8),

                    // Option cashback
                    if (_selectedMethod.isMobileMoney ||
                        _selectedMethod == PaymentMethod.gsgWallet) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _useCashback,
                            onChanged: (value) {
                              setState(() => _useCashback = value ?? true);
                            },
                            activeColor: PharmaConnectColors.accentCyan,
                          ),
                          Expanded(
                            child: Text(
                              'Utiliser mon cashback (${CurrencyFormatter.format(cashbackAmount)})',
                              style: PharmaConnectTypography.body2,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton de paiement
                    PrimaryButton(
                      label: _selectedMethod == PaymentMethod.installment
                          ? 'Payer en plusieurs fois'
                          : 'Payer ${CurrencyFormatter.format(finalAmount)}',
                      isLoading: _isProcessing || provider.isLoading,
                      onPressed: () async {
                        setState(() => _isProcessing = true);

                        final transaction = await provider.initiatePayment(
                          userId: 'patient_123', // À récupérer de l'auth
                          userPhone: '+224612345678',
                          amount: finalAmount,
                          method: _selectedMethod,
                          reservationId: widget.reservationId,
                          deliveryId: widget.deliveryId,
                          pharmacyName: widget.pharmacyName,
                          useCashback: _useCashback,
                        );

                        setState(() => _isProcessing = false);

                        if (transaction != null && context.mounted) {
                          if (_selectedMethod == PaymentMethod.installment) {
                            context.go(
                              '/payments/installment/${transaction.id}',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Paiement effectué avec succès !',
                                ),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                            context.go('/reservations/confirmation');
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Sécurisé par GSG Kernel',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
