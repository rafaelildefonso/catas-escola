import 'dart:convert';

import '../core/app_config.dart';
import 'package:http/http.dart' as http;
import '../services/token_holder.dart';

class PaymentsService {
  String _getBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  Map<String, String> _getHeaders() {
    if (AppConfig.isDemoMode) {
      return {"Content-Type": "application/json", "Authorization": "Bearer demo-token"};
    }
    final token = TokenHolder().token ?? "dev-token";

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Cria uma sessão de checkout para o plano selecionado
  /// Retorna a URL do checkout da Stripe
  Future<String> createPlanCheckout(String plan) async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse("$baseUrl/payments/create-plan-checkout");

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({"plan": plan.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['url'] as String;
      }

      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? "Erro ao criar checkout");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  /// Cria uma sessão do Stripe Billing Portal para o usuário gerenciar assinaturas
  Future<String> createPortalSession() async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse("$baseUrl/payments/create-portal-session");

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['url'] as String;
      }

      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? "Erro ao criar portal de cobrança");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }
}
