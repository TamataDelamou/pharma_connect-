import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Réservation confirmée',
      icon: Icons.check_circle_outline,
    );
  }
}
