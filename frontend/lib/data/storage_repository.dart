import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/picked_attachment.dart';
import '../services/token_holder.dart';
import '../core/app_config.dart';

class StorageRepository {
  Future<String> uploadAttachment(PickedAttachment attachment) async {
    final token = TokenHolder().token;
    if (token == null) throw Exception("Usuário não autenticado");

    final bytes =
        attachment.bytes ??
        (kIsWeb ? null : await File(attachment.path).readAsBytes());
    if (bytes == null) {
      throw Exception("Não foi possível ler o arquivo selecionado.");
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${AppConfig.apiBaseUrl}/attachments'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: attachment.name,
            ),
          );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic> && data['url'] is String) {
        return data['url'] as String;
      }
      throw Exception("Resposta inesperada ao enviar arquivo.");
    }
    throw Exception(_errorMessage(response));
  }

  Future<List<Map<String, dynamic>>> listAttachments() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attachments'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List)
      throw Exception("Resposta inesperada ao listar arquivos.");
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> deleteAttachment(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/attachments/$id'),
      headers: _headers(),
    );
    if (response.statusCode != 204) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<Map<String, dynamic>> previewDocx(String id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/attachments/$id/preview'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) return data;
    throw Exception("Resposta inesperada ao pré-visualizar documento.");
  }

  Map<String, String> _headers() {
    final token = TokenHolder().token;
    if (token == null) throw Exception("Usuário não autenticado");
    return {'Authorization': 'Bearer $token'};
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic> && data['detail'] is String) {
        return data['detail'] as String;
      }
    } on FormatException {
      // Keep the HTTP status visible when the server does not return JSON.
    }
    return "Falha na operação de arquivos (${response.statusCode}).";
  }
}
