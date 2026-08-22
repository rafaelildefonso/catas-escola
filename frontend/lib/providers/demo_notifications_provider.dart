import 'notifications_provider.dart';
import '../models/notification_model.dart';

/// Demo version of NotificationsProvider — no-op for FCM.
/// Keeps local-only demo helpers (addReportReadyNotification) for demo screens.
class DemoNotificationsProvider extends NotificationsProvider {
  final List<AppNotification> _demoNotifications = [];

  @override
  Future<void> initFCM() async {}

  /// Adds the report-ready notification for the demo (local only, no backend).
  void addReportReadyNotification() {
    final now = DateTime.now();
    final notification = AppNotification(
      id: 'demo-notif-report-${now.millisecondsSinceEpoch}',
      userId: 'demo-user',
      type: NotificationType.automation,
      title: 'Relatório de Vendas Semanal',
      body: 'Seu relatório está pronto! Clique para visualizar e baixar.',
      actionType: 'app_route',
      actionData: '/report/demo',
      metadata: {
        'automation_name': 'Relatório de Vendas Semanal',
        'automation_status': 'success',
      },
      isRead: false,
      createdAt: now,
    );

    _demoNotifications.insert(0, notification);
  }
}
