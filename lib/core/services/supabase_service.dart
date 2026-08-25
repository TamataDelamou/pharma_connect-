import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://votre-projet.supabase.co';
  static const String supabaseAnonKey = 'votre-clé-anon';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => Supabase.instance.client.auth;

  User? get currentUser => auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> signOut() async => await auth.signOut();
}
