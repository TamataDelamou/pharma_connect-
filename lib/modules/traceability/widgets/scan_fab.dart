import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/palette.dart';

class ScanFloatingButton extends StatelessWidget {
  const ScanFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push('/traceability/verify'),
      backgroundColor: context.palette.primary,
      child: Icon(Icons.qr_code_scanner, color: context.palette.onPrimary),
    );
  }
}
