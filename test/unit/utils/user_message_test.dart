import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:pharma_connect/modules/cash/services/cash_service.dart';
import 'package:pharma_connect/modules/pos/services/pos_service.dart';
import 'package:pharma_connect/modules/reservations/services/reservation_service.dart';

// C263 : une erreur n'est jamais affichée telle quelle à l'utilisateur.

/// Mots qui ne doivent jamais apparaître dans un message affiché.
const _technical = [
  'Exception',
  'Socket',
  'supabase',
  'uri=',
  'errno',
  'Postgrest',
  'statusCode',
];

void _expectReadable(String message) {
  for (final word in _technical) {
    expect(
      message.contains(word),
      isFalse,
      reason: '« $word » dans « $message »',
    );
  }
}

void main() {
  group('hors connexion', () {
    final cases = <String, Object>{
      'SocketException': const SocketException('Failed host lookup'),
      'TimeoutException': TimeoutException('lecture'),
      'erreur relevée à l\'essai, enveloppée par un service': Exception(
        'Failed to get cash summary: ClientException with SocketException: '
        'Failed host lookup: xyzabc.supabase.co (OS Error: No address '
        'associated with hostname, errno = 7), uri=https://xyzabc.supabase.co'
        '/rest/v1/reservations?id=eq.71996b45',
      ),
      'connexion refusée': Exception('Connection refused'),
      'AuthRetryableFetchException': AuthRetryableFetchException(),
    };
    cases.forEach((name, error) {
      test(name, () {
        expect(userMessage(error), offlineMessage);
        expect(isOfflineError(error), isTrue);
      });
    });
  });

  test('refus rédigé par un service : affiché tel quel', () {
    expect(
      userMessage(const ReservationException('Code de retrait incorrect.')),
      'Code de retrait incorrect.',
    );
    expect(
      userMessage(
        const POSSaleException('Caisse fermée : ouvrez votre caisse.'),
      ),
      'Caisse fermée : ouvrez votre caisse.',
    );
    expect(
      userMessage(const CashException('Vous avez déjà une caisse ouverte.')),
      'Vous avez déjà une caisse ouverte.',
    );
  });

  test('refus métier du serveur non traduit : préfixe technique retiré', () {
    final message = userMessage(
      const PostgrestException(
        message: 'POS: remise non autorisee (remise 32)',
        code: '22023',
      ),
    );
    expect(message, 'Remise non autorisee (remise 32).');
    _expectReadable(message);
  });

  test('connexion : code expiré, trop de demandes, autre refus', () {
    expect(
      userMessage(
        const AuthApiException(
          'Token has expired or is invalid',
          statusCode: '403',
          code: 'otp_expired',
        ),
      ),
      'Code expiré ou incorrect. Demandez un nouveau code.',
    );
    expect(
      userMessage(
        const AuthApiException(
          'For security purposes, you can only request this after 60 seconds',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      ),
      'Trop de demandes. Patientez une minute avant de redemander un code.',
    );
    _expectReadable(
      userMessage(const AuthApiException('Something odd', statusCode: '400')),
    );
  });

  test('toute autre erreur : message générique, jamais le détail', () {
    final cases = <Object>[
      Exception('Null check operator used on a null value'),
      StateError('Bad state: No element'),
      const PostgrestException(
        message: 'relation does not exist',
        code: '42P01',
      ),
      const FormatException('Unexpected character'),
    ];
    for (final error in cases) {
      expect(userMessage(error), unexpectedErrorMessage);
    }
  });
}
