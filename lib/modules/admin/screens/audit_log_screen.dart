import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Journal d\'audit',
      message:
          'La consultation du journal d\'audit centralisé (Kernel) est en cours de développement.',
      icon: Icons.fact_check,
    );
  }
}
