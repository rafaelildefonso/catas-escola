import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../services/token_holder.dart';
import '../core/app_config.dart';

/// Provider para gerenciar FCM (foreground notifications) e registro de dispositivo.
/// A lista de notificações é carregada separadamente pelos endpoints do backend.
class NotificationsProvider extends ChangeNotifier {
  String? _currentToken;

  String? get currentToken => _currentToken;

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
          debugPrint('FCM Token obtido.');
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
}
