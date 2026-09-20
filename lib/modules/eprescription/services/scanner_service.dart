import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/eprescription.dart';
import '../models/eprescription_item.dart';
import 'eprescription_service.dart';

class ScannerService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();

  // PRE-3 (audit Module 25, Étape 2/3, 30/08/2026) : `scanner_screen.dart`
  // accédait directement à `_imagePicker` (champ privé, déclaré dans CE
  // fichier) depuis un AUTRE fichier — en Dart, la visibilité privée est
  // portée par la bibliothèque (le fichier), pas par la classe : un champ
  // privé n'est visible que là où il est déclaré, cet accès ne pouvait pas
  // compiler. Corrigé en exposant une méthode publique dédiée plutôt que le
  // champ lui-même (encapsulation préservée).
  Future<XFile?> pickImage(ImageSource source) {
    return _imagePicker.pickImage(source: source);
  }

  Future<ScannedPrescription> scanPrescription({
    required String patientId,
    required XFile image,
  }) async {
    // Upload image
    final imageUrl = await _uploadImage(patientId, image);

    // OCR processing
    final ocrResult = await _performOCR(image);

    // Extract items
    final extractedItems = _extractItems(ocrResult);

    final scanned = ScannedPrescription(
      id: _uuid.v4(),
      patientId: patientId,
      imageUrl: imageUrl,
      ocrResult: ocrResult,
      extractedItems: extractedItems,
      status: 'completed',
      processedAt: DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    await _client.from('scanned_prescriptions').insert(scanned.toJson());

    return scanned;
  }

  Future<String> _uploadImage(String patientId, XFile image) async {
    final bytes = await image.readAsBytes();
    final path =
        'prescriptions/$patientId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('prescriptions').uploadBinary(path, bytes);
    return _client.storage.from('prescriptions').getPublicUrl(path);
  }

  Future<Map<String, dynamic>> _performOCR(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    // PRE-4 (audit Module 25, Étape 2/3, 30/08/2026) : `GoogleMlKit.vision`
    // appartient au paquet agrégateur `google_ml_kit`, jamais déclaré dans
    // `pubspec.yaml` (vérifié directement sur le fichier) — seul le paquet
    // scopé `google_mlkit_text_recognition` (importé ci-dessus) est présent,
    // qui expose directement la classe `TextRecognizer`. Corrigé par l'appel
    // direct au constructeur réellement fourni par ce paquet.
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();

    return {
      'text': recognizedText.text,
      'blocks': recognizedText.blocks
          .map(
            (block) => {
              'text': block.text,
              'corner_points': block.cornerPoints
                  .map((p) => {'x': p.x, 'y': p.y})
                  .toList(),
            },
          )
          .toList(),
    };
  }

  List<Map<String, String>> _extractItems(Map<String, dynamic> ocrResult) {
    final text = ocrResult['text'] as String;
    final lines = text.split('\n');
    final items = <Map<String, String>>[];

    for (final line in lines) {
      final regex = RegExp(r'([A-Za-z\s]+)(\d+\s*(mg|g|ml|µg))');
      final matches = regex.allMatches(line);
      for (final match in matches) {
        items.add({
          'name': match.group(1)?.trim() ?? '',
          'dosage': match.group(2)?.trim() ?? '',
        });
      }
    }

    return items;
  }

  Future<EPrescription> createFromScan(String scanId) async {
    final scanResponse = await _client
        .from('scanned_prescriptions')
        .select()
        .eq('id', scanId)
        .single();
    final scanned = ScannedPrescription.fromJson(
      scanResponse as Map<String, dynamic>,
    );

    final prescription = EPrescription(
      id: '',
      prescriptionNumber: '',
      patientId: scanned.patientId,
      doctorId: SupabaseService().currentUser!.id,
      prescribedAt: DateTime.now().toUtc(),
      validUntil: DateTime.now().add(const Duration(days: 30)),
      status: 'draft',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final eprescriptionService = EPrescriptionService();
    final saved = await eprescriptionService.createPrescription(prescription);

    for (final item in scanned.extractedItems) {
      await eprescriptionService.addItem(
        EPrescriptionItem(
          id: '',
          eprescriptionId: saved.id,
          medicationName: item['name'] ?? '',
          dosage: item['dosage'] ?? '',
          frequency: 'À déterminer',
          duration: 'À déterminer',
          quantity: 1,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    return saved;
  }
}

class ScannedPrescription {
  final String id;
  final String patientId;
  final String imageUrl;
  final Map<String, dynamic> ocrResult;
  final List<Map<String, String>> extractedItems;
  final String status;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  ScannedPrescription({
    required this.id,
    required this.patientId,
    required this.imageUrl,
    required this.ocrResult,
    required this.extractedItems,
    required this.status,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'image_url': imageUrl,
    'ocr_result': ocrResult,
    'extracted_items': extractedItems,
    'status': status,
    if (processedAt != null) 'processed_at': processedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ScannedPrescription.fromJson(Map<String, dynamic> json) =>
      ScannedPrescription(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        imageUrl: json['image_url'] as String,
        ocrResult: json['ocr_result'] as Map<String, dynamic>? ?? {},
        extractedItems:
            (json['extracted_items'] as List?)?.cast<Map<String, String>>() ??
            [],
        status: json['status'] as String? ?? 'pending',
        processedAt: json['processed_at'] != null
            ? DateTime.parse(json['processed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );
}
