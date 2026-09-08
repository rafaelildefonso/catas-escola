import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:catas/models/user_model.dart';
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';
import 'package:http/http.dart' as http;
import '../services/token_holder.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final LocaleProvider? _localeProvider;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  UserModel? _currentUser;
  UserProfile? _profile;
  bool _isLoading = true;
  final bool _isDemoMode;

  bool _isInitializing = true;
  bool _onboardingPrefsLoaded = false;
  bool _onboardingCompleted = false;

  bool get onboardingPrefsLoaded => _onboardingPrefsLoaded;
  bool get onboardingCompleted => _onboardingCompleted;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  UserProfile? get profile => _profile;
  String? get userId => _currentUser?.id;
  String? get userName =>
      _currentUser?.displayName ?? (_currentUser?.email.split('@')[0] ?? 'Usuário');
  String? get userEmail => _currentUser?.email;
  String? get userPhotoUrl => _currentUser?.photoUrl;
  String? get userFirstName =>
      _currentUser?.displayName?.split(' ')[0] ??
      (_currentUser?.email.split('@')[0] ?? 'Usuário');

  int? get monthlyQuotaLimit => _profile?.monthlyQuotaLimit;
  int? get quotaUsed => _profile?.quotaUsed;
  int? get quotaRemaining => _profile?.quotaRemaining;
  String? get subscriptionTier => _profile?.subscriptionTier;

  String? get _token {
    return _tokenCache;
  }

  String? _tokenCache;

  AuthProvider({LocaleProvider? localeProvider})
      : _localeProvider = localeProvider,
        _isDemoMode = AppConfig.isDemoMode {
    _initAuth();
  }

  Future<void> _initAuth() async {
    if (_isDemoMode) {
      _currentUser = UserModel(
        id: 'demo-user-id',
        email: 'demo@catas.ai',
        displayName: 'Usuário Demo',
        photoUrl: null,
      );
      _profile = UserProfile(
        id: 'demo-user-id',
        email: 'demo@catas.ai',
        subscriptionTier: 'pro',
        quotaUsed: 0,
        monthlyQuotaLimit: 100,
        quotaRemaining: 100,
        attachmentLimit: 50,
        language: 'pt',
        industry: 'other',
        onboardingCompleted: true,
      );
      _isAuthenticated = true;
      _onboardingCompleted = true;
      _onboardingPrefsLoaded = true;
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    await refreshOnboardingState();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile_cache');
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(profileMap);
        _onboardingCompleted = _profile!.onboardingCompleted;
        _onboardingPrefsLoaded = true;
        notifyListeners();
        debugPrint("📦 Perfil carregado do cache local.");
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao carregar cache de perfil: $e");
    }

    _tokenCache = await _secureStorage.read(key: 'jwt_token');
    if (_tokenCache != null) {
      TokenHolder().token = _tokenCache!;
      await _loadUserFromToken(_tokenCache!);
    }

    _isInitializing = false;

    await _checkServerAndAuth();
  }

  Future<void> _checkServerAndAuth() async {
    if (_tokenCache == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    await _loadUserFromToken(_tokenCache!);
  }

  Future<void> _loadUserFromToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
        _onboardingCompleted = _profile!.onboardingCompleted;
        _onboardingPrefsLoaded = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_profile_cache', jsonEncode(_profile!.toMap()));
        await prefs.setBool('onboarding_completed', _onboardingCompleted);

        _isAuthenticated = true;
        _isLoading = false;
        TokenHolder().token = token;
        notifyListeners();
        debugPrint("🚀 Usuário carregado com sucesso via token.");
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao carregar usuário: $e");
      await logout();
    }
  }

  void updateQuota(int used, int? limit) {
    if (_profile == null) return;

    int finalLimit = limit ?? _profile!.monthlyQuotaLimit;

    _profile = UserProfile(
      id: _profile!.id,
      email: _profile!.email,
      subscriptionTier: _profile!.subscriptionTier,
      quotaUsed: used,
      monthlyQuotaLimit: finalLimit,
      quotaRemaining: (finalLimit - used).clamp(0, finalLimit),
      attachmentLimit: _profile!.attachmentLimit,
      language: _profile!.language,
      industry: _profile!.industry,
      role: _profile!.role,
      onboardingCompleted: _profile!.onboardingCompleted,
    );

    notifyListeners();
    debugPrint("📊 [AuthProvider] Cota atualizada manualmente: $used/$finalLimit");
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _profile = null;
    _tokenCache = null;
    TokenHolder().token = null;
    await _secureStorage.delete(key: 'jwt_token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_cache');

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password) async {
    if (_isDemoMode) return true;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveSession(data['token'] as String, data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Email Sign-In Error: ${error['detail']}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Email Sign-In Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    if (_isDemoMode) return true;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveSession(data['token'] as String, data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Email Sign-Up Error: ${error['detail']}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Email Sign-Up Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession(String token, Map<String, dynamic> data) async {
    _tokenCache = token;
    TokenHolder().token = token;
    await _secureStorage.write(key: 'jwt_token', value: token);

    _isAuthenticated = true;
    _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
    _onboardingCompleted = _profile!.onboardingCompleted;
    _onboardingPrefsLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_profile_cache', jsonEncode(_profile!.toMap()));
    await prefs.setBool('onboarding_completed', _onboardingCompleted);
  }

  Future<void> refreshProfile() async {
    if (!_isAuthenticated || _isDemoMode || _tokenCache == null) return;

    try {
      final response = await _userRepository.getMe(_tokenCache!);
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        _profile = UserProfile.fromJson(data);
        _onboardingCompleted = _profile!.onboardingCompleted;
        _onboardingPrefsLoaded = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_profile_cache', jsonEncode(_profile!.toMap()));
        await prefs.setBool('onboarding_completed', _onboardingCompleted);

        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao atualizar perfil: $e");
    }
  }

  Future<void> refreshOnboardingState() async {
    if (_profile != null) {
      _onboardingCompleted = _profile!.onboardingCompleted;
      _onboardingPrefsLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      _onboardingPrefsLoaded = true;
      notifyListeners();
    } catch (_) {
      _onboardingPrefsLoaded = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding({
    String? industry,
    String? role,
    List<String>? tools,
    bool scheduleAhaDemo = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (scheduleAhaDemo) {
      await prefs.setBool('onboarding_aha_pending', true);
    }

    _onboardingCompleted = true;

    if (_isAuthenticated && !_isDemoMode && _tokenCache != null) {
      try {
        debugPrint('🔄 Atualizando perfil no backend: industry=$industry, role=$role, tools=$tools');
        await _userRepository.updateMe(_tokenCache!, {
          'industry': industry,
          'role': role,
          'onboarding_completed': true,
          'onboarding_data': {
            'tools': tools ?? [],
          },
        });
        debugPrint('✅ Perfil atualizado no backend. Recarregando perfil...');
        await refreshProfile();
        debugPrint('✅ Perfil recarregado: industry=${_profile?.industry}');
      } catch (e) {
        debugPrint('⚠️ Erro ao salvar onboarding no backend: $e');
      }
    }

    notifyListeners();
    debugPrint('🔔 AuthProvider notificado: onboardingCompleted=$_onboardingCompleted, profile.industry=${_profile?.industry}');
  }

  Future<void> updateProfile({String? name}) async {
    if (!_isAuthenticated || _isDemoMode || _tokenCache == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['display_name'] = name;

      if (updates.isEmpty) return;

      final response = await _userRepository.updateMe(_tokenCache!, updates);
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        _profile = UserProfile.fromJson(data);
        _onboardingCompleted = _profile!.onboardingCompleted;
        _onboardingPrefsLoaded = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', _onboardingCompleted);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (!_isAuthenticated || _isDemoMode || _tokenCache == null) return;

    try {
      await _userRepository.deleteMe(_tokenCache!);
      await logout();
    } catch (e) {
      debugPrint('Erro ao remover conta: $e');
      rethrow;
    }
  }
}

class UserRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateMe(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profiles/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  Future<void> deleteMe(String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/profiles/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete profile: ${response.statusCode}');
    }
  }
}