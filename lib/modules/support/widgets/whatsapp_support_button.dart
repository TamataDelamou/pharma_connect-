import 'package:flutter/material.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import '../services/whatsapp_support_service.dart';

class WhatsAppSupportButton extends StatelessWidget {
  final String? initialMessage;
  final bool showIconOnly;

  const WhatsAppSupportButton({
    super.key,
    this.initialMessage,
    this.showIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = WhatsAppSupportService();

    if (showIconOnly) {
      return IconButton(
        icon: const Icon(Icons.chat, color: Colors.green),
        onPressed: () =>
            service.startSupportChat(initialMessage: initialMessage),
        tooltip: 'Contacter le support WhatsApp',
      );
    }

    return ElevatedButton.icon(
      onPressed: () => service.startSupportChat(initialMessage: initialMessage),
      icon: const Icon(Icons.chat, color: Colors.white),
      label: const Text('💬 Support WhatsApp'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
