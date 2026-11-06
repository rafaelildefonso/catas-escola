import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../services/token_holder.dart';

class BillingRepository {
  Future<String> createCheckout(String planTier) {
    return _createSession('checkout', {'plan_tier': planTier});
  }

  Future<String> createPortal() {
    return _createSession('portal', const {});
  }

  Future<Map<String, dynamic>> confirmCheckout(String sessionId) async {
    final token = TokenHolder().token;
    if (token == null) throw Exception('Usuário não autenticado.');
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/billing/checkout-session/${Uri.encodeComponent(sessionId)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      final detail = data is Map<String, dynamic> && data['detail'] is String
          ? data['detail'] as String
          : 'Não foi possível confirmar o pagamento.';
      throw BillingConfirmationException(detail, response.statusCode);
    }
    if (data is Map<String, dynamic>) return data;
    throw Exception('Resposta inválida do serviço de cobrança.');
  }

  Future<String> _createSession(String path, Map<String, dynamic> body) async {
    final token = TokenHolder().token;
    if (token == null) throw Exception('Usuário não autenticado.');
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data['detail'] is String) {
          throw Exception(data['detail'] as String);
        }
      } on FormatException {
        // Keep the status visible when the API does not return JSON.
      }
      throw Exception(
        'Não foi possível iniciar o pagamento (${response.statusCode}).',
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic> && data['url'] is String) {
      return data['url'] as String;
    }
    throw Exception('Resposta inválida do serviço de cobrança.');
  }
}

class BillingConfirmationException implements Exception {
  final String message;
  final int statusCode;

  BillingConfirmationException(this.message, this.statusCode);

  @override
  String toString() => message;
}
