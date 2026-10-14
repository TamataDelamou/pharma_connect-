import 'package:flutter/material.dart';
import 'package:pharma_connect/core/utils/user_message.dart';
import '../../../core/kernel/gsg_kernel_auth_bridge.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_role.dart';
import '../models/account_status.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final GsgKernelAuthBridge _kernelBridge = GsgKernelAuthBridge();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userPhone;
  UserRole? _userRole;
  String? _pendingIdentifier; // stocke l'email ou téléphone en cours
  String? _gsgId;
  String? _gsgOrgId;
  String? _pharmacyId;
  bool _isGsgAdmin = false;
  AccountStatus? _accountStatus;
  // C228 : nom du profil. `_profileLoaded` distingue « nom vide » de « profil
  // pas encore lu » (hors réseau) : sans lecture, on ne demande rien.
  String? _fullName;
  bool _profileLoaded = false;
  bool _profileCompletionSkipped = false;
  String? _error; // Gestion d'erreur

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  UserRole? get userRole => _userRole;
  String? get pendingIdentifier => _pendingIdentifier;
  String? get gsgId => _gsgId;
  String? get gsgOrgId => _gsgOrgId;
  String? get pharmacyId => _pharmacyId;

  /// Pose un rattachement sans appel au serveur (tests et captures d'écran).
  @visibleForTesting
  set pharmacyIdForTesting(String? pharmacyId) {
    _pharmacyId = pharmacyId;
    notifyListeners();
  }

  /// Vrai si le compte connecté est aussi un membre actif du back-office GSG
  /// (`public.admin_users`, audit Module 14, 29/08/2026). Reflète côté client
  /// exactement le test déjà utilisé par la RLS `is_gsg_admin()` — sans
  /// dupliquer sa logique : c'est une simple lecture best-effort de la même
  /// table, jamais utilisée pour décider d'un accès (la RLS reste seule
  /// autorité), seulement pour savoir quelles actions proposer à l'écran
  /// (ex. Approuver/Rejeter/Décaisser en financement, request_detail_screen).
  bool get isGsgAdmin => _isGsgAdmin;

  /// Pose le statut d'administrateur GSG sans appel au serveur (tests et
  /// captures d'écran).
  @visibleForTesting
  set isGsgAdminForTesting(bool value) {
    _isGsgAdmin = value;
    notifyListeners();
  }

  String? get error => _error;

  String? get fullName => _fullName;

  /// C228 : vrai si l'écran « Complétez votre profil » doit s'afficher :
  /// compte connecté, profil lu, nom vide, et pas de « Plus tard » pendant
  /// cette session. « Plus tard » ne vaut que jusqu'à la prochaine connexion.
  bool get needsProfileCompletion =>
      _isAuthenticated &&
      _profileLoaded &&
      (_fullName == null || _fullName!.trim().isEmpty) &&
      !_profileCompletionSkipped;

  /// C213 / D64 : état du compte lu sur le serveur (null tant qu'il n'a pas
  /// pu être lu, par exemple hors réseau).
  AccountStatus? get accountStatus => _accountStatus;

  /// Pose un état de compte sans appel au serveur (tests et captures
  /// d'écran).
  @visibleForTesting
  set accountStatusForTesting(AccountStatus? status) {
    _accountStatus = status;
    notifyListeners();
  }

  /// C213 / D64 : vrai si le rôle déclaré ouvre ses droits (vérifié par GSG,
  /// pharmacien d'une officine active). Sans état lu, l'application garde le
  /// rôle déclaré : le serveur reste seul juge des droits.
  bool get isRoleActive =>
      _userRole == null ||
      _userRole == UserRole.patient ||
      (_accountStatus?.roleActive ?? true);

  /// C213 / D64 : rôle à utiliser pour les menus et les écrans. Tant que le
  /// rôle déclaré n'est pas vérifié, le compte utilise l'application comme
  /// un patient (un bandeau explique la situation).
  UserRole? get effectiveRole => isRoleActive ? _userRole : UserRole.patient;

  /// RG-AUT-01 (audit Module 1, 29/08/2026) : un compte pharmacien sans
  /// officine rattachée doit passer par la vérification de licence avant
  /// le tableau de bord. `_pharmacyId` n'est jamais renseigné par
  /// l'auto-inscription (voir pharmacy_service.dart et la migration
  /// 20260829013000) — seul le back-office GSG le fait, après vérification.
  /// C213 : une candidature déjà déposée (en attente) ou une officine
  /// suspendue ne renvoient plus vers le formulaire, mais vers le tableau de
  /// bord, où le bandeau d'état du compte explique la situation.
  bool get needsLicenseVerification {
    if (_userRole != UserRole.pharmacien || _pharmacyId != null) return false;
    final status = _accountStatus;
    return status == null || status.canRegisterPharmacy;
  }

  /// C213 : relit l'état du compte (après une action qui peut le changer,
  /// ou à la demande de l'utilisateur depuis le bandeau).
  Future<void> refreshAccountStatus() async {
    if (_userId == null) return;
    await _loadAccountStatus();
    notifyListeners();
  }

  Future<void> _loadAccountStatus() async {
    _accountStatus = await _profileService.getAccountStatus();
  }

  // === TÉLÉPHONE ===

  Future<bool> sendPhoneOtp(String phone, String channel) async {
    final normalized = Validators.normalizeE164(phone);
    if (normalized == null) {
      _error = 'Numéro de téléphone invalide';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await _authService.sendPhoneOtp(normalized, channel: channel);
      _pendingIdentifier = normalized;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = userMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(
    String phone,
    String token, {
    String? fullName,
    UserRole? role,
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyPhoneOtp(phone, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userPhone = user.phone;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        if (role != null) _userRole = role;
        await _persistProfile(
          user.id,
          phone: user.phone,
          fullName: fullName,
          role: role,
        );
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = userMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // === EMAIL ===

  Future<bool> sendEmailOtp(String email, bool isMagicLink) async {
    _setLoading(true);
    try {
      if (isMagicLink) {
        await _authService.sendMagicLink(email);
      } else {
        await _authService.sendEmailOtp(email);
      }
      _pendingIdentifier = email;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = userMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmailOtp(
    String email,
    String token, {
    String? fullName,
    UserRole? role,
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyEmailOtp(email, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userEmail = user.email;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        if (role != null) _userRole = role;
        await _persistProfile(user.id, fullName: fullName, role: role);
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = userMessage(e);
      _setLoading(false);
      return false;
    }
  }

  /// Ecriture best-effort de public.profiles : l'authentification a déjà
  /// réussi à ce stade (id/token Supabase valides), une panne réseau ici ne
  /// doit pas transformer une connexion réussie en échec de vérification.
  Future<void> _persistProfile(
    String userId, {
    String? phone,
    String? fullName,
    UserRole? role,
  }) async {
    // C228 : nouvelle connexion, « Plus tard » ne vaut plus.
    _profileCompletionSkipped = false;
    try {
      final row = await _profileService.upsertProfile(
        id: userId,
        phone: phone,
        fullName: fullName,
        role: role?.name,
      );
      // Relit toujours role/pharmacy_id depuis la ligne persistée plutôt
      // que du seul paramètre role (audit Module 1, 29/08/2026) : une
      // simple connexion (login_screen.dart) ne fournit pas de rôle, seule
      // l'inscription le fait — sans cette relecture, needsLicenseVerification
      // serait systématiquement faux pour un pharmacien qui se reconnecte.
      if (row != null) {
        final roleStr = row['role'] as String?;
        if (roleStr != null) {
          _userRole = UserRole.values.byName(roleStr);
        }
        _pharmacyId = row['pharmacy_id'] as String?;
        _fullName = row['full_name'] as String?;
        _profileLoaded = true;
      }
    } catch (_) {
      // Best-effort — voir docstring ci-dessus.
    }
    await _loadAdminStatus(userId);
    await _loadAccountStatus();
  }

  /// Best-effort, même rationale que `_persistProfile` ci-dessus : une
  /// panne réseau ou l'absence de ligne `admin_users` (l'immense majorité
  /// des comptes) ne doit jamais transformer une connexion réussie en échec
  /// — `_isGsgAdmin` reste simplement à `false`.
  Future<void> _loadAdminStatus(String userId) async {
    try {
      final row = await SupabaseService().client
          .from('admin_users')
          .select('is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      _isGsgAdmin = row != null;
    } catch (_) {
      _isGsgAdmin = false;
    }
  }

  // === PONT GSG KERNEL ===

  void _bridgeToGsgKernel(String userId, String? accessToken) {
    if (accessToken == null) return;
    _kernelBridge
        .exchangeSupabaseSession(
          supabaseAccessToken: accessToken,
          userId: userId,
        )
        .then((identity) {
          if (identity == null) return;
          _gsgId = identity.gsgId;
          _gsgOrgId = identity.gsgOrgId;
          notifyListeners();
        });
  }

  // === RESTAURATION DE SESSION (C199) ===

  /// Supabase persiste la session sur l'appareil et le routeur envoie
  /// directement sur /dashboard au redémarrage, mais l'état de ce provider
  /// n'était rempli qu'à la vérification OTP. Sans cette relecture,
  /// pharmacyId/userRole/isGsgAdmin restaient null après chaque réouverture
  /// de l'app, pour tous les modules qui s'appuient sur AuthProvider.
  Future<void> restoreSession() async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    _userId = user.id;
    _userEmail = user.email;
    _userPhone = user.phone;
    _isAuthenticated = true;

    final row = await _profileService.getProfile(user.id);
    if (row != null) {
      final roleStr = row['role'] as String?;
      if (roleStr != null) {
        // Rôle inconnu de l'enum : _userRole reste null plutôt que de faire
        // échouer l'ouverture de l'app.
        try {
          _userRole = UserRole.values.byName(roleStr);
        } catch (_) {}
      }
      _pharmacyId = row['pharmacy_id'] as String?;
      _fullName = row['full_name'] as String?;
      _profileLoaded = true;
    }
    await _loadAdminStatus(user.id);
    await _loadAccountStatus();
    notifyListeners();

    _bridgeToGsgKernel(
      user.id,
      SupabaseService().auth.currentSession?.accessToken,
    );
  }

  // === PROFIL À COMPLÉTER (C228) ===

  /// « Plus tard » : l'écran ne revient pas pendant cette session. Il
  /// reviendra à la prochaine connexion tant que le nom est vide.
  void skipProfileCompletion() {
    _profileCompletionSkipped = true;
    notifyListeners();
  }

  /// Enregistre le nom (obligatoire) et le téléphone (facultatif, E.164) sur
  /// le profil de l'utilisateur connecté. Le rôle et les champs de
  /// vérification ne sont jamais envoyés : le serveur les refuse de toute
  /// façon (C211).
  Future<bool> completeProfile({
    required String fullName,
    String? phone,
  }) async {
    final userId = _userId;
    final name = fullName.trim();
    if (userId == null || name.isEmpty) {
      _error = 'Le nom est obligatoire';
      notifyListeners();
      return false;
    }
    String? normalizedPhone;
    if (phone != null && phone.trim().isNotEmpty) {
      normalizedPhone = Validators.normalizeE164(phone);
      if (normalizedPhone == null) {
        _error = 'Numéro de téléphone invalide';
        notifyListeners();
        return false;
      }
    }
    _setLoading(true);
    try {
      await _profileService.updateOwnProfile(
        id: userId,
        fullName: name,
        phone: normalizedPhone,
      );
      _fullName = name;
      _profileLoaded = true;
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = userMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // === DÉCONNEXION ===

  Future<void> logout() async {
    await SupabaseService().signOut();
    _userId = null;
    _userEmail = null;
    _userPhone = null;
    _userRole = null;
    _gsgId = null;
    _gsgOrgId = null;
    _pharmacyId = null;
    _isGsgAdmin = false;
    _accountStatus = null;
    _fullName = null;
    _profileLoaded = false;
    _profileCompletionSkipped = false;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  void setRole(UserRole role) {
    _userRole = role;
    notifyListeners();
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
