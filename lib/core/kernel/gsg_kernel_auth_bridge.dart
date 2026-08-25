import 'package:dio/dio.dart';

/// Pont d'échange de session vers le GSG ID (Kernel) — KER-ID-02.
///
/// Appelé après un `verifyOTP()` Supabase réussi, jamais avant : Supabase Auth
/// reste l'unique mécanisme qui authentifie l'utilisateur. Cet appel ne fait
/// qu'échanger la session déjà valide contre une identité GSG.
///
/// Ne lève jamais d'exception et ne bloque jamais le flux de connexion : si le
/// Kernel est injoignable, en panne, ou pas encore déployé, l'app continue en
/// mode dégradé avec la session Supabase seule (KER-ARC-03). L'appelant ne
/// doit jamais attendre ce résultat pour considérer le login terminé.
class GsgKernelAuthBridge {
  GsgKernelAuthBridge({Dio? httpClient, String? baseUrl})
    : _dio = httpClient ?? Dio(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  // TODO(kernel-integration) : remplacer par l'URL réelle du GSG Kernel une
  // fois fournie par l'architecte (cahier de conception v3.0). Même
  // convention que SupabaseService pour les valeurs de config à renseigner.
  static const String _defaultBaseUrl = 'https://kernel.gsg.example';

  static const Duration _timeout = Duration(seconds: 5);

  final Dio _dio;
  final String _baseUrl;

  Future<GsgIdentity?> exchangeSupabaseSession({
    required String supabaseAccessToken,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/v1/auth/sso/supabase',
        data: {'supabase_access_token': supabaseAccessToken, 'supabase_user_id': userId},
        options: Options(sendTimeout: _timeout, receiveTimeout: _timeout),
      );

      final data = response.data;
      final gsgId = data is Map ? data['gsg_id'] as String? : null;
      if (gsgId == null) return null;

      return GsgIdentity(gsgId: gsgId, gsgOrgId: data['gsg_org_id'] as String?);
    } catch (_) {
      return null;
    }
  }
}

class GsgIdentity {
  final String gsgId;
  final String? gsgOrgId;

  const GsgIdentity({required this.gsgId, this.gsgOrgId});
}
