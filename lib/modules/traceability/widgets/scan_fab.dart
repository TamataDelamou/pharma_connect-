import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';

class ScanFloatingButton extends StatelessWidget {
  const ScanFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push('/traceability/verify'),
      backgroundColor: PharmaConnectColors.accentCyan,
      child: const Icon(
        Icons.qr_code_scanner,
        color: PharmaConnectColors.textOnAccent,
      ),
    );
  }
}
