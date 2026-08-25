import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class PharmaciesManagementScreen extends StatelessWidget {
  const PharmaciesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Gestion des officines',
      message:
          'La gestion centralisée des officines (validation DNPM, statut, licences) est en cours de développement.',
      icon: Icons.local_pharmacy,
    );
  }
}
