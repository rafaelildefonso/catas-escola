import 'dart:convert';

import '../core/app_config.dart';
import 'package:http/http.dart' as http;
import '../services/token_holder.dart';

/// Repositório REST dos Termos de Uso e Consentimento (LGPD).
/// Endpoints: GET/POST /api/v1/termos/aceite
class TermoAceiteRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;

  Map<String, String> _headers() {
    final token = TokenHolder().token ?? "dev-token";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Consulta o aceite atual do usuário autenticado.
  Future<Map<String, dynamic>> consultar() async {
    final uri = Uri.parse("$_baseUrl/termos/aceite");
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception("Erro ao consultar aceite dos termos: ${response.statusCode}");
  }

  /// Registra o aceite dos termos informados (padrão: uso + consentimento).
  Future<Map<String, dynamic>> registrar({List<String>? tipos}) async {
    final uri = Uri.parse("$_baseUrl/termos/aceite");
    final response = await http.post(uri, headers: _headers(), body: jsonEncode({
      if (tipos != null) "tipos": tipos,
    }));
    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception("Erro ao registrar aceite dos termos: ${response.statusCode}");
  }
}
