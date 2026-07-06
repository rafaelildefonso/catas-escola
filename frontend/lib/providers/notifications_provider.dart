import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../services/token_holder.dart';
import '../core/app_config.dart';

/// Provider para gerenciar notificações do usuário.
class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;
  String? _currentToken;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoaded => _hasLoaded;
  bool get hasMore => _hasMore;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Map<String, String> _headers() {
    final token = TokenHolder().token ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Inicializa o FCM, solicita permissão e salva o token
  Future<void> initFCM() async {
    final token = TokenHolder().token;
    if (token == null) return;

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM Permissão concedida.');

        String? fcmToken;
        try {
          fcmToken = await _fcm.getToken();
          debugPrint('FCM Token obtido: $fcmToken');
        } catch (tokenError) {
          debugPrint('FCM Erro ao obter token: $tokenError');
        }

        if (fcmToken != null) {
          _currentToken = fcmToken;
          await _saveTokenToApi(fcmToken);
        }

        _fcm.onTokenRefresh.listen((newToken) {
          _currentToken = newToken;
          _saveTokenToApi(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('FCM Mensagem recebida no foreground: ${message.notification?.title}');

          final notification = message.notification;
          final android = message.notification?.android;

          if (notification != null && android != null) {
            _localNotifications.show(
              notification.hashCode,
              notification.title,
              notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'catas_notifications',
                  'Notificações Importantes',
                  channelDescription: 'Canal para alertas de automação do CATAS',
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
          }

          loadNotifications();
        });
      } else {
        debugPrint('FCM Permissão não foi concedida.');
      }
    } catch (e) {
      debugPrint('FCM Erro ao inicializar: $e');
    }
  }

  Future<void> _saveTokenToApi(String fcmToken) async {
    final token = TokenHolder().token;
    if (token == null) return;

    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/user-devices'),
        headers: _headers(),
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': platform,
          'active': true,
        }),
      );
      debugPrint('FCM Token salvo via API: ${response.statusCode}');
    } catch (e) {
      debugPrint('Erro ao salvar FCM Token: $e');
    }
  }

  Future<void> deactivateCurrentToken() async {
    final token = TokenHolder().token;
    if (token == null || _currentToken == null) return;

    try {
      await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/user-devices'),
        headers: _headers(),
        body: jsonEncode({'active': false}),
      );
      _currentToken = null;
      debugPrint('FCM Token desativado com sucesso.');
    } catch (e) {
      debugPrint('Erro ao desativar FCM Token: $e');
    }
  }

  Future<void> loadNotifications() async {
    final token = TokenHolder().token;
    if (token == null || _isLoading) return;

    _isLoading = true;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications?limit=$_limit&offset=$_offset'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> data;
        if (body is List) {
          data = body;
        } else if (body is Map && body.containsKey('data')) {
          data = body['data'] as List<dynamic>;
        } else {
          data = [];
        }

        _notifications = data.map((e) => AppNotification.fromMap(e)).toList();
        _hasLoaded = true;
        if (data.length < _limit) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    final token = TokenHolder().token;
    if (token == null || _isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _offset += _limit;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications?limit=$_limit&offset=$_offset'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> data;
        if (body is List) {
          data = body;
        } else if (body is Map && body.containsKey('data')) {
          data = body['data'] as List<dynamic>;
        } else {
          data = [];
        }

        final newNotifications = data.map((e) => AppNotification.fromMap(e)).toList();
        _notifications.addAll(newNotifications);

        if (data.length < _limit) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar mais notificações: $e');
      _offset -= _limit;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id'),
        headers: _headers(),
        body: jsonEncode({'is_read': true}),
      );
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      for (final id in unreadIds) {
        await http.put(
          Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id'),
          headers: _headers(),
          body: jsonEncode({'is_read': true}),
        );
      }
    } catch (e) {
      debugPrint('Erro ao marcar todas como lidas: $e');
    }
  }

  Future<void> markVisibleAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    _notifications = _notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();

    notifyListeners();

    try {
      for (final n in unread) {
        await http.put(
          Uri.parse('${AppConfig.apiBaseUrl}/notifications/${n.id}'),
          headers: _headers(),
          body: jsonEncode({'is_read': true}),
        );
      }
    } catch (e) {
      debugPrint('Erro ao marcar visíveis como lidas: $e');
    }
  }
}
