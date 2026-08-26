import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/reservation_provider.dart';
import '../widgets/checkout_step_indicator.dart';

enum CheckoutStep { summary, details, payment, confirmation }

class ReservationCheckoutScreen extends StatefulWidget {
  const ReservationCheckoutScreen({super.key});

  @override
  State<ReservationCheckoutScreen> createState() =>
      _ReservationCheckoutScreenState();
}

class _ReservationCheckoutScreenState extends State<ReservationCheckoutScreen> {
  CheckoutStep _currentStep = CheckoutStep.summary;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentMethod = 'Orange Money';
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Orange Money',
    'MTN MoMo',
    'Moov Money',
    'Portefeuille GSG',
    'Paiement à la livraison',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

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
                  onPressed: () {
                    if (_currentStep != CheckoutStep.summary) {
                      setState(() {
                        _currentStep =
                            CheckoutStep.values[_currentStep.index - 1];
                      });
                    } else {
                      context.pop();
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Validation de la commande',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Indicateur d'étape
            CheckoutStepIndicator(
              currentStep: _currentStep.index,
              steps: const [
                'Récapitulatif',
                'Livraison',
                'Paiement',
                'Confirmation',
              ],
            ),
            const SizedBox(height: 24),

            // Contenu selon l'étape
            Expanded(child: _buildStepContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ReservationProvider provider) {
    switch (_currentStep) {
      case CheckoutStep.summary:
        return _buildSummaryStep(provider);
      case CheckoutStep.details:
        return _buildDetailsStep(provider);
      case CheckoutStep.payment:
        return _buildPaymentStep(provider);
      case CheckoutStep.confirmation:
        return _buildConfirmationStep(provider);
    }
  }

  // ==================== ÉTAPE 1 : RÉCAPITULATIF ====================

  Widget _buildSummaryStep(ReservationProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif de la commande',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 12),
                ...provider.cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: PharmaConnectTypography.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: PharmaConnectTypography.body1,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: PharmaConnectTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: PharmaConnectTypography.heading3,
                    ),
                    Text(
                      CurrencyFormatter.format(provider.cartTotal),
                      style: PharmaConnectTypography.kpiSmall.copyWith(
                        color: PharmaConnectColors.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pharmacie : ${provider.selectedPharmacyName ?? 'Non sélectionnée'}',
                  style: PharmaConnectTypography.body2,
                ),
                if (provider.selectedPharmacyAddress != null) ...[
                  Text(
                    provider.selectedPharmacyAddress!,
                    style: PharmaConnectTypography.micro,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour au panier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Continuer',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    setState(() {
                      _currentStep = CheckoutStep.details;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ÉTAPE 2 : DÉTAILS ====================

  Widget _buildDetailsStep(ReservationProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations de livraison',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adresse de livraison (optionnel)',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                GlassInput(
                  label: '',
                  hint: 'Votre adresse de livraison',
                  controller: _addressController,
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Instructions particulières (optionnel)',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                GlassInput(
                  label: '',
                  hint: 'Digicode, étage, etc.',
                  controller: _notesController,
                  prefixIcon: Icons.note,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = CheckoutStep.summary;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Continuer',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    setState(() {
                      _currentStep = CheckoutStep.payment;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ÉTAPE 3 : PAIEMENT ====================

  Widget _buildPaymentStep(ReservationProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode de paiement',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Montant total :',
                  style: PharmaConnectTypography.label,
                ),
                Text(
                  CurrencyFormatter.format(provider.cartTotal),
                  style: PharmaConnectTypography.kpiSmall.copyWith(
                    color: PharmaConnectColors.accentCyan,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre moyen de paiement',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 8),
                ..._paymentMethods.map((method) => _buildPaymentOption(method)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = CheckoutStep.details;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: _isSubmitting
                      ? 'Validation...'
                      : 'Confirmer la commande',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          final reservation = await provider.createReservation(
                            patientId: 'patient_123', // TODO: from auth
                            patientName: 'Jean Dupont', // TODO: from auth
                            patientPhone: '+224612345678', // TODO: from auth
                            pharmacyId: provider.selectedPharmacyId ?? 'ph_1',
                            pharmacyName:
                                provider.selectedPharmacyName ?? 'Pharmacie',
                            pharmacyAddress:
                                provider.selectedPharmacyAddress ?? 'Adresse',
                            pharmacyPhone: provider.selectedPharmacyPhone,
                            preferredPickupTime: provider.selectedSlot?.start,
                            deliveryAddress: _addressController.text.trim(),
                            paymentMethod: _selectedPaymentMethod,
                            notes: _notesController.text.trim(),
                          );
                          setState(() => _isSubmitting = false);
                          if (reservation != null && context.mounted) {
                            setState(() {
                              _currentStep = CheckoutStep.confirmation;
                            });
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Erreur lors de la création de la commande',
                                ),
                                backgroundColor: PharmaConnectColors.accentRed,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? PharmaConnectColors.accentCyan
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(_getPaymentIcon(method), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) ...[
              const Icon(
                Icons.check_circle,
                color: PharmaConnectColors.accentCyan,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPaymentIcon(String method) {
    switch (method) {
      case 'Orange Money':
        return '🟠';
      case 'MTN MoMo':
        return '🟡';
      case 'Moov Money':
        return '🔵';
      case 'Portefeuille GSG':
        return '⚡';
      case 'Paiement à la livraison':
        return '💰';
      default:
        return '💳';
    }
  }

  // ==================== ÉTAPE 4 : CONFIRMATION ====================

  Widget _buildConfirmationStep(ReservationProvider provider) {
    final reservation = provider.selectedReservation;
    if (reservation == null) {
      return const Center(child: Text('Aucune réservation trouvée'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlassCard(
            glow: true,
            glowColor: PharmaConnectColors.accentGreen,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: PharmaConnectColors.accentGreen,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Commande confirmée !',
                  style: PharmaConnectTypography.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre réservation a été prise en compte',
                  style: PharmaConnectTypography.body2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PharmaConnectColors.accentCyan.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PharmaConnectColors.accentCyan.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Numéro de commande',
                        style: PharmaConnectTypography.label,
                      ),
                      Text(
                        reservation.id,
                        style: PharmaConnectTypography.kpiMedium.copyWith(
                          color: PharmaConnectColors.accentCyan,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Position dans la file',
                            style: PharmaConnectTypography.label,
                          ),
                          Text(
                            reservation.queueDisplay,
                            style: PharmaConnectTypography.kpiSmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text(
                            'Temps d\'attente estimé',
                            style: PharmaConnectTypography.label,
                          ),
                          Text(
                            reservation.estimatedWaitDisplay,
                            style: PharmaConnectTypography.kpiSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // QR Code
          GlassCard(
            child: Column(
              children: [
                const Text(
                  'QR Code de retrait',
                  style: PharmaConnectTypography.heading3,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data:
                        reservation.qrCodeToken ??
                        'reservation_${reservation.id}',
                    version: QrVersions.auto,
                    size: 200,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Présentez ce QR code en pharmacie',
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/reservations/history'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Voir l\'historique'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Retour à l\'accueil',
                  icon: Icons.home,
                  onPressed: () => context.go('/dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
