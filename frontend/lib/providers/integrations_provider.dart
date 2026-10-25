import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
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
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        _connectedProviders = data
            .where((e) => e['is_connected'] == true)
            .map((e) => e['provider'] as String)
            .toList();
        if (!silent) _lastError = null;
      } else if (!silent) {
        _lastError = "Erro ao buscar integrações";
      }
    } catch (e) {
      if (!silent) {
        _lastError = "Verifique sua conexão com a internet e tente novamente.";
      }
    } finally {
      _hasAttemptedFetch = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleConnection(String provider) async {
    if (isConnected(provider)) {
      return await disconnectProvider(provider);
    } else {
      return await connectProvider(provider);
    }
  }

  Future<bool> connectProvider(String provider) async {
    _busyProviders.add(provider);
    _lastError = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        "${_getBaseUrl()}/integrations/google/auth-url?provider=$provider",
      );
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final authUrl = data['auth_url'] as String?;
        if (authUrl != null) {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
        _lastError = "Erro ao gerar link de autenticacao";
        return false;
      } else {
        _lastError = "Erro ao conectar com o servidor";
        return false;
      }
    } catch (e) {
      _lastError = "Erro de conexao";
      return false;
    } finally {
      _busyProviders.remove(provider);
      notifyListeners();
    }
  }

  Future<bool> disconnectProvider(String provider) async {
    _busyProviders.add(provider);
    _lastError = null;
    notifyListeners();

    try {
      final url = Uri.parse("${_getBaseUrl()}/integrations/provider/$provider");
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200 || response.statusCode == 204) {
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
