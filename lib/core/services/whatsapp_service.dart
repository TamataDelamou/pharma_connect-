import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static const String _supportNumber = '+224600000000';

  Future<void> openWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final url =
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
    await _launchURL(url);
  }

  Future<void> startSupportChat(String message) async {
    final msg = 'Bonjour PharmaConnect Support, $message';
    await openWhatsApp(_supportNumber, msg);
  }

  Future<void> sendAlert(String phone, String message) async {
    await openWhatsApp(phone, message);
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
