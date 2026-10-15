import '../utils/user_message.dart';

/// C269 : lecture automatique du texte d'une photo (ordonnance).
///
/// La bibliothèque de reconnaissance de texte (ML Kit,
/// `google_mlkit_text_recognition`) est retirée de la version pilote : elle
/// ajoutait 8 à 12 Mo à chaque APK pour une fonction masquée pendant le pilote
/// (`PilotConfig.aiPrescriptionOcr`). Les services qui lisaient une photo
/// passent par ce contrat ; la version pilote fournit
/// [UnavailableTextRecognizer]. Pour rouvrir la lecture d'ordonnances, une
/// implémentation réelle de [TextRecognizerPort] sera branchée ici, avec la
/// bibliothèque, dans une version qui l'embarque.
abstract interface class TextRecognizerPort {
  /// Texte lu sur l'image du fichier [imagePath].
  Future<String> readText(String imagePath);
}

/// Refus : la lecture automatique n'est pas disponible dans cette version.
class TextRecognitionUnavailable implements UserFacingException {
  const TextRecognitionUnavailable();

  @override
  String get message =>
      'Lecture automatique indisponible dans cette version. Saisissez '
      'l\'ordonnance à la main.';

  @override
  String toString() => message;
}

/// Version pilote : aucune lecture automatique, aucune bibliothèque.
class UnavailableTextRecognizer implements TextRecognizerPort {
  const UnavailableTextRecognizer();

  @override
  Future<String> readText(String imagePath) async =>
      throw const TextRecognitionUnavailable();
}
