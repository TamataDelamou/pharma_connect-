import 'package:flutter/material.dart';
import '../services/whatsapp_support_service.dart';
import '../../../core/theme/palette.dart';

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
        icon: Icon(Icons.chat, color: context.palette.success),
        onPressed: () =>
            service.startSupportChat(initialMessage: initialMessage),
        tooltip: 'Contacter le support WhatsApp',
      );
    }

    return ElevatedButton.icon(
      onPressed: () => service.startSupportChat(initialMessage: initialMessage),
      icon: const Icon(Icons.chat),
      label: const Text('💬 Support WhatsApp'),
      style: ElevatedButton.styleFrom(
        backgroundColor: PharmaConnectFixedColors.whatsapp,
        foregroundColor: PharmaConnectFixedColors.onWhatsapp,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
