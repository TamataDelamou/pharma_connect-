import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class SystemConfigScreen extends StatelessWidget {
  const SystemConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Configuration système',
      message: 'La configuration système (paliers, seuils, intégrations) est en cours de développement.',
      icon: Icons.settings,
    );
  }
}
