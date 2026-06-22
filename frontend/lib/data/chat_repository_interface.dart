import 'package:dio/dio.dart';

abstract class IChatRepository {
  Future<List<Map<String, dynamic>>> getSessions({
    int limit = 50,
    int offset = 0,
  });
  Future<Map<String, dynamic>> createSession({String? title});
  Future<void> renameSession(String sessionId, String title);
  Future<void> deleteSession(String sessionId);
  Future<List<Map<String, dynamic>>> getHistory(
    String sessionId, {
    int limit = 100,
    int offset = 0,
  });
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
  });

  /// Cancela uma automação em execução no backend
  Future<void> cancelAutomation(String automationId);

  /// Envia like/dislike para uma mensagem do assistente.
  /// [isLiked] null = remove o feedback (toggle off).
  /// [reason] motivo do feedback (opcional).
  Future<void> sendFeedback({
    required String messageId,
    required String sessionId,
    required bool? isLiked,
    String? reason,
  });

  /// Continua uma mensagem existente baseada na resposta de um componente.
  Future<Map<String, dynamic>> continueMessage({
    required String sessionId,
    required String continuationId,
    required String componentType,
    required Map<String, dynamic> responseData,
    String? model,
    CancelToken? cancelToken,
  });
}
