import 'package:flutter/material.dart';
import '../theme/colors.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirmer',
  String cancelText = 'Annuler',
  Color confirmColor = PharmaConnectColors.accentRed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: PharmaConnectColors.primaryDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          color: PharmaConnectColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: PharmaConnectColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: const TextStyle(color: PharmaConnectColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: PharmaConnectColors.textPrimary,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
