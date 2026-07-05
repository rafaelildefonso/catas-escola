import 'dart:convert';
import '../core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudApiService {
  final String resourcePath;

  CrudApiService(this.resourcePath);

  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? "dev-token";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<List<Map<String, dynamic>>> listar({Map<String, String>? params}) async {
    final uri = Uri.parse("$_baseUrl/$resourcePath").replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('data')) return List<Map<String, dynamic>>.from(body['data']);
      return [];
    }
    throw Exception("Erro ao listar: ${response.statusCode}");
  }

  Future<Map<String, dynamic>> buscarPorId(String id) async {
    final uri = Uri.parse("$_baseUrl/$resourcePath/$id");
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception("Erro ao buscar: ${response.statusCode}");
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> dados) async {
    final uri = Uri.parse("$_baseUrl/$resourcePath");
    final response = await http.post(uri, headers: _headers(), body: jsonEncode(dados));
    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception("Erro ao criar: ${response.statusCode} ${response.body}");
  }

  Future<Map<String, dynamic>> atualizar(String id, Map<String, dynamic> dados) async {
    final uri = Uri.parse("$_baseUrl/$resourcePath/$id");
    final response = await http.put(uri, headers: _headers(), body: jsonEncode(dados));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception("Erro ao atualizar: ${response.statusCode}");
  }

  Future<void> deletar(String id) async {
    final uri = Uri.parse("$_baseUrl/$resourcePath/$id");
    final response = await http.delete(uri, headers: _headers());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Erro ao deletar: ${response.statusCode}");
    }
  }
}
