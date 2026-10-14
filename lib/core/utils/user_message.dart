import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// C263 : erreur dont le message est déjà rédigé pour l'utilisateur (refus du
/// serveur traduit par un service : « Caisse fermée », « Code de retrait
/// incorrect »…). [userMessage] l'affiche tel quel.
abstract interface class UserFacingException implements Exception {
  String get message;
}

/// Message affiché quand le serveur ne répond pas.
const String offlineMessage =
    'Hors connexion. Vérifiez la connexion et réessayez.';

/// Message affiché pour toute autre erreur imprévue.
const String unexpectedErrorMessage =
    'Une erreur est survenue. Réessayez dans un instant.';

/// C263 : traduit une erreur en message lisible par l'utilisateur. Une
/// exception brute (classe, adresse du serveur, identifiant, pile d'appels)
/// n'est jamais affichée ; elle est seulement écrite dans le journal de
/// l'application.
String userMessage(Object error) {
  debugPrint('PharmaConnect, erreur : $error');

  if (error is UserFacingException) return error.message;
  if (isOfflineError(error)) return offlineMessage;

  if (error is AuthException) return _authMessage(error);

  // Refus métier du serveur (fonctions SQL : « POS: … », « RES: … »…), non
  // traduit par un service : préfixe technique retiré.
  if (error is PostgrestException &&
      const {'22023', '42501', 'P0001'}.contains(error.code)) {
    final text = error.message.replaceFirst(RegExp(r'^[A-Z]{2,8}: '), '');
    if (text.isNotEmpty) {
      return '${text[0].toUpperCase()}${text.substring(1)}.';
    }
  }

  return unexpectedErrorMessage;
}

/// Vrai si l'erreur vient d'un serveur injoignable (mode avion, pas de
/// réseau, délai dépassé), y compris quand un service l'a enveloppée dans
/// une autre exception.
bool isOfflineError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is AuthRetryableFetchException) {
    return true;
  }
  final text = error.toString();
  return const [
    'SocketException',
    'ClientException',
    'Failed host lookup',
    'Network is unreachable',
    'Connection refused',
    'Connection reset',
    'Connection closed',
    'TimeoutException',
    'HandshakeException',
  ].any(text.contains);
}

String _authMessage(AuthException error) {
  final code = error.code ?? '';
  final text = error.message.toLowerCase();
  if (code == 'otp_expired' ||
      text.contains('expired') ||
      text.contains('invalid') && text.contains('token')) {
    return 'Code expiré ou incorrect. Demandez un nouveau code.';
  }
  if (code.startsWith('over_') ||
      text.contains('rate limit') ||
      error.statusCode == '429') {
    return 'Trop de demandes. Patientez une minute avant de redemander un code.';
  }
  if (code == 'email_address_invalid' || code == 'validation_failed') {
    return 'Adresse e-mail invalide.';
  }
  return 'Connexion impossible. Vérifiez votre saisie et réessayez.';
}
