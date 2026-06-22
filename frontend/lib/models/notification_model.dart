/// Tipos de notificação suportados pelo sistema.
enum NotificationType {
  update,
  automation,
  integration,
  system,
  billing;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Status de uma automação (usado em metadata de notificações do tipo automation).
enum AutomationStatus {
  success,
  error,
  warning;

  static AutomationStatus fromString(String? value) {
    if (value == null) return AutomationStatus.success;
    return AutomationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AutomationStatus.success,
    );
  }
}

/// Modelo de notificação do app.
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionType; // 'app_route' | 'external_url'
  final String? actionData;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionType,
    this.actionData,
    this.metadata = const {},
    this.isRead = false,
    required this.createdAt,
  });

  /// Nome da automação (para tipo automation).
  String? get automationName => metadata['automation_name'] as String?;

  /// Status da automação (para tipo automation).
  AutomationStatus get automationStatus =>
      AutomationStatus.fromString(metadata['automation_status'] as String?);

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: NotificationType.fromString(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String,
      imageUrl: map['image_url'] as String?,
      actionType: map['action_type'] as String?,
      actionData: map['action_data'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
