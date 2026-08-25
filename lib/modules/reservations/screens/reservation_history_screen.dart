import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Historique des réservations',
      icon: Icons.history,
    );
  }
}
