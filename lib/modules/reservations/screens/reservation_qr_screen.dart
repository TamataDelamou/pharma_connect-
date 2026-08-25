import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationQRScreen extends StatelessWidget {
  const ReservationQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'QR code de retrait',
      icon: Icons.qr_code_2,
    );
  }
}
