import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthService {
  final GoTrueClient _auth = SupabaseService().auth;

  // ==================== TÉLÉPHONE ====================

  /// Envoie un OTP par SMS ou WhatsApp sur le numéro donné.
  /// [channel] : 'sms' ou 'whatsapp'
  Future<void> sendPhoneOtp(String phone, {String channel = 'sms'}) async {
    await _auth.signInWithOtp(
      phone: phone,
      channel: channel == 'whatsapp' ? OtpChannel.whatsapp : OtpChannel.sms,
    );
  }

  /// Vérifie le code OTP reçu par SMS/WhatsApp.
  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return _auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ==================== EMAIL ====================

  /// Envoie un Magic Link par email (redirection automatique).
  Future<void> sendMagicLink(String email, {String? redirectUrl}) async {
    await _auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl ?? 'https://app.gsg.com/callback',
    );
  }

  /// Envoie un code OTP par email (template avec {{ .Token }}).
  Future<void> sendEmailOtp(String email) async {
    await _auth.signInWithOtp(email: email);
  }

  /// Vérifie le code OTP reçu par email.
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    return _auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }
}
