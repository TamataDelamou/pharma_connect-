import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../services/emergency_access_service.dart';

/// C219 / D63 : déclaration d'une urgence depuis un dossier de triage.
/// Demande un motif écrit, appelle le serveur et retourne `true` si l'accès
/// au dossier de santé du patient a été accordé (24 heures).
Future<bool> showEmergencyAccessDialog(
  BuildContext context, {
  required String triagePatientId,
}) async {
  final granted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EmergencyAccessDialog(triagePatientId: triagePatientId),
  );
  return granted ?? false;
}

class _EmergencyAccessDialog extends StatefulWidget {
  final String triagePatientId;

  const _EmergencyAccessDialog({required this.triagePatientId});

  @override
  State<_EmergencyAccessDialog> createState() => _EmergencyAccessDialogState();
}

class _EmergencyAccessDialogState extends State<_EmergencyAccessDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < EmergencyAccessService.minReasonLength) {
      setState(
        () => _error =
            'Indiquez le motif de l\'urgence '
            '(${EmergencyAccessService.minReasonLength} caractères au moins).',
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await EmergencyAccessService().declare(
        triagePatientId: widget.triagePatientId,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on EmergencyAccessException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Impossible de joindre le serveur. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      title: const Row(
        children: [
          Icon(Icons.emergency, color: PharmaConnectColors.accentRed),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Accès d\'urgence au dossier',
              style: PharmaConnectTypography.heading3,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous allez ouvrir le dossier de santé de ce patient sans son '
              'rendez-vous. L\'accès dure 24 heures. Votre nom, votre hôpital '
              'et le motif sont enregistrés et visibles par le patient et par '
              'GSG.',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motif de l\'urgence',
                hintText: 'Ex. : patient inconscient, recherche d\'allergies',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: PharmaConnectTypography.body2.copyWith(
                  color: PharmaConnectColors.accentRed,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open),
          label: const Text('Déclarer l\'urgence'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmaConnectColors.accentRed,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
