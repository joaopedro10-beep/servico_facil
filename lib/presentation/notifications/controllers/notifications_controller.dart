import 'dart:async';

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
    return NotificationItem(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      targetId: map['targetId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

class NotificationsController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final _notifService = Get.find<NotificationService>();

  final notifications = <NotificationItem>[].obs;
  final isLoading = true.obs;
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

  void _startStream() {
    isLoading.value = true;
    _sub?.cancel();
    _sub = _ds.watchNotifications(_fb.uid).listen((list) {
      notifications.assignAll(
          list.map((m) => NotificationItem.fromMap(m, m['id'] as String)).toList());
      _notifService.unreadCount.value =
          notifications.where((n) => !n.isRead).length;
      isLoading.value = false;
    }, onError: (_) => isLoading.value = false);
  }

  Future<void> markAllRead() async {
    await _ds.markAllNotificationsRead(_fb.uid);
    for (final n in notifications) {
      if (!n.isRead) notifications.refresh();
    }
  }

  Future<void> markRead(String id) async {
    await _ds.markNotificationRead(id);
  }
}
