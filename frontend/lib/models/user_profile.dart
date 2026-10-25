class UserProfile {
  final String id;
  final String email;
  final String subscriptionTier;
  final int quotaUsed;
  final int monthlyQuotaLimit;
  final int quotaRemaining;
  final int attachmentLimit;
  final bool hasBillingAccount;
  final bool hasBillingSubscription;
  final String? language;

  final String? industry;
  final String? role;
  final bool onboardingCompleted;

  UserProfile({
    required this.id,
    required this.email,
    required this.subscriptionTier,
    required this.quotaUsed,
    required this.monthlyQuotaLimit,
    required this.quotaRemaining,
    required this.attachmentLimit,
    this.hasBillingAccount = false,
    this.hasBillingSubscription = false,
    this.language,
    this.industry,
    this.role,
    this.onboardingCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'subscription_tier': subscriptionTier,
      'quota_used': quotaUsed,
      'monthly_quota_limit': monthlyQuotaLimit,
      'attachment_limit': attachmentLimit,
      'has_billing_account': hasBillingAccount,
      'has_billing_subscription': hasBillingSubscription,
      'language': language,
      'industry': industry,
      'role': role,
      'onboarding_completed': onboardingCompleted,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final tier = (json['subscription_tier'] as String?) ?? 'free';
    final used = (json['quota_used'] as int?) ?? 0;

    // Mapping client-side defaults but prioritizing backend value if present
    int defaultLimit = 500;
    int defaultAttachLimit = 5;
    if (tier == 'pro') {
      defaultLimit = 7500;
      defaultAttachLimit = 100;
    }
    if (tier == 'max') {
      defaultLimit = 25000;
      defaultAttachLimit = 1000;
    }

    // Cap by tier maximum to prevent backend errors from showing inflated values
    final tierMax = switch (tier) {
      'max' => 25000,
      'pro' => 7500,
      _ => 500,
    };
    final limit = ((json['monthly_quota_limit'] as int?) ?? defaultLimit).clamp(
      0,
      tierMax,
    );
    final safeUsed = used.clamp(0, limit);

    return UserProfile(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      subscriptionTier: tier,
      quotaUsed: safeUsed,
      monthlyQuotaLimit: limit,
      quotaRemaining: limit - safeUsed,
      attachmentLimit:
          ((json['attachment_limit'] as int?) ?? defaultAttachLimit).clamp(
            0,
            defaultAttachLimit,
          ),
      hasBillingAccount: (json['has_billing_account'] as bool?) ?? false,
      hasBillingSubscription:
          (json['has_billing_subscription'] as bool?) ?? false,
      language: json['language'] as String?,
      industry: json['industry'] as String?,
      role: json['role'] as String?,
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? false,
    );
  }
}
