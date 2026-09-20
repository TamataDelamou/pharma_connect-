import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _client = SupabaseService().client;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings: settings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, String>? data,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pharma_connect_channel',
          'PharmaConnect Notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Get user's push tokens
    final tokens = await _getUserTokens(userId);
    for (final token in tokens) {
      await _sendToToken(token, title, body, data);
    }
    await _logNotification(userId, title, body);
  }

  Future<List<String>> _getUserTokens(String userId) async {
    try {
      final response = await _client
          .from('push_tokens')
          .select('token')
          .eq('user_id', userId);
      return (response as List).map((e) => e['token'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendToToken(
    String token,
    String title,
    String body,
    Map<String, String>? data,
  ) async {
    // FCM or other push service implementation
    print('Sending push to token $token: $title - $body');
  }

  Future<void> _logNotification(
    String userId,
    String title,
    String body,
  ) async {
    try {
      await _client.from('notifications_history').insert({
        'patient_id': userId,
        'channel': 'push',
        'notification_type': 'general',
        'title': title,
        'message': body,
        'status': 'sent',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }
}
