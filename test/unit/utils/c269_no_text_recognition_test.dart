import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/services/text_recognition.dart';
import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:pharma_connect/modules/prescriptions/services/ocr_service.dart';

// C269 : la bibliothèque de reconnaissance de texte est retirée de la version
// pilote (8 à 12 Mo par APK). La lecture des codes-barres et des QR codes
// (mobile_scanner) reste.

class _FakeRecognizer implements TextRecognizerPort {
  @override
  Future<String> readText(String imagePath) async =>
      'Paracetamol 500mg 3 fois par jour pendant 5 jours';
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  test('aucune trace de la bibliothèque dans le code ni les dépendances', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => f.readAsStringSync().contains(
            "import 'package:google_mlkit_text_recognition",
          ),
        )
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
    expect(
      File(
        'pubspec.yaml',
      ).readAsStringSync().contains('google_mlkit_text_recognition'),
      isFalse,
    );
    // La lecture des QR codes au retrait reste.
    expect(
      File('pubspec.yaml').readAsStringSync().contains('mobile_scanner'),
      isTrue,
    );
  });

  test('lecture indisponible : message lisible, aucune erreur brute', () async {
    const recognizer = UnavailableTextRecognizer();
    await expectLater(
      recognizer.readText('photo.jpg'),
      throwsA(isA<TextRecognitionUnavailable>()),
    );
    expect(
      userMessage(const TextRecognitionUnavailable()),
      contains('Lecture automatique indisponible'),
    );
  });

  test('ordonnance : sans lecture, résultat vide, sans erreur', () async {
    final result = await OcrService().extractFromImage('photo.jpg');
    expect(result['items'], isEmpty);
    expect(result['isComplete'], isFalse);
  });

  test(
    'ordonnance : avec une lecture branchée, le texte est analysé',
    () async {
      final result = await OcrService(
        recognizer: _FakeRecognizer(),
      ).extractFromImage('photo.jpg');
      expect(result['rawText'], contains('Paracetamol'));
    },
  );
}
