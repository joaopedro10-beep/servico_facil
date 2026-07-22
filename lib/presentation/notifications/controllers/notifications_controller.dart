import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/datasources/firestore_datasource.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map, String docId) {
    // Parsing defensivo: createdAt pode ser Timestamp, null (serverTimestamp
    // pendente no snapshot local) ou até int (docs antigos). Antes, um
    // formato inesperado derrubava a tela inteira de notificações.
    DateTime created = DateTime.now();
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is DateTime) {
      created = raw;
    } else if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return NotificationItem(
      id: docId,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      targetId: map['targetId']?.toString(),
      isRead: map['isRead'] == true,
      createdAt: created,
    );
  }
}

class NotificationsController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final _notifService = Get.find<NotificationService>();

  final notifications = <NotificationItem>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _startStream();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Recarrega a stream — usado pelo botão "Tentar novamente".
  void retry() => _startStream();

  void _startStream() {
    isLoading.value = true;
    hasError.value = false;
    _sub?.cancel();
    _sub = _ds.watchNotifications(_fb.uid).listen((list) {
      // Parsing item a item: um documento malformado é ignorado em vez
      // de derrubar a tela inteira (motivo do "não carrega").
      final parsed = <NotificationItem>[];
      for (final m in list) {
        try {
          parsed.add(
              NotificationItem.fromMap(m, m['id']?.toString() ?? ''));
        } catch (_) {}
      }
      notifications.assignAll(parsed);
      _notifService.unreadCount.value =
          parsed.where((n) => !n.isRead).length;
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
      hasError.value = true;
    });
  }

  Future<void> markAllRead() async {
    try {
      await _ds.markAllNotificationsRead(_fb.uid);
      // A stream do Firestore reemite a lista atualizada automaticamente.
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível marcar como lidas.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _ds.markNotificationRead(id);
    } catch (_) {}
  }
}
