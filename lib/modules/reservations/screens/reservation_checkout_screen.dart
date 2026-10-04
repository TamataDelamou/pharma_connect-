import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/profile_service.dart';
import '../../delivery/providers/delivery_provider.dart';
import '../../payments/models/payment_method.dart';
import '../../payments/providers/payment_provider.dart';
import '../providers/reservation_provider.dart';
import '../widgets/checkout_step_indicator.dart';
import '../widgets/timeslot_picker.dart';
import '../../../core/theme/palette.dart';

enum CheckoutStep { summary, timeslot, details, payment, confirmation }

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
  final ProfileService _profileService = ProfileService();
  final OfflineSyncService _offlineSync = OfflineSyncService();
  String _selectedPaymentMethod = 'Orange Money';
  bool _isSubmitting = false;
  // RG-LIV-01 (audit Module 7, 29/08/2026) : aucun produit ne porte
  // aujourd'hui de drapeau chaîne du froid automatique (voir Module 3/CAT —
  // territoire du futur Module CLD), donc sans cette case à cocher,
  // Delivery.isColdChainRequired resterait toujours false et la vérification
  // "livreur certifié chaîne du froid" ajoutée côté service ne se
  // déclencherait jamais en pratique. Choix délibéré : déclaration manuelle
  // du patient à la commande, en attendant un flag produit automatique.
  bool _isColdChainRequired = false;
  // Amélioration UX (audit Module 7, 29/08/2026) : permet d'afficher un
  // raccourci "Suivre ma livraison" sur l'écran de confirmation quand une
  // Delivery a bien été programmée, plutôt que de laisser le patient
  // chercher lui-même dans l'historique des livraisons.
  String? _scheduledDeliveryId;
  // Amélioration UX + fonctionnalité (audit Module 6, 29/08/2026) :
  // TimeslotPicker existait déjà dans le module mais n'était référencé nulle
  // part (grep : aucun call site pour loadAvailableSlots/selectSlot hors de
  // leurs propres définitions) — le parcours de commande n'avait donc aucune
  // étape de choix de créneau malgré "Réservation avec créneau de retrait"
  // (cahier de conception). preferredPickupTime restait toujours null en
  // conséquence. _selectedDate pilote la navigation par jour du picker.
  DateTime _selectedDate = DateTime.now();

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
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
                  Expanded(
                    child: Text(
                      'Validation de la commande',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: [const KernelBadge()],
            ),
            const SizedBox(height: 16),

            // Indicateur d'étape
            CheckoutStepIndicator(
              currentStep: _currentStep.index,
              steps: const [
                'Récapitulatif',
                'Créneau',
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
      case CheckoutStep.timeslot:
        return _buildTimeslotStep(provider);
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
                Text(
                  'Récapitulatif de la commande',
                  style: context.text.heading3,
                ),
                const SizedBox(height: 12),
                ...provider.cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: context.text.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: context.text.body1,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: context.text.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: context.palette.veil(0.12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: context.text.heading3),
                    Text(
                      CurrencyFormatter.format(provider.cartTotal),
                      style: context.text.kpiSmall.copyWith(
                        color: context.palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pharmacie : ${provider.selectedPharmacyName ?? 'Non sélectionnée'}',
                  style: context.text.body2,
                ),
                if (provider.selectedPharmacyAddress != null) ...[
                  Text(
                    provider.selectedPharmacyAddress!,
                    style: context.text.micro,
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
                    side: BorderSide(color: context.palette.veil(0.24)),
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
                      _currentStep = CheckoutStep.timeslot;
                    });
                    final pharmacyId = provider.selectedPharmacyId;
                    if (pharmacyId != null) {
                      provider.loadAvailableSlots(
                        pharmacyId: pharmacyId,
                        date: _selectedDate,
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

  // ==================== ÉTAPE 2 : CRÉNEAU DE RETRAIT ====================

  Widget _buildTimeslotStep(ReservationProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: provider.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : TimeslotPicker(
                    slots: provider.availableSlots,
                    selectedSlot: provider.selectedSlot,
                    selectedDate: _selectedDate,
                    onSlotSelected: provider.selectSlot,
                    onDateChanged: (date) {
                      setState(() => _selectedDate = date);
                      final pharmacyId = provider.selectedPharmacyId;
                      if (pharmacyId != null) {
                        provider.loadAvailableSlots(
                          pharmacyId: pharmacyId,
                          date: date,
                        );
                      }
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le choix d\'un créneau est optionnel : sans sélection, l\'officine '
            'vous contactera pour convenir d\'un horaire de retrait.',
            style: context.text.micro,
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
                    side: BorderSide(color: context.palette.veil(0.24)),
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

  // ==================== ÉTAPE 3 : DÉTAILS ====================

  Widget _buildDetailsStep(ReservationProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations de livraison', style: context.text.heading3),
                const SizedBox(height: 8),
                Text(
                  'Adresse de livraison (optionnel)',
                  style: context.text.label,
                ),
                const SizedBox(height: 4),
                GlassInput(
                  label: '',
                  hint: 'Votre adresse de livraison',
                  controller: _addressController,
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                Text(
                  'Instructions particulières (optionnel)',
                  style: context.text.label,
                ),
                const SizedBox(height: 4),
                GlassInput(
                  label: '',
                  hint: 'Digicode, étage, etc.',
                  controller: _notesController,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _isColdChainRequired,
                  onChanged: (value) =>
                      setState(() => _isColdChainRequired = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: context.palette.primary,
                  title: Text(
                    'Livraison chaîne du froid',
                    style: context.text.body2,
                  ),
                  subtitle: Text(
                    'Cochez si votre commande contient des produits nécessitant '
                    'un transport réfrigéré (insuline, vaccins, etc.)',
                    style: context.text.micro,
                  ),
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
                      _currentStep = CheckoutStep.timeslot;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.veil(0.24)),
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

  // ==================== ÉTAPE 4 : PAIEMENT ====================

  Widget _buildPaymentStep(ReservationProvider provider) {
    final palette = context.palette;
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode de paiement', style: context.text.heading3),
                const SizedBox(height: 8),
                Text('Montant total :', style: context.text.label),
                Text(
                  CurrencyFormatter.format(provider.cartTotal),
                  style: context.text.kpiSmall.copyWith(
                    color: context.palette.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choisissez votre moyen de paiement',
                  style: context.text.label,
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
                    side: BorderSide(color: context.palette.veil(0.24)),
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
                          // Bug corrigé (audit Module 6, 29/08/2026) : cet
                          // écran envoyait un patientId ('patient_123', pas
                          // un uuid valide), un patientName et un
                          // patientPhone en dur, et repliait un pharmacyId
                          // absent sur 'ph_1' — même défaut déjà corrigé
                          // pour prescription_upload_screen.dart (Module 5)
                          // et stock_adjustment_screen.dart (Module 4).
                          // reservations.patient_id/pharmacy_id sont de type
                          // uuid : ces insertions échouaient pour tout le
                          // monde en production.
                          final auth = context.read<AuthProvider>();
                          final patientId = auth.userId;
                          final pharmacyId = provider.selectedPharmacyId;
                          if (patientId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Vous devez être connecté pour réserver.',
                                ),
                                backgroundColor: context.palette.danger,
                              ),
                            );
                            return;
                          }
                          if (pharmacyId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Aucune officine sélectionnée pour cette commande.',
                                ),
                                backgroundColor: context.palette.danger,
                              ),
                            );
                            return;
                          }
                          setState(() => _isSubmitting = true);
                          final fullName = await _profileService.getFullName(
                            patientId,
                          );
                          final patientName =
                              fullName ??
                              auth.userEmail ??
                              auth.userPhone ??
                              'Patient';
                          final reservation = await provider.createReservation(
                            patientId: patientId,
                            patientName: patientName,
                            patientPhone: auth.userPhone ?? '',
                            patientEmail: auth.userEmail,
                            pharmacyId: pharmacyId,
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
                            // Mode hors-ligne (directive standing) : la
                            // commande est prise en compte localement et
                            // sera envoyée automatiquement au retour du
                            // réseau — informatif, non bloquant (même
                            // distinction que Module 5).
                            if (provider.isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Hors connexion : la commande est enregistrée sur '
                                    'cet appareil et sera envoyée automatiquement au '
                                    'retour du réseau.',
                                  ),
                                  backgroundColor: palette.warningStrong,
                                ),
                              );
                            }
                            // Bug corrigé (audit Module 8, 29/08/2026) :
                            // cet écran ne faisait que stocker un libellé
                            // libre paymentMethod sur la réservation elle-
                            // même — aucun lien avec transactions/wallets/
                            // invoices. PaymentService.initiateTransaction /
                            // PaymentProvider.initiatePayment étaient
                            // entièrement fonctionnels mais n'avaient
                            // jusqu'ici AUCUN point d'entrée réel dans
                            // l'application (voir le rapport d'audit) : ni
                            // paiement, ni portefeuille, ni facture n'a
                            // jamais été créé par un vrai parcours d'achat.
                            // Non bloquant pour la confirmation de commande
                            // (même logique que l'échec de programmation de
                            // livraison ci-dessous) : la réservation existe
                            // déjà, le patient est informé si le paiement
                            // échoue plutôt que de perdre sa commande.
                            final paymentMethod = _mapPaymentMethod(
                              _selectedPaymentMethod,
                            );
                            // Décision D13 (audit Module 8, 29/08/2026,
                            // arbitrée par le porteur du projet) : le
                            // paiement est bloqué explicitement hors
                            // connexion plutôt que de tenter un appel
                            // réseau voué à l'échec — la réservation, elle,
                            // reste prise en compte (mode hors-ligne déjà
                            // géré plus haut, RES).
                            final hasInternet = await _offlineSync
                                .hasInternet();
                            if (paymentMethod != null &&
                                !hasInternet &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Commande confirmée, mais le paiement est '
                                    'indisponible hors connexion. Réglez-le '
                                    'depuis l\'historique dès votre retour en ligne.',
                                  ),
                                  backgroundColor: palette.warningStrong,
                                ),
                              );
                            } else if (paymentMethod != null &&
                                context.mounted) {
                              final paymentProvider = context
                                  .read<PaymentProvider>();
                              final transaction = await paymentProvider
                                  .initiatePayment(
                                    userId: patientId,
                                    userPhone: auth.userPhone ?? '',
                                    amount: provider.cartTotal,
                                    method: paymentMethod,
                                    reservationId: reservation.id,
                                    pharmacyId: pharmacyId,
                                    pharmacyName: provider.selectedPharmacyName,
                                  );
                              if (transaction == null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Commande confirmée, mais le paiement a échoué : '
                                      '${paymentProvider.error ?? "erreur inconnue"}. '
                                      'Vous pourrez réessayer depuis l\'historique.',
                                    ),
                                    backgroundColor: palette.warningStrong,
                                  ),
                                );
                              }
                            }
                            // Bug corrigé (audit Module 7, 29/08/2026) :
                            // cet écran collectait une adresse de livraison
                            // mais ne créait jamais de Delivery — le module
                            // LIV tout entier (DeliveryService.scheduleDelivery
                            // et tout ce qui en dépend) était donc inatteignable
                            // depuis l'application, malgré "Livraison à
                            // domicile" comme fonctionnalité clé du cahier.
                            // Livraison programmée seulement si une adresse a
                            // été renseignée (elle reste optionnelle : sans
                            // adresse, le patient retire en officine, sans
                            // création de Delivery).
                            if (!context.mounted) return;
                            final deliveryAddress = _addressController.text
                                .trim();
                            if (deliveryAddress.isNotEmpty && context.mounted) {
                              final deliveryProvider = context
                                  .read<DeliveryProvider>();
                              final delivery = await deliveryProvider
                                  .scheduleDelivery(
                                    reservationId: reservation.id,
                                    patientId: patientId,
                                    patientName: patientName,
                                    patientPhone: auth.userPhone ?? '',
                                    deliveryAddress: deliveryAddress,
                                    // Aucune étape dédiée au choix d'un
                                    // horaire de livraison n'existe encore
                                    // (le créneau choisi plus haut concerne
                                    // le retrait en officine) — délai par
                                    // défaut documenté au registre comme
                                    // piste d'amélioration UX.
                                    scheduledAt: DateTime.now().add(
                                      const Duration(hours: 2),
                                    ),
                                    isColdChainRequired: _isColdChainRequired,
                                  );
                              if (delivery != null) {
                                _scheduledDeliveryId = delivery.id;
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Commande confirmée, mais la programmation de '
                                      'la livraison a échoué : '
                                      '${deliveryProvider.error ?? "erreur inconnue"}. '
                                      'Contactez l\'officine.',
                                    ),
                                    backgroundColor: palette.warningStrong,
                                  ),
                                );
                              }
                            }
                            if (!context.mounted) return;
                            setState(() {
                              _currentStep = CheckoutStep.confirmation;
                            });
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      'Erreur lors de la création de la commande',
                                ),
                                backgroundColor: palette.danger,
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
              ? context.palette.primary.withValues(alpha: 0.1)
              : context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.palette.primary
                : context.palette.surface,
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
                style: context.text.body1.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) ...[
              Icon(Icons.check_circle, color: context.palette.primary),
            ],
          ],
        ),
      ),
    );
  }

  // Amélioration/correctif (audit Module 8, 29/08/2026) : traduit le
  // libellé libre de _paymentMethods (propre à cet écran de checkout, non
  // modifié pour rester cohérent avec l'UI existante) vers l'enum
  // PaymentMethod attendu par PaymentProvider.initiatePayment.
  // 'Paiement en plusieurs fois' n'est volontairement pas proposé ici : cet
  // écran ne collecte pas le nombre d'échéances — l'échéancier reste
  // accessible via l'écran /payments dédié.
  PaymentMethod? _mapPaymentMethod(String label) {
    switch (label) {
      case 'Orange Money':
        return PaymentMethod.orangeMoney;
      case 'MTN MoMo':
        return PaymentMethod.mtnMomo;
      case 'Moov Money':
        return PaymentMethod.moovMoney;
      case 'Portefeuille GSG':
        return PaymentMethod.gsgWallet;
      case 'Paiement à la livraison':
        return PaymentMethod.cashOnDelivery;
      default:
        return null;
    }
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

  // ==================== ÉTAPE 5 : CONFIRMATION ====================

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
            glowColor: context.palette.success,
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: context.palette.success,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text('Commande confirmée !', style: context.text.heading2),
                const SizedBox(height: 4),
                Text(
                  'Votre réservation a été prise en compte',
                  style: context.text.body2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.palette.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('Numéro de commande', style: context.text.label),
                      Text(
                        reservation.id,
                        style: context.text.kpiMedium.copyWith(
                          color: context.palette.primary,
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
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Position dans la file',
                            style: context.text.label,
                          ),
                          Text(
                            reservation.queueDisplay,
                            style: context.text.kpiSmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          Text(
                            'Temps d\'attente estimé',
                            style: context.text.label,
                          ),
                          Text(
                            reservation.estimatedWaitDisplay,
                            style: context.text.kpiSmall,
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
                Text('QR Code de retrait', style: context.text.heading3),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.textPrimary,
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
                  style: context.text.micro,
                ),
              ],
            ),
          ),
          if (_scheduledDeliveryId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Suivre ma livraison',
                icon: Icons.local_shipping,
                onPressed: () =>
                    context.go('/deliveries/tracking/$_scheduledDeliveryId'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/reservations/history'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.veil(0.24)),
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
