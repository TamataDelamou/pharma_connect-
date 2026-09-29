import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';

/// C204 : choix fait dans le dialogue de remboursement.
class RefundDecision {
  final String reason;

  /// 'restock' (remise en stock) ou 'quarantine'.
  final String stockDisposition;

  const RefundDecision({required this.reason, required this.stockDisposition});
}

/// C204 : dialogue de remboursement commun (écran de remboursement et reçu).
/// Motif obligatoire (3 caractères au moins) et destination du stock choisie
/// explicitement, sans valeur par défaut. La règle jour / plafond / titulaire
/// est appliquée par le serveur, pas ici.
Future<RefundDecision?> showRefundConfirmationDialog(
  BuildContext context, {
  required String saleNumber,
  required int finalAmount,
  String initialReason = '',
}) {
  return showDialog<RefundDecision>(
    context: context,
    builder: (_) => RefundConfirmationDialog(
      saleNumber: saleNumber,
      finalAmount: finalAmount,
      initialReason: initialReason,
    ),
  );
}

class RefundConfirmationDialog extends StatefulWidget {
  final String saleNumber;
  final int finalAmount;
  final String initialReason;

  const RefundConfirmationDialog({
    super.key,
    required this.saleNumber,
    required this.finalAmount,
    this.initialReason = '',
  });

  @override
  State<RefundConfirmationDialog> createState() =>
      _RefundConfirmationDialogState();
}

class _RefundConfirmationDialogState extends State<RefundConfirmationDialog> {
  static const _minReasonLength = 3;

  late final TextEditingController _reasonController;
  String? _disposition;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _reasonController.text.trim().length >= _minReasonLength &&
      _disposition != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      title: const Text('🔄 Rembourser la vente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vente #${widget.saleNumber}',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 4),
            Text(
              'Montant : ${CurrencyFormatter.format(widget.finalAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: PharmaConnectColors.accentOrange,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire)',
                hintText: 'Au moins 3 caractères',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Destination du stock rendu',
              style: PharmaConnectTypography.label,
            ),
            const SizedBox(height: 8),
            _buildDispositionOption(
              value: 'restock',
              title: 'Remettre en stock',
              subtitle: 'Boîte intacte, peut être revendue',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 8),
            _buildDispositionOption(
              value: 'quarantine',
              title: 'Mettre en quarantaine',
              subtitle:
                  'Ne pas revendre (abîmée, ouverte, chaîne du froid, doute)',
              icon: Icons.block,
            ),
            const SizedBox(height: 16),
            const Text(
              'Au-delà du jour de la vente ou du plafond de l\'officine, '
              'seul le titulaire peut rembourser.',
              style: PharmaConnectTypography.micro,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () => Navigator.pop(
                  context,
                  RefundDecision(
                    reason: _reasonController.text.trim(),
                    stockDisposition: _disposition!,
                  ),
                )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmaConnectColors.accentOrange,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
          child: const Text('Rembourser'),
        ),
      ],
    );
  }

  Widget _buildDispositionOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _disposition == value;
    return InkWell(
      onTap: () => setState(() => _disposition = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? PharmaConnectColors.accentCyan : Colors.white24,
          ),
          color: selected
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? PharmaConnectColors.accentCyan
                  : PharmaConnectColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: PharmaConnectColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(subtitle, style: PharmaConnectTypography.micro),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
