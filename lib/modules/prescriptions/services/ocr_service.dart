import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../catalog/services/catalog_service.dart';
import '../models/prescription_item.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final CatalogService _catalogService = CatalogService();

  Future<Map<String, dynamic>> extractFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;

      // Parser le texte extrait pour en extraire les médicaments
      final items = _parsePrescriptionText(text);
      final confidence = _calculateConfidence(text);

      return {
        'items': items,
        'confidenceScore': confidence,
        'rawText': text,
        'isComplete': confidence > 0.7,
      };
    } catch (e) {
      // Fallback : utiliser la simulation existante
      return _simulateExtraction(imagePath);
    }
  }

  void dispose() {
    _recognizer.close();
  }

  /// Suggère des noms de médicaments du catalogue proches de [wrongName],
  /// pour corriger une erreur de reconnaissance OCR.
  Future<List<String>> suggestCorrection(String wrongName) async {
    final products = await _catalogService.getProducts();
    final candidates = {
      for (final p in products) p.name,
      for (final p in products) p.genericName,
    };

    final scored =
        candidates
            .map(
              (name) => (
                name: name,
                distance: _levenshtein(
                  wrongName.toLowerCase(),
                  name.toLowerCase(),
                ),
              ),
            )
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));

    return scored.take(3).map((c) => c.name).toList();
  }

  int _levenshtein(String a, String b) {
    final costs = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var previous = costs[0];
      costs[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final current = a[i - 1] == b[j - 1]
            ? previous
            : 1 +
                  [
                    previous,
                    costs[j],
                    costs[j - 1],
                  ].reduce((x, y) => x < y ? x : y);
        previous = costs[j];
        costs[j] = current;
      }
    }
    return costs[b.length];
  }

  List<PrescriptionItem> _parsePrescriptionText(String text) {
    final items = <PrescriptionItem>[];
    final lines = text.split('\n');

    // Pattern de reconnaissance : "Nom médicament Dosage Forme"
    // Exemple : "Doliprane 1000 mg Comprimé"
    final pattern = RegExp(
      r'([A-Za-zÀ-ÿ\s]+)\s+(\d+)\s*(mg|g|µg|ml)\s+([A-Za-zÀ-ÿ]+)',
    );

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final dosage = '${match.group(2)} ${match.group(3)}';

        items.add(
          PrescriptionItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
            prescriptionId: '',
            medicationName: name,
            dosage: dosage,
            frequency: _guessFrequency(line),
            duration: _guessDuration(line),
            quantity: 1,
            isExtractedByOcr: true,
            ocrConfidence: 0.9,
          ),
        );
      }
    }

    return items;
  }

  String _guessFrequency(String text) {
    if (text.contains('matin') && text.contains('soir')) return '2x par jour';
    if (text.contains('matin')) return '1x par jour (matin)';
    if (text.contains('soir')) return '1x par jour (soir)';
    if (text.contains('repas')) return 'A prendre avec les repas';
    return 'A déterminer';
  }

  String _guessDuration(String text) {
    if (text.contains('jour')) {
      final match = RegExp(r'(\d+)\s*jours').firstMatch(text);
      if (match != null) return '${match.group(1)} jours';
    }
    return 'A déterminer';
  }

  double _calculateConfidence(String text) {
    // Calcul basé sur la longueur du texte et la présence de mots-clés
    final keywords = ['mg', 'comprimé', 'gélule', 'sirop', 'injection'];
    int found = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) found++;
    }
    return 0.6 + (found / keywords.length) * 0.4;
  }

  Map<String, dynamic> _simulateExtraction(String imagePath) {
    // Garder la simulation existante comme fallback
    return _legacySimulateExtraction(imagePath);
  }

  // Garder la méthode de simulation existante
  Map<String, dynamic> _legacySimulateExtraction(String imagePath) {
    // ... code existant de simulation
    return {'items': [], 'confidenceScore': 0.5, 'isComplete': false};
  }
}
