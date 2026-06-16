import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// FirebaseService — centraliza instâncias Firebase.
/// Storage removido: não é utilizado neste projeto (plano gratuito).
class FirebaseService extends GetxService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  User? get currentUser => auth.currentUser;

  String get uid {
    final user = auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    return user.uid;
  }

  Stream<User?> get authStateChanges => auth.authStateChanges();

  // ─── Referências Firestore ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usersRef =>
      firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get workersRef =>
      firestore.collection('workers');
  CollectionReference<Map<String, dynamic>> get ordersRef =>
      firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get reviewsRef =>
      firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get chatsRef =>
      firestore.collection('chats');
  CollectionReference<Map<String, dynamic>> get reportsRef =>
      firestore.collection('reports');
  CollectionReference<Map<String, dynamic>> get notificationsRef =>
      firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> messagesRef(String orderId) =>
      chatsRef.doc(orderId).collection('messages');

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<FirebaseService> init() async {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await _requestNotificationPermission();
    _configureMessagingHandlers();
    debugPrint('[FirebaseService] Inicializado (sem Storage)');
    return this;
  }

  Future<void> _requestNotificationPermission() async {
    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
  }

  void _configureMessagingHandlers() {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] Foreground: ${msg.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleNav(msg.data);
    });
  }

  void _handleNav(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final targetId = data['targetId'] as String?;
    if (type == null || targetId == null) return;
    switch (type) {
      case 'new_order':
      case 'order_update':
        Get.toNamed('/order-detail', arguments: targetId);
        break;
      case 'new_message':
        Get.toNamed('/chat', arguments: targetId);
        break;
    }
  }

  Future<String?> getFcmToken() async {
    try { return await messaging.getToken(); } catch (_) { return null; }
  }

  Future<void> updateFcmToken(String userId, {bool isWorker = false}) async {
    final token = await getFcmToken();
    if (token == null) return;
    final ref = isWorker ? workersRef.doc(userId) : usersRef.doc(userId);
    await ref.update({'fcmToken': token});
  }

  Future<bool> isAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true;
  }

  Future<void> runBatch(Future<void> Function(WriteBatch b) ops) async {
    final batch = firestore.batch();
    await ops(batch);
    await batch.commit();
  }

  Future<T> runTransaction<T>(Future<T> Function(Transaction tx) ops) =>
      firestore.runTransaction(ops);

}
