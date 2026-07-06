import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../core/app_config.dart';
import '../services/token_holder.dart';

class IntegrationsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasAttemptedFetch = false;
  List<String> _connectedProviders = [];
  final Set<String> _busyProviders = {};
  String? _lastError;

  bool get isLoading => _isLoading;
  bool get hasAttemptedFetch => _hasAttemptedFetch;
  List<String> get connectedProviders => _connectedProviders;
  String? get lastError => _lastError;
  bool isBusy(String provider) => _busyProviders.contains(provider);

  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  IntegrationsProvider();

  bool isConnected(String provider) {
    return _connectedProviders.contains(provider);
  }

  String _getBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  Map<String, String> _getHeaders() {
    if (AppConfig.isDemoMode) {
      return {"Content-Type": "application/json", "Authorization": "Bearer demo-token"};
    }
    final token = TokenHolder().token ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<void> fetchIntegrations({
    bool force = false,
    bool silent = false,
  }) async {
    if (_isLoading && !force) return;

    if (!silent) {
      _isLoading = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      final url = Uri.parse("${_getBaseUrl()}/integrations");
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes))['data'] as List;
        _connectedProviders = data.map((e) => e['provider'] as String).toList();
        _hasAttemptedFetch = true;
        if (!silent) _lastError = null;
      } else if (!silent) {
        _lastError = "Erro ao buscar integrações";
      }
    } catch (e) {
      if (!silent) {
        _lastError = "Verifique sua conexão com a internet e tente novamente.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleConnection(String provider) async {
    if (isConnected(provider)) {
      return await disconnectProvider(provider);
    } else {
      if (provider.startsWith('google_')) {
        return await connectGoogleWorkspace(provider);
      } else {
        _lastError = "Provedor $provider não configurado no client.";
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> connectGoogleWorkspace(String provider) async {
    _busyProviders.add(provider);
    _lastError = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        "${_getBaseUrl()}/integrations/google/auth-url?provider=$provider",
      );
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode != 200) {
        _lastError = "Erro ao obter URL de autenticação.";
        return false;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final authUrl = data['auth_url'] as String?;

      if (authUrl == null || authUrl.isEmpty) {
        _lastError = "URL de autenticação inválida.";
        return false;
      }

      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _lastError = "Não foi possível abrir o navegador.";
        return false;
      }

      // Poll em background — quando o OAuth server-side concluir, a UI será atualizada
      _pollForProvider(provider);
      return true;
    } catch (e) {
      _lastError = "Erro ao conectar. Verifique sua conexão e tente novamente.";
      return false;
    } finally {
      _busyProviders.remove(provider);
      notifyListeners();
    }
  }

  void _pollForProvider(String provider) async {
    int attempts = 0;
    while (attempts < 20) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        await fetchIntegrations(force: true, silent: true);
      } catch (_) {
        // Ignore network errors during polling — user will see the result
        // when they come back to the app after authentication.
      }
      if (_connectedProviders.contains(provider)) break;
      attempts++;
    }
  }

  Future<bool> disconnectProvider(String provider) async {
    _busyProviders.add(provider);
    _lastError = null;
    notifyListeners();

    try {
      final url = Uri.parse("${_getBaseUrl()}/integrations/$provider");
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
          await fetchIntegrations(force: true, silent: true);
        return true;
      } else {
        _lastError = "Erro ao desconectar";
        return false;
      }
    } catch (e) {
      _lastError = "Erro de conexão";
      return false;
    } finally {
      _busyProviders.remove(provider);
      notifyListeners();
    }
  }
}
