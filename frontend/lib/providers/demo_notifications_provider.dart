import 'notifications_provider.dart';
import '../models/notification_model.dart';

/// Demo version of NotificationsProvider that works without Supabase/FCM.
/// Provides mock notifications for the report demo.
/// Extends NotificationsProvider for type compatibility with UI screens.
class DemoNotificationsProvider extends NotificationsProvider {
  final List<AppNotification> _demoNotifications = [];
  bool _demoIsLoading = false;
  bool _demoHasLoaded = false;

  @override
  List<AppNotification> get notifications => _demoNotifications;
  @override
  bool get isLoading => _demoIsLoading;
  @override
  bool get hasLoaded => _demoHasLoaded;
  @override
  int get unreadCount => _demoNotifications.where((n) => !n.isRead).length;

  /// No-op for demo.
  @override
  Future<void> initFCM() async {}

  /// No-op for demo.
  @override
  Future<void> deactivateCurrentToken() async {}

  /// Load notifications (mock — returns in-memory list).
  @override
  Future<void> loadNotifications() async {
    _demoIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _demoHasLoaded = true;
    _demoIsLoading = false;
    notifyListeners();
  }

  /// No-op for demo.
  @override
  Future<void> loadMoreNotifications() async {}

  /// Mark as read locally.
  @override
  Future<void> markAsRead(String id) async {
    final index = _demoNotifications.indexWhere((n) => n.id == id);
    if (index == -1 || _demoNotifications[index].isRead) return;

    _demoNotifications[index] = _demoNotifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  /// Mark all as read locally.
  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _demoNotifications.length; i++) {
      _demoNotifications[i] = _demoNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Mark visible as read locally.
  @override
  Future<void> markVisibleAsRead() async {
    for (int i = 0; i < _demoNotifications.length; i++) {
      _demoNotifications[i] = _demoNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Clear all notifications (demo only).
  Future<void> clearAllNotifications() async {
    _demoNotifications.clear();
    notifyListeners();
  }

  /// Adds the report-ready notification for the demo.
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
    notifyListeners();
  }
}
