import 'package:dio/dio.dart';
import '../core/app_config.dart';
import '../services/token_holder.dart';
import 'chat_repository_interface.dart';

class ChatRepository implements IChatRepository {
  final Dio _dio = Dio();

  String _getBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  Options _getOptions() {
    final token = TokenHolder().token ?? "dev-token";

    return Options(
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/sessions";

    try {
      final response = await _dio.get(
        url,
        queryParameters: {"limit": limit, "offset": offset},
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        final data = (response.data['data'] as List<dynamic>? ?? const []);
        return data.cast<Map<String, dynamic>>();
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  @override
  Future<Map<String, dynamic>> createSession({String? title}) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/sessions";
    final payload = {"title": title};

    try {
      final response = await _dio.post(
        url,
        options: _getOptions(),
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw Exception("Resposta inválida ao criar sessão");
        }
        return data;
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  @override
  Future<void> renameSession(String sessionId, String title) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/sessions/$sessionId/title";

    try {
      final response = await _dio.patch(
        url,
        options: _getOptions(),
        data: {"title": title},
      );

      if (response.statusCode == 200) {
        return;
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/sessions/$sessionId";

    try {
      final response = await _dio.delete(url, options: _getOptions());

      if (response.statusCode == 200) {
        return;
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(
    String sessionId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/history/$sessionId";

    try {
      final response = await _dio.get(
        url,
        queryParameters: {"limit": limit, "offset": offset},
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        final data = (response.data['data'] as List<dynamic>? ?? const []);
        return data.cast<Map<String, dynamic>>();
      }

      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
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
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/message";

    final payload = <String, dynamic>{
      "message": text,
      "conversation_id": sessionId,
      "model": model ?? "CATAS Free",
      "web_search": webSearch,
      "active_integrations": activeIntegrations ?? [],
    };

    if (currentPageUrl != null) {
      payload["current_page_url"] = currentPageUrl;
    }
    if (currentPageTitle != null) {
      payload["current_page_title"] = currentPageTitle;
    }
    if (attachmentUrls != null && attachmentUrls.isNotEmpty) {
      payload["attachment_urls"] = attachmentUrls;
    }

    try {
      final response = await _dio.post(
        url,
        options: _getOptions(),
        data: payload,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception("HttpError: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        throw Exception("cancelled");
      }
      throw Exception("Erro de conexão: $e");
    }
  }

  @override
  Future<void> sendFeedback({
    required String messageId,
    required String sessionId,
    required bool? isLiked,
    String? reason,
  }) async {
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/messages/$messageId/feedback";

    try {
      final response = await _dio.post(
        url,
        options: _getOptions(),
        data: {
          "session_id": sessionId,
          "is_liked": isLiked,
          "reason": reason,
        },
      );

      if (response.statusCode == 200) return;
      throw Exception("HttpError: ${response.statusCode}");
    } catch (e) {
      throw Exception("Erro ao enviar feedback: $e");
    }
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
    final baseUrl = _getBaseUrl();
    final url = "$baseUrl/chat/message/continue";

    final payload = {
      "session_id": sessionId,
      "continuation_id": continuationId,
      "component_type": componentType,
      "response_data": responseData,
      "model": model ?? "CATAS Basic",
    };

    try {
      final response = await _dio.post(
        url,
        options: _getOptions(),
        data: payload,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception("HttpError: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        throw Exception("cancelled");
      }
      throw Exception("Erro de conexão: $e");
    }
  }
}
