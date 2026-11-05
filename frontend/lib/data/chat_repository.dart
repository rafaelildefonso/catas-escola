import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/app_config.dart';
import 'chat_repository_interface.dart';

class ChatRepository implements IChatRepository {
  ChatRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  String get _baseUrl => AppConfig.apiBaseUrl;

  @override
  Future<List<Map<String, dynamic>>> getSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '$_baseUrl/chat/sessions',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Resposta inválida ao carregar conversas.',
      );
    }
    return (data['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createSession({String? title}) async {
    final response = await _apiClient.post(
      '$_baseUrl/chat/sessions',
      data: {'title': title},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    throw const ApiException(message: 'Resposta inválida ao criar conversa.');
  }

  @override
  Future<void> renameSession(String sessionId, String title) async {
    await _apiClient.patch(
      '$_baseUrl/chat/sessions/$sessionId/title',
      data: {'title': title},
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _apiClient.delete('$_baseUrl/chat/sessions/$sessionId');
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(
    String sessionId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '$_baseUrl/chat/history/$sessionId',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Resposta inválida ao carregar histórico.',
      );
    }
    return (data['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String? sessionId,
    String text, {
    String? model,
    String? currentPageUrl,
    String? currentPageTitle,
    bool webSearch = false,
    List<String>? activeIntegrations,
    List<String>? attachmentUrls,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'message': text,
      'conversation_id': sessionId,
      'model': model ?? 'CATAS Basic',
      'web_search': webSearch,
      'active_integrations': activeIntegrations ?? [],
      if (currentPageUrl != null) 'current_page_url': currentPageUrl,
      if (currentPageTitle != null) 'current_page_title': currentPageTitle,
      if (attachmentUrls != null && attachmentUrls.isNotEmpty)
        'attachment_urls': attachmentUrls,
    };
    final response = await _apiClient.post(
      '$_baseUrl/chat/message',
      data: payload,
      cancelToken: cancelToken,
    );
    return _responseMap(response.data, 'enviar a mensagem');
  }

  @override
  Future<void> sendFeedback({
    required String messageId,
    required String sessionId,
    required bool? isLiked,
    String? reason,
  }) async {
    await _apiClient.post(
      '$_baseUrl/chat/messages/$messageId/feedback',
      data: {'session_id': sessionId, 'is_liked': isLiked, 'reason': reason},
    );
  }

  @override
  Future<Map<String, dynamic>> continueMessage({
    required String sessionId,
    required String continuationId,
    required String componentType,
    required Map<String, dynamic> responseData,
    String? model,
    CancelToken? cancelToken,
  }) async {
    final response = await _apiClient.post(
      '$_baseUrl/chat/message/continue',
      data: {
        'session_id': sessionId,
        'continuation_id': continuationId,
        'component_type': componentType,
        'response_data': responseData,
        'model': model ?? 'CATAS Basic',
      },
      cancelToken: cancelToken,
    );
    return _responseMap(response.data, 'continuar a mensagem');
  }

  Map<String, dynamic> _responseMap(Object? data, String action) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException(message: 'Resposta inválida ao $action.');
  }
}
