import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/pickup_line.dart';
import '../providers/reservation_provider.dart';
import '../widgets/reservation_status_card.dart';
import 'pickup_code_scanner_screen.dart';

/// C243 : retrait d'une réservation à l'officine. La réservation devient une
/// vente au comptoir en espèces, au prix du jour imposé par le serveur ;
/// l'écart avec le prix indicatif de la réservation est affiché avant
/// l'encaissement. Un produit dont le lot a été rappelé ou est périmé, sans
/// remplaçant, ne peut être remis : retrait partiel motivé, ou annulation.
/// Le code de retrait du patient (saisi ou lu sur son QR) est exigé par le
/// serveur ; il n'est pas affiché ici.
class ReservationPickupScreen extends StatefulWidget {
  final String reservationId;

  const ReservationPickupScreen({super.key, required this.reservationId});

  @override
  State<ReservationPickupScreen> createState() =>
      _ReservationPickupScreenState();
}

class _ReservationPickupScreenState extends State<ReservationPickupScreen> {
  final _partialReasonController = TextEditingController();
  final _codeController = TextEditingController();
  bool _prescriptionChecked = false;
  bool _partial = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().loadPickup(widget.reservationId);
    });
  }

  @override
  void dispose() {
    _partialReasonController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Code saisi, sans espaces : le serveur ignore la casse.
  String get _code => _codeController.text.replaceAll(RegExp(r'\s'), '');

  Future<void> _scanCode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PickupCodeScannerScreen()),
    );
    if (!mounted || scanned == null) return;
    setState(() => _codeController.text = scanned.toUpperCase());
  }

  Future<void> _pickUp() async {
    final provider = context.read<ReservationProvider>();
    setState(() => _isSubmitting = true);
    final saleId = await provider.pickUp(
      widget.reservationId,
      pickupCode: _code,
      prescriptionChecked: _prescriptionChecked,
      allowPartial: _partial,
      partialReason: _partial ? _partialReasonController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (saleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Retrait impossible.'),
          backgroundColor: context.palette.danger,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrait enregistré : vente créée.')),
    );
    context.pushReplacement('/pos/receipt/$saleId');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ReservationProvider>();
    final reservation = provider.selectedReservation;
    final lines = provider.pickupLines;

    if (auth.effectiveRole != UserRole.pharmacien) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Réservé aux pharmaciens de l\'officine.',
              style: context.text.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final unavailable = lines.where((l) => l.isUnavailable).toList();
    final served = _partial
        ? lines.where((l) => !l.isUnavailable).toList()
        : lines;
    final reservedTotal = served.fold(0, (sum, l) => sum + l.reservedTotal);
    final currentTotal = served.fold(0, (sum, l) => sum + l.currentTotal);
    final gap = currentTotal - reservedTotal;
    final needsPrescription = served.any((l) => l.prescriptionRequired);
    // Un produit ne peut plus être remis et le retrait partiel n'est pas
    // choisi : aucun montant à encaisser tant que le choix n'est pas fait.
    final choicePending = unavailable.isNotEmpty && !_partial;
    final canSubmit =
        !_isSubmitting &&
        served.isNotEmpty &&
        _code.length >= 6 &&
        (unavailable.isEmpty ||
            (_partial && _partialReasonController.text.trim().length >= 3));

    return Scaffold(
      body: Padding(
        padding: screenPadding(context, wide: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      'Retrait de la réservation',
                      style: context.text.heading2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: const [],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reservation == null || lines.isEmpty
                  ? Center(
                      child: Text(
                        provider.error ?? 'Réservation introuvable.',
                        style: context.text.body2,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.patientName,
                                  style: context.text.heading3,
                                ),
                                if (reservation.pickupDeadline != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'À retirer avant le '
                                    '${formatReservationDateTime(reservation.pickupDeadline!)}',
                                    style: context.text.micro,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _codeController,
                                  onChanged: (_) => setState(() {}),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: 'Code de retrait du patient',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      tooltip: 'Scanner le QR du patient',
                                      onPressed: _scanCode,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saisissez le code à 6 caractères du patient, '
                                  'ou scannez son QR.',
                                  style: context.text.micro,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Produits', style: context.text.heading3),
                                const SizedBox(height: 8),
                                for (final line in lines) _buildLine(line),
                                Divider(color: context.palette.veil(0.12)),
                                _totalRow(
                                  'Prix indicatif à la réservation',
                                  CurrencyFormatter.format(reservedTotal),
                                ),
                                _totalRow(
                                  'Prix du jour',
                                  CurrencyFormatter.format(currentTotal),
                                ),
                                if (gap != 0)
                                  _totalRow(
                                    'Écart',
                                    '${gap > 0 ? '+ ' : '- '}'
                                        '${CurrencyFormatter.format(gap.abs())}',
                                    color: context.palette.warning,
                                  ),
                                const SizedBox(height: 4),
                                _totalRow(
                                  'À encaisser en espèces',
                                  choicePending
                                      ? '—'
                                      : CurrencyFormatter.format(currentTotal),
                                  strong: true,
                                ),
                                if (choicePending)
                                  Text(
                                    'Choisissez le retrait partiel ou annulez '
                                    'la réservation : le montant sera calculé '
                                    'sur les produits remis.',
                                    style: context.text.micro.copyWith(
                                      color: context.palette.danger,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (unavailable.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildUnavailable(unavailable),
                          ],
                          if (needsPrescription) ...[
                            const SizedBox(height: 4),
                            CheckboxListTile(
                              value: _prescriptionChecked,
                              onChanged: (value) => setState(
                                () => _prescriptionChecked = value ?? false,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: context.palette.primary,
                              title: Text(
                                'Ordonnance présentée et vérifiée',
                                style: context.text.body2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Encaisser et remettre',
                            icon: Icons.point_of_sale,
                            isLoading: _isSubmitting,
                            isDisabled: !canSubmit,
                            onPressed: _pickUp,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Le retrait crée une vente au comptoir en espèces, '
                            'au prix du jour. Votre caisse doit être ouverte.',
                            style: context.text.micro,
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

  Widget _buildLine(PickupLine line) {
    final removed = _partial && line.isUnavailable;
    final priceChanged = line.currentUnitPrice != line.reservedUnitPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${line.quantity}x',
            style: context.text.body2.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.productName} ${line.dosage}'.trim(),
                  style: context.text.body1.copyWith(
                    decoration: removed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  priceChanged
                      ? 'Réservé à ${CurrencyFormatter.format(line.reservedUnitPrice)}, '
                            'prix du jour ${CurrencyFormatter.format(line.currentUnitPrice)}'
                      : '${CurrencyFormatter.format(line.currentUnitPrice)} l\'unité',
                  style: context.text.micro,
                ),
                if (line.prescriptionRequired)
                  Text(
                    'Ordonnance à présenter',
                    style: context.text.micro.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                if (line.isUnavailable)
                  Text(
                    'Lot rappelé ou périmé, aucun autre lot : ne peut pas '
                    'être remis',
                    style: context.text.micro.copyWith(
                      color: context.palette.danger,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            removed ? '—' : CurrencyFormatter.format(line.currentTotal),
            style: context.text.body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool strong = false,
    Color? color,
  }) {
    final style = (strong ? context.text.body1 : context.text.body2).copyWith(
      fontWeight: strong ? FontWeight.w700 : null,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildUnavailable(List<PickupLine> unavailable) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.palette.danger.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${unavailable.map((l) => l.productName).join(', ')} : ne peut '
            'plus être remis. Proposez un retrait partiel, ou annulez la '
            'réservation.',
            style: context.text.body2.copyWith(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SwitchListTile(
            value: _partial,
            onChanged: (value) => setState(() => _partial = value),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: context.palette.primary,
            title: Text(
              'Retrait partiel, sans ce produit',
              style: context.text.body2,
            ),
          ),
          if (_partial)
            TextField(
              controller: _partialReasonController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
        ],
      ),
    );
  }
}
