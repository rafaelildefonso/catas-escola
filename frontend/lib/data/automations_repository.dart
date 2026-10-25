import 'dart:convert';
import '../core/app_config.dart';
import '../services/token_holder.dart';
import 'package:http/http.dart' as http;

class AutomationsRepository {
  Future<Map<String, String>> _headers() async {
    final token = TokenHolder().token ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<List<Map<String, dynamic>>> fetchAutomations({String? status}) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/automations',
    ).replace(queryParameters: status == null ? null : {'status': status});
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar automações');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
  }

  Future<Map<String, dynamic>> saveAutomation(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/automations${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http.post(
            uri,
            headers: await _headers(),
            body: jsonEncode(data),
          )
        : await http.put(
            uri,
            headers: await _headers(),
            body: jsonEncode(data),
          );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail'];
      throw Exception(detail ?? 'Falha ao salvar automação');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> runAutomation(String id) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/automations/$id/run'),
      headers: await _headers(),
    );
    if (response.statusCode != 202) {
      throw Exception('Falha ao executar automação');
    }
  }

  Future<Map<String, dynamic>> reviseAutomation(
    String id,
    String request,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/automations/$id/revise'),
      headers: await _headers(),
      body: jsonEncode({'request': request}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['detail'] ?? 'Não foi possível alterar a automação');
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> fetchAutomationRuns({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/automation-runs?limit=$limit&offset=$offset',
      ),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('data')) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    }
    throw Exception("Erro ao buscar execuções: ${response.statusCode}");
  }

  Future<List<Map<String, dynamic>>> fetchStepLogs(String runId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/automation-step-logs?run_id=$runId'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('data')) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    }
    throw Exception("Erro ao buscar logs: ${response.statusCode}");
  }

  Future<void> updateAutomationStatus(
    String automationId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/automations/$automationId'),
      headers: await _headers(),
      body: jsonEncode({"status": status}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar automação: ${response.statusCode}");
    }
  }

  Future<void> deleteAutomation(String automationId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/automations/$automationId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Erro ao deletar automação: ${response.statusCode}");
    }
  }

  Future<void> deleteRun(String runId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/automation-runs/$runId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Erro ao deletar execução: ${response.statusCode}");
    }
  }
}
