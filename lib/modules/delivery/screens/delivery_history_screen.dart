import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Historique des livraisons',
      icon: Icons.history,
    );
  }
}
