import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

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

  late final _supabase = Supabase.instance.client;
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Inicializa o FCM, solicita permissão e salva o token
  Future<void> initFCM() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Apenas web/mobile suportam isso nativamente, mas firebase_messaging no web
    // precisa de config extra de service worker, então testamos se pode prosseguir.
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

      // Inicializa local notifications para o foreground
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM Permissão concedida.');
        
        // Pega o token atual
        debugPrint('FCM Chamando getToken()...');
        String? token;
        try {
          token = await _fcm.getToken();
          debugPrint('FCM Token obtido: $token');
        } catch (tokenError) {
          debugPrint('FCM Erro ao obter token: $tokenError');
        }

        if (token != null) {
          _currentToken = token;
          await _saveTokenToSupabase(token);
        } else {
          debugPrint('FCM Token é NULO.');
        }

        // Fica escutando mudanças de token
        _fcm.onTokenRefresh.listen((newToken) {
          _currentToken = newToken;
          _saveTokenToSupabase(newToken);
        });

        // Configura listener de mensagens no foreground
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
          
          // Opcional: Recarregar a lista de notificações do banco
          loadNotifications();
        });

      } else {
        debugPrint('FCM Permissão não foi concedida.');
      }
    } catch (e) {
      debugPrint('FCM Erro ao inicializar: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');

    try {
      debugPrint('FCM Salvando token no Supabase para usuário ${user.id}...');
      final response = await _supabase.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': platform,
        'active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token').select();
      
      debugPrint('FCM Token salvo com sucesso: ${response.isNotEmpty}');
    } catch (e) {
      debugPrint('Erro ao salvar FCM Token no Supabase: $e');
    }
  }

  /// Desativa o token atual no Supabase (chamado no logout)
  Future<void> deactivateCurrentToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _currentToken == null) {
      debugPrint('FCM: Não há usuário ou token para desativar.');
      return;
    }

    try {
      debugPrint('FCM Desativando token para usuário ${user.id}...');
      await _supabase
          .from('user_devices')
          .update({'active': false})
          .eq('user_id', user.id)
          .eq('fcm_token', _currentToken!);
      
      _currentToken = null;
      debugPrint('FCM Token desativado com sucesso.');
    } catch (e) {
      debugPrint('Erro ao desativar FCM Token: $e');
    }
  }

  /// Carrega notificações do Supabase.
  Future<void> loadNotifications() async {
    if (_isLoading) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      _notifications =
          (data as List).map((e) => AppNotification.fromMap(e)).toList();
      _hasLoaded = true;
      if (data.length < _limit) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega mais notificações (paginação).
  Future<void> loadMoreNotifications() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoadingMore = true;
    _offset += _limit;
    notifyListeners();

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final newNotifications =
          (data as List).map((e) => AppNotification.fromMap(e)).toList();
          
      _notifications.addAll(newNotifications);
      
      if (data.length < _limit) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Erro ao carregar mais notificações: $e');
      _offset -= _limit; // Reverte offset em caso de erro
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Marca uma notificação como lida.
  Future<void> markAsRead(String id) async {
    // Atualiza localmente imediatamente
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  /// Marca TODAS as notificações não-lidas como lidas.
  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    // Atualiza localmente imediatamente
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Erro ao marcar todas como lidas: $e');
    }
  }

  /// Marca todas as notificações visíveis na tela como lidas.
  Future<void> markVisibleAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    // Atualiza localmente de uma vez
    _notifications = _notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();

    notifyListeners();

    try {
      final unreadIds = unread.map((n) => n.id).toList();
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .filter('id', 'in', unreadIds);
    } catch (e) {
      debugPrint('Erro ao marcar visíveis como lidas: $e');
    }
  }
}
