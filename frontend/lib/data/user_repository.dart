import 'dart:convert';

import '../core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  String _getBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  Map<String, String> _getHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? "dev-token";

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<Map<String, dynamic>> getMe() async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse("$baseUrl/user/me");

    try {
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception("AuthError: ${response.statusCode}");
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      if (e.toString().contains("AuthError")) rethrow;
      throw Exception("Erro de conexão: $e");
    }
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse("$baseUrl/user/me");

    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(),
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  Future<void> deleteMe() async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse("$baseUrl/user/me");

    try {
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode != 200) {
        throw Exception("HttpError: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }
}
