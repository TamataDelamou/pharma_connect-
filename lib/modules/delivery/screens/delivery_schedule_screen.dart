import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DeliveryScheduleScreen extends StatelessWidget {
  const DeliveryScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Planification des livraisons',
      icon: Icons.event_note_outlined,
    );
  }
}
