import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://qemizapoldevapmygryp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlbWl6YXBvbGRldmFwbXlncnlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4MjU5NjMsImV4cCI6MjEwMzQwMTk2M30.oVUr5Dl54W2qSJjuYma0XQTaelBkeqDhCCbJKqm9fu0';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => Supabase.instance.client.auth;

  User? get currentUser => auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> signOut() async => await auth.signOut();
}
