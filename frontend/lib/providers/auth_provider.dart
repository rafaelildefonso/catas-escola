import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:catas/models/user_model.dart';
import '../data/user_repository.dart';
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';

class AuthProvider extends ChangeNotifier {
  late final SupabaseClient _supabase;
  final UserRepository _userRepository = UserRepository();
  final LocaleProvider? _localeProvider;
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  UserProfile? _profile;
  bool _isLoading = true;
  final bool _isDemoMode;
  
  String get _redirectUrl => kIsWeb 
      ? Uri.base.origin 
      : 'io.supabase.flutter://callback';

  // Flag que indica se o app acabou de inicializar (primeiros segundos).
  // Usada para evitar logout forçado por 401 transiente durante restauração
  // do token Supabase no startup.
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

  AuthProvider({LocaleProvider? localeProvider}) : _localeProvider = localeProvider, _isDemoMode = AppConfig.isDemoMode {
    if (!_isDemoMode) {
      _supabase = Supabase.instance.client;
    }
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

    // 0. Carregar perfil do cache local (Quota Cache - Step 03)
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

    // Verifica se já existe uma sessão ativa ANTES de registrar o listener.
    final existingSession = _supabase.auth.currentSession;
    if (existingSession != null) {
      _isAuthenticated = true;
      _currentUser = UserModel.fromSupabase(existingSession.user);
      _isLoading = false;
      notifyListeners();
      debugPrint("🚀 Sessão Supabase existente encontrada no startup.");
    } else {
      debugPrint("🔍 Nenhuma sessão imediata. Aguardando listener de auth...");
      // No Web, damos um pequeno fôlego para o Supabase recuperar a sessão dos cookies
      // antes de liberar o router, evitando redirecionamento precoce para o Login.
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_supabase.auth.currentSession != null) {
           _isLoading = false;
           notifyListeners();
           return;
        }
      }
    }

    // Escutar mudanças futuras no estado de autenticação
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _isAuthenticated = session != null;
      _currentUser = session?.user != null
          ? UserModel.fromSupabase(session!.user)
          : null;
      
      if (!_isAuthenticated) {
        _profile = null;
        _clearProfileCache();
      }
      
      _isLoading = false;
      notifyListeners();

      if (_isAuthenticated) {
        refreshProfile();
      }
    });

    // Após a janela de inicialização (3s), qualquer 401 subsequente
    // já pode ser tratado como sessão genuinamente inválida.
    await Future.delayed(const Duration(seconds: 3));
    _isInitializing = false;

    // Setup realtime listener para atualizações de perfil (créditos)
    _setupProfileRealtimeListener();
  }

  void _setupProfileRealtimeListener() {
    if (_isDemoMode) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('profile_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 Perfil atualizado via realtime - recarregando...');
            refreshProfile();
          },
        )
        .subscribe();
  }

  /// Atualiza a cota localmente e notifica ouvintes (Quota Sync - Step 02)
  void updateQuota(int used, int? limit) {
    if (_profile == null) return;
    
    // Mapping local limit if not provided (keeping consistency with UserProfile.fromJson)
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

  Future<void> _clearProfileCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_cache');
    } catch (_) {}
  }

  Future<void> refreshProfile({int retries = 3}) async {
    if (!_isAuthenticated || _isDemoMode) return;

    final session = _supabase.auth.currentSession;
    if (session == null) return;

    for (int i = 0; i < retries; i++) {
      try {
        final response = await _userRepository.getMe();
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          _profile = UserProfile.fromJson(data);
          _onboardingCompleted = _profile!.onboardingCompleted;
          _onboardingPrefsLoaded = true;
          
          // Load language from database
          final languageCode = _profile?.language;
          if (languageCode != null && languageCode.isNotEmpty) {
            try {
              await _localeProvider?.loadLocaleFromDatabase(languageCode);
            } catch (e) {
              debugPrint("⚠️ Erro ao carregar idioma do banco: $e");
            }
          }
          
          // Salvar no cache local (Quota Cache - Step 03)
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_profile_cache', jsonEncode(_profile!.toMap()));
            await prefs.setBool('onboarding_completed', _onboardingCompleted);
          } catch (e) {
            debugPrint("⚠️ Erro ao salvar cache de perfil ou onboarding prefs: $e");
          }

          notifyListeners();
          return;
        }
      } catch (e) {
        final errorStr = e.toString();
        debugPrint(
          "Error fetching profile: $errorStr. Retries left: ${retries - i - 1}",
        );

        // Se o erro for 401 ou 403, verifica se ainda estamos no período de
        // inicialização. Um 401 durante o startup é quase sempre transitório
        // (token ainda sendo restaurado pelo Supabase) e NÃO deve causar logout.
        if (errorStr.contains("401") || errorStr.contains("403")) {
          if (_isInitializing) {
            // Durante a inicialização: aguarda e tenta novamente (não faz logout).
            debugPrint(
              "Auth 401 during initialization window — retrying, NOT logging out.",
            );
            if (i < retries - 1) {
              await Future.delayed(const Duration(seconds: 2));
            }
            continue;
          } else {
            // Fora da janela de inicialização: sessão genuinamente inválida.
            debugPrint("Auth failure detected (401/403). Forcing logout.");
            await logout();
            return;
          }
        }

        if (i < retries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
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

    if (_isAuthenticated && !_isDemoMode) {
      try {
        debugPrint('🔄 Atualizando perfil no backend: industry=$industry, role=$role, tools=$tools');
        await _userRepository.updateMe({
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

    // Notifica ouvintes (incluindo GoRouter) APÓS tudo estar atualizado
    notifyListeners();
    debugPrint('🔔 AuthProvider notificado: onboardingCompleted=$_onboardingCompleted, profile.industry=${_profile?.industry}');
  }

  Future<bool> signInWithMagicLink(String email) async {
    if (_isDemoMode) return true;
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: _redirectUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Magic link error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    if (_isDemoMode) return true;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
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

  Future<void> logout() async {
    if (_isDemoMode) {
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
      return;
    }
    await _supabase.auth.signOut();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name}) async {
    if (!_isAuthenticated || _isDemoMode) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['display_name'] = name;

      if (updates.isEmpty) return;

      final response = await _userRepository.updateMe(updates);
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        _profile = UserProfile.fromJson(data);
        _onboardingCompleted = _profile!.onboardingCompleted;
        _onboardingPrefsLoaded = true;
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_completed', _onboardingCompleted);
        } catch (_) {}

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (!_isAuthenticated || _isDemoMode) return;

    try {
      await _userRepository.deleteMe();
      await logout();
    } catch (e) {
      debugPrint('Erro ao remover conta: $e');
      rethrow;
    }
  }
}
