import 'dart:convert';
import 'package:pharma_connect/core/services/supabase_service.dart';

class TranslationService {
  final Map<String, String> _cache = {};
  final _client = SupabaseService().client;

  static const Map<String, String> _languageNames = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  static const List<String> supportedLanguages = ['fr', 'en', 'ar'];

  Future<String> translate(String text, String targetLang) async {
    if (text.isEmpty) return text;
    if (targetLang == 'fr') return text; // Default language

    // Check cache
    final cacheKey = '$text|$targetLang';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    // Simulate translation (in production, use Google Translate API)
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock translations
    final translations = _getMockTranslations();
    String result = text;

    for (final entry in translations.entries) {
      if (text.contains(entry.key)) {
        final translated = entry.value[targetLang] ?? entry.key;
        result = result.replaceAll(entry.key, translated);
      }
    }

    _cache[cacheKey] = result;
    return result;
  }

  Future<String> detectLanguage(String text) async {
    // Simple detection based on common words
    final frenchWords = [
      'bonjour',
      'merci',
      'comment',
      'pour',
      'avec',
      'sans',
      'oui',
      'non',
    ];
    final englishWords = [
      'hello',
      'thank',
      'how',
      'for',
      'with',
      'without',
      'yes',
      'no',
    ];
    final arabicWords = ['مرحبا', 'شكرا', 'كيف', 'مع', 'بدون', 'نعم', 'لا'];

    final lower = text.toLowerCase();
    for (final word in frenchWords) {
      if (lower.contains(word)) return 'fr';
    }
    for (final word in englishWords) {
      if (lower.contains(word)) return 'en';
    }
    for (final word in arabicWords) {
      if (lower.contains(word)) return 'ar';
    }
    return 'fr';
  }

  Map<String, Map<String, String>> _getMockTranslations() {
    return {
      'Bonjour': {'en': 'Hello', 'ar': 'مرحبا'},
      'Comment allez-vous?': {'en': 'How are you?', 'ar': 'كيف حالك؟'},
      'Merci': {'en': 'Thank you', 'ar': 'شكرا'},
      'Au revoir': {'en': 'Goodbye', 'ar': 'وداعا'},
      'Oui': {'en': 'Yes', 'ar': 'نعم'},
      'Non': {'en': 'No', 'ar': 'لا'},
      'Urgence': {'en': 'Emergency', 'ar': 'طوارئ'},
      'Aide': {'en': 'Help', 'ar': 'مساعدة'},
      'Médicament': {'en': 'Medication', 'ar': 'دواء'},
      'Rendez-vous': {'en': 'Appointment', 'ar': 'موعد'},
      'Pharmacie': {'en': 'Pharmacy', 'ar': 'صيدلية'},
    };
  }

  Map<String, String> getLanguageNames() {
    return _languageNames;
  }
}
