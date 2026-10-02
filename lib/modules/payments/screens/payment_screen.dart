import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_method_selector.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String? reservationId;
  final String? deliveryId;
  final String? pharmacyId;
  final String? pharmacyName;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.reservationId,
    this.deliveryId,
    this.pharmacyId,
    this.pharmacyName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.orangeMoney;
  bool _useCashback = true;
  bool _isProcessing = false;
  // Amélioration/correctif (audit Module 8, 29/08/2026) : "Paiement en
  // plusieurs fois" ne proposait aucun choix du nombre d'échéances —
  // PaymentService.createInstallment acceptait pourtant numberOfPayments
  // depuis le départ, sans jamais être appelée (voir le rapport d'audit).
  int _numberOfPayments = 3;
  final OfflineSyncService _offlineSync = OfflineSyncService();

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
    // RG-PAY-02 (Cahier de conception, Standard) : "Les frais de service
    // PharmaConnect sont calculés et affichés de manière transparente avant
    // validation du paiement par le patient." Bug corrigé (audit Module 8,
    // 29/08/2026) : les frais (1%, hors gsgWallet — voir
    // PaymentService._feePercent) n'étaient jusqu'ici jamais affichés nulle
    // part sur cet écran, malgré leur application réelle côté service.
    final int feeAmount = _selectedMethod == PaymentMethod.gsgWallet
        ? 0
        : (widget.amount * 1) ~/ 100;
    final int finalAmount = _useCashback
        ? widget.amount + feeAmount - cashbackAmount
        : widget.amount + feeAmount;

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
                          if (feeAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Frais de service (1%)',
                                  style: PharmaConnectTypography.body2,
                                ),
                                Text(
                                  '+ ${CurrencyFormatter.format(feeAmount)}',
                                  style: PharmaConnectTypography.body2,
                                ),
                              ],
                            ),
                          ],
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

                    // Nombre d'échéances (audit Module 8, 29/08/2026) :
                    // sélecteur ajouté pour piloter numberOfPayments,
                    // jusqu'ici jamais exposé côté UI.
                    if (_selectedMethod == PaymentMethod.installment) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Nombre d\'échéances',
                        style: PharmaConnectTypography.label,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [3, 6, 12].map((n) {
                          final isSelected = _numberOfPayments == n;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$n fois'),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _numberOfPayments = n),
                              selectedColor: PharmaConnectColors.accentCyan
                                  .withValues(alpha: 0.2),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: isSelected
                                    ? PharmaConnectColors.accentCyan
                                    : Colors.white24,
                              ),
                            ),
                          );
                        }).toList(),
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
                        // Décision D13 (audit Module 8, 29/08/2026,
                        // arbitrée par le porteur du projet) : le mode
                        // hors-ligne de PAY reste volontairement limité à
                        // la lecture (solde, historique) — un paiement
                        // rejoué après coupure réseau risquerait un double
                        // débit ou une double confirmation. Plutôt que de
                        // laisser l'appel réseau simplement échouer avec un
                        // message générique, on bloque explicitement ici,
                        // avant tout appel.
                        final hasInternet = await _offlineSync.hasInternet();
                        if (!hasInternet) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Paiement indisponible hors connexion. '
                                  'Reconnectez-vous pour régler cette commande.',
                                ),
                                backgroundColor: PharmaConnectColors.accentRed,
                              ),
                            );
                          }
                          return;
                        }

                        // Bug corrigé (audit Module 8, 29/08/2026) : userId
                        // et userPhone en dur ('patient_123',
                        // '+224612345678') — 5e/6e occurrence du même
                        // défaut que Modules 4/5/6/7. Toute transaction
                        // créée depuis cet écran s'écrivait sous une
                        // identité fictive.
                        final auth = context.read<AuthProvider>();
                        final userId = auth.userId;
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vous devez être connecté pour payer.',
                              ),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
                          return;
                        }

                        setState(() => _isProcessing = true);

                        final transaction = await provider.initiatePayment(
                          userId: userId,
                          userPhone: auth.userPhone ?? '',
                          amount: widget.amount,
                          method: _selectedMethod,
                          reservationId: widget.reservationId,
                          deliveryId: widget.deliveryId,
                          pharmacyId: widget.pharmacyId,
                          pharmacyName: widget.pharmacyName,
                          useCashback: _useCashback,
                          numberOfPayments: _numberOfPayments,
                        );

                        setState(() => _isProcessing = false);

                        if (transaction != null && context.mounted) {
                          if (_selectedMethod == PaymentMethod.installment) {
                            context.go(
                              '/payments/installment/${transaction.id}',
                            );
                          } else {
                            // C225 / D67 : le paiement n'est « payé » qu'une
                            // fois l'encaissement confirmé par l'officine.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Paiement enregistré : l\'officine le '
                                  'confirmera dès réception.',
                                ),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                            context.go('/reservations/confirmation');
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.error ??
                                    'Erreur lors du paiement',
                              ),
                              backgroundColor: PharmaConnectColors.accentRed,
                            ),
                          );
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
