class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnboarding;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isOnboarding = false,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // Handle is_onboarding as int (0/1) or bool from SQLite/PostgreSQL
    final dynamic onboardingRaw = json['is_onboarding'];
    final bool isOnboarding = onboardingRaw is bool
        ? onboardingRaw
        : (onboardingRaw is int ? onboardingRaw == 1 : false);

    // Use tryParse for date format safety
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now();

    return ChatSession(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Nova Conversa',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isOnboarding: isOnboarding,
    );
  }
}
