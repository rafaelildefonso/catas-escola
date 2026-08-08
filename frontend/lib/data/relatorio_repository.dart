import 'dart:convert';

import '../core/app_config.dart';
import '../services/token_holder.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP para os endpoints de relatórios/busca (além do CRUD básico).
/// Rotas: /api/v1/relatorios/{dashboard,automacoes,chat,mensagens/busca}
class RelatorioRepository {
  Future<Map<String, String>> _headers() async {
    final token = TokenHolder().token ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<Map<String, dynamic>> estatisticasDashboard(
    String userId, {
    int dias = 7,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/relatorios/dashboard').replace(
      queryParameters: {'user_id': userId, 'dias': '$dias'},
    );
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 200) {
      return _decodeMap(resp);
    }
    throw Exception('Erro ao buscar estatísticas: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> relatorioAutomacoes({
    required String userId,
    String? status,
    String? busca,
    String? dataInicio,
    String? dataFim,
    String? ordem,
    int limite = 50,
    int deslocamento = 0,
  }) async {
    final params = <String, String>{
      'user_id': userId,
      'limite': '$limite',
      'deslocamento': '$deslocamento',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (busca != null && busca.isNotEmpty) params['busca'] = busca;
    if (dataInicio != null && dataInicio.isNotEmpty) params['data_inicio'] = dataInicio;
    if (dataFim != null && dataFim.isNotEmpty) params['data_fim'] = dataFim;
    if (ordem != null && ordem.isNotEmpty) params['ordem'] = ordem;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/relatorios/automacoes')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 200) {
      return _decodeMap(resp);
    }
    throw Exception('Erro ao gerar relatório de automações: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> relatorioChat(
    String userId, {
    int dias = 30,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/relatorios/chat')
        .replace(queryParameters: {'user_id': userId, 'dias': '$dias'});
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 200) {
      return _decodeMap(resp);
    }
    throw Exception('Erro ao gerar relatório de chat: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> buscarMensagens(
    String userId,
    String termo, {
    int limite = 50,
    int deslocamento = 0,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/relatorios/mensagens/busca')
        .replace(queryParameters: {
      'user_id': userId,
      'termo': termo,
      'limite': '$limite',
      'deslocamento': '$deslocamento',
    });
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode == 200) {
      return _decodeMap(resp);
    }
    throw Exception('Erro na busca de mensagens: ${resp.statusCode}');
  }

  Map<String, dynamic> _decodeMap(http.Response resp) {
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    if (body is Map<String, dynamic>) return body;
    throw Exception('Resposta inesperada da API');
  }
}