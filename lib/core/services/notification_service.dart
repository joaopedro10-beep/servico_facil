import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';

/// Handler de background — deve ser top-level (fora da classe).
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService extends GetxService {
  static final _localPlugin = FlutterLocalNotificationsPlugin();

  // Canal Android
  static const _channelId = 'servicofacil_main';
  static const _channelName = 'ServiçoFácil';

  // Badge de notificações não lidas (atualizado pelo NotificationsController)
  final unreadCount = 0.obs;

  Future<NotificationService> init() async {
    // 1. Background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2. Inicializa flutter_local_notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTapLocalNotification,
    );

    // 3. Cria canal Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      enableVibration: true,
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Foreground: exibe local notification
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 5. App aberto pelo toque em notificação (terminated → open)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNavigation(initial.data);

    // 6. App em background, usuário tocou na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleNavigation(msg.data);
    });

    debugPrint('[NotificationService] Inicializado');
    return this;
  }

  // ── Foreground ────────────────────────────────────────────────────────────

  /// Exibe uma notificação local imediata (usada para alertas em tempo real
  /// gerados dentro do próprio app, ex.: nova solicitação para o prestador).
  Future<void> showLocal({
    required String title,
    required String body,
    String? type,
    String? targetId,
  }) async {
    try {
      await _localPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: _encodePayload({
          if (type != null) 'type': type,
          if (targetId != null) 'targetId': targetId,
        }),
      );
    } catch (e) {
      debugPrint('[NotificationService] showLocal falhou: $e');
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _localPlugin.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  // ── Navegação ao tocar ────────────────────────────────────────────────────

  static void _onTapLocalNotification(NotificationResponse response) {
    if (response.payload == null) return;
    final data = _decodePayload(response.payload!);
    _handleNavigation(data);
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final targetId = data['targetId'] as String?;
    if (type == null) return;

    switch (type) {
      case 'new_order':
      case 'order_update':
      case 'order_accepted':
      case 'order_scheduled':
      case 'order_started':
        if (targetId != null) {
          Get.toNamed(AppRoutes.orderDetail,
              arguments: {'orderId': targetId});
        }
        break;
      case 'new_message':
        if (targetId != null) {
          Get.toNamed(AppRoutes.chat,
              arguments: {'chatId': targetId});
        }
        break;
      case 'rating_warning':
      case 'cancellation_warning':
        Get.toNamed(AppRoutes.notifications);
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  static Map<String, dynamic> _decodePayload(String payload) {
    return Map.fromEntries(
      payload.split('&').map((p) {
        final parts = p.split('=');
        return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
      }),
    );
  }
}
