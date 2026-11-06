import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../services/token_holder.dart';

class GeneratedReportsRepository {
  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${TokenHolder().token ?? ''}',
  };

  Future<List<Map<String, dynamic>>> listar() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/relatorios/gerados'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar os relatórios.');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! List) {
      throw Exception('Resposta inesperada ao carregar relatórios.');
    }
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<http.Response> baixar(String reportId) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/relatorios/gerados/$reportId/download',
      ),
      headers: await _headers(),
    );
    if (response.statusCode == 200) return response;
    throw Exception('Não foi possível baixar este relatório.');
  }
}
