class ChatMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.metadata,
    required this.createdAt,
  });

  /// Retorna a lista bruta de componentes do metadata.
  /// O AIComponentFactory é responsável por parsear os diferentes formatos (type/data ou key-value).
  List<dynamic> get components {
    if (metadata.containsKey('components') && metadata['components'] is List) {
      return metadata['components'] as List;
    }
    return [];
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      content: (json['content'] as String?) ?? '',
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
