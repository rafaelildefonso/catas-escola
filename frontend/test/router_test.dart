import 'package:flutter_test/flutter_test.dart';

import 'package:catas/core/router.dart';

void main() {
  group('AppRoutes constants', () {
    test('are correctly defined', () {
      expect(AppRoutes.login, '/app/login');
      expect(AppRoutes.onboarding, '/app/onboarding');
      expect(AppRoutes.chat, '/app');
      expect(AppRoutes.chatWithSession, '/app/chat/:sessionId');
      expect(AppRoutes.notifications, '/app/notifications');
      expect(AppRoutes.pricing, '/app/pricing');
      expect(AppRoutes.settings, '/app/settings');
      expect(AppRoutes.history, '/app/history');
      expect(AppRoutes.dashboard, '/app/dashboard');
      expect(AppRoutes.integrations, '/app/integrations');
      expect(AppRoutes.automations, '/app/automations');
      expect(AppRoutes.suggestedPrompts, '/app/prompts');
      expect(AppRoutes.automationDetail, '/app/automations/:runId');
      expect(AppRoutes.paymentSuccess, '/app/payment-success');
    });

    test('chatSession builds correct path', () {
      expect(AppRoutes.chatSession('abc-123'), '/app/chat/abc-123');
      expect(AppRoutes.chatSession(''), '/app/chat/');
    });

    test('automationDetailPath builds correct path', () {
      expect(AppRoutes.automationDetailPath('run-456'), '/app/automations/run-456');
    });
  });
}
