import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../services/token_holder.dart';

class NotificationsRepository {
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${TokenHolder().token ?? ''}',
    'Content-Type': 'application/json',
  };

  Future<List<Map<String, dynamic>>> list() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar notificações');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
  }

  Future<void> markRead(String id) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id/read'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar notificação');
    }
  }
}
