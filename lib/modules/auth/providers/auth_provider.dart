import 'package:flutter/material.dart';
import '../../../core/kernel/gsg_kernel_auth_bridge.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
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
  String? get error => _error;

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
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyPhoneOtp(phone, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userPhone = user.phone;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String email, String token) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyEmailOtp(email, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userEmail = user.email;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
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

  // === DÉCONNEXION ===

  Future<void> logout() async {
    await SupabaseService().signOut();
    _userId = null;
    _userEmail = null;
    _userPhone = null;
    _userRole = null;
    _gsgId = null;
    _gsgOrgId = null;
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
