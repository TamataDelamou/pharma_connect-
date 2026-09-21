import 'package:url_launcher/url_launcher.dart';

class WhatsAppSupportService {
  static const String _supportNumber = '+224600000000';
  static const String _supportMessage = 'Bonjour PharmaConnect Support, ';

  Future<void> openWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final url =
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
    await _launchURL(url);
  }

  Future<void> startSupportChat({String? initialMessage}) async {
    final message = initialMessage != null
        ? '$_supportMessage$initialMessage'
        : '$_supportMessage je souhaite obtenir de l\'aide.';
    await openWhatsApp(_supportNumber, message);
  }

  Future<void> sendTicketNotification(String phone, String ticketNumber) async {
    final message =
        '📋 PharmaConnect Support: Votre ticket $ticketNumber a été mis à jour. '
        'Pour suivre l\'évolution, répondez à ce message.';
    await openWhatsApp(phone, message);
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      throw Exception('Error launching URL: $e');
    }
  }

  String getSupportNumber() => _supportNumber;
}
