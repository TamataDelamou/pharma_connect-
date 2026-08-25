import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class PharmacyQueueScreen extends StatelessWidget {
  const PharmacyQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "File d'attente pharmacie",
      icon: Icons.people_outline,
    );
  }
}
