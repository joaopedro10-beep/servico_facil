import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';
import '../models/models.dart';
import '../models/order_model.dart';
import '../models/models.dart';


/// FirestoreDatasource — operações CRUD para todas as coleções do Firestore.
/// Lança AppException em caso de erro; repositórios convertem em Failures.
class FirestoreDatasource {
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─────────────────────────────────────────────────────────────────────────
  //  USERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    try {
      await _fb.usersRef.doc(user.id).set(user.toMap());
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar usuário: ${e.message}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _fb.usersRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao buscar usuário: ${e.message}');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _fb.usersRef.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar usuário: ${e.message}');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      await _fb.usersRef.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao deletar usuário: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WORKERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createWorker(WorkerModel worker) async {
    try {
      await _fb.workersRef.doc(worker.id).set(worker.toMap());
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar trabalhador: ${e.message}');
    }
  }

  Future<WorkerModel?> getWorker(String workerId) async {
    try {
      final doc = await _fb.workersRef.doc(workerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return WorkerModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao buscar trabalhador: ${e.message}');
    }
  }

  /// Stream de trabalhadores disponíveis, verificados, não suspensos e com rating >= 2.5
  Stream<List<WorkerModel>> watchAvailableWorkers({String? category}) {
    Query<Map<String, dynamic>> query = _fb.workersRef
        .where('isVerified', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('isSuspended', isEqualTo: false);

    if (category != null) {
      query = query.where('categories', arrayContains: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs
          .map((d) => WorkerModel.fromMap(d.data(), d.id))
          .where((w) => w.rating >= 2.5 || w.totalReviews == 0)
          .toList(),
    );
  }

  Future<void> updateWorker(String workerId, Map<String, dynamic> data) async {
    try {
      await _fb.workersRef.doc(workerId).update(data);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar trabalhador: ${e.message}');
    }
  }

  Future<void> updateWorkerAvailability(
      String workerId, bool isAvailable) async {
    await updateWorker(workerId, {'isAvailable': isAvailable});
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ORDERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final ref = _fb.ordersRef.doc();
      final newOrder = OrderModel(
        id: ref.id,
        userId: order.userId,
        workerId: order.workerId,
        serviceCategory: order.serviceCategory,
        description: order.description,
        photoUrls: order.photoUrls,
        scheduledAt: order.scheduledAt,
        address: order.address,
        price: order.price,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.set(newOrder.toMap());
      return newOrder;
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao criar pedido: ${e.message}');
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _fb.ordersRef.doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao buscar pedido: ${e.message}');
    }
  }

  /// Stream de pedidos de um cliente (filtra por userId).
  Stream<List<OrderModel>> watchClientOrders(String userId) {
    return _fb.ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream de pedidos de um trabalhador (filtra por workerId).
  Stream<List<OrderModel>> watchWorkerOrders(String workerId) {
    return _fb.ordersRef
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateOrderStatus(
      String orderId, String status) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar pedido: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REVIEWS
  // ─────────────────────────────────────────────────────────────────────────

  /// Cria uma review e atualiza o rating do alvo em transação.
  Future<void> createReview(ReviewModel review) async {
    try {
      await _fb.runTransaction((tx) async {
        final existing = await _fb.reviewsRef
            .where('orderId', isEqualTo: review.orderId)
            .where('authorId', isEqualTo: review.authorId)
            .get();
        if (existing.docs.isNotEmpty) {
          throw const ValidationException('Você já avaliou este serviço.');
        }

        final reviewRef = _fb.reviewsRef.doc();
        tx.set(reviewRef, review.toMap());

        final workerDoc = await _fb.workersRef.doc(review.targetId).get();
        final isWorkerTarget = workerDoc.exists;
        final targetRef = isWorkerTarget
            ? _fb.workersRef.doc(review.targetId)
            : _fb.usersRef.doc(review.targetId);

        tx.update(targetRef, {
          'rating': FieldValue.increment(review.rating),
          'totalReviews': FieldValue.increment(1),
        });

        // Se nova média cai abaixo de 2.5 → desabilita o worker
        if (isWorkerTarget) {
          final data = workerDoc.data()!;
          final oldSum = (data['rating'] ?? 0.0).toDouble();
          final oldCount = (data['totalReviews'] ?? 0) as int;
          final newAvg = (oldSum + review.rating) / (oldCount + 1);
          if (newAvg < 2.5 && (data['isAvailable'] == true)) {
            tx.update(_fb.workersRef.doc(review.targetId), {
              'isAvailable': false,
            });
          }
        }
      });
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar avaliação: ${e.message}');
    }
  }


  Stream<List<ReviewModel>> watchReviews(String targetId) {
    return _fb.reviewsRef
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList());
  }

  /// Paginação de reviews — page size 10, passa lastDoc para próxima página.
  Future<List<ReviewModel>> getReviewsPaged(
    String targetId, {
    DocumentSnapshot? lastDoc,
    double? starFilter, // null = todas
    int pageSize = 10,
  }) async {
    Query<Map<String, dynamic>> q = _fb.reviewsRef
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (starFilter != null) {
      q = q.where('rating', isEqualTo: starFilter);
    }
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);

    final snap = await q.get();
    return snap.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList();
  }

  /// Conta cancelamentos do cliente nos últimos 30 dias.
  Future<int> countClientCancellationsThisMonth(String userId) async {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)));
    final snap = await _fb.ordersRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'cancelled')
        .where('createdAt', isGreaterThan: since)
        .get();
    return snap.size;
  }

  /// Atualiza o campo lastSeen do usuário ou trabalhador.
  Future<void> updateLastSeen(String uid, {required bool isWorker}) async {
    final ref = isWorker ? _fb.workersRef.doc(uid) : _fb.usersRef.doc(uid);
    await ref.update({'lastSeen': FieldValue.serverTimestamp()});
  }

  /// Lê o lastSeen de um usuário/trabalhador como stream.
  Stream<DateTime?> watchLastSeen(String uid, {required bool isWorker}) {
    final ref = isWorker ? _fb.workersRef.doc(uid) : _fb.usersRef.doc(uid);
    return ref.snapshots().map((doc) {
      final ts = doc.data()?['lastSeen'] as Timestamp?;
      return ts?.toDate();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CHAT / MESSAGES
  // ─────────────────────────────────────────────────────────────────────────

  /// Inicializa o documento do chat (identificado pelo orderId).
  Future<void> initChat({
    required String orderId,
    required String userId,
    required String workerId,
  }) async {
    try {
      await _fb.chatsRef.doc(orderId).set({
        'orderId': orderId,
        'participants': [userId, workerId],
        'lastMessage': null,
        'lastMessageAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao inicializar chat: ${e.message}');
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      final msgRef = _fb.messagesRef(message.chatId).doc();
      await _fb.runBatch((batch) async {
        batch.set(msgRef, message.toMap());
        // Atualiza preview no documento do chat
        batch.update(_fb.chatsRef.doc(message.chatId), {
          'lastMessage': message.content ?? '📷 Foto',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao enviar mensagem: ${e.message}');
    }
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _fb.messagesRef(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  /// Marca todas as mensagens não lidas (de outro remetente) como lidas.
  Future<void> markMessagesAsRead(
      {required String chatId, required String currentUserId}) async {
    try {
      final unread = await _fb.messagesRef(chatId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      if (unread.docs.isEmpty) return;

      await _fb.runBatch((batch) async {
        for (final doc in unread.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao marcar mensagens: ${e.message}');
    }
  }

  Stream<List<Map<String, dynamic>>> watchChatList(String userId) {
    return _fb.chatsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REPORTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createReport(ReportModel report) async {
    try {
      await _fb.runTransaction((tx) async {
        // Cria o report
        final reportRef = _fb.reportsRef.doc();
        tx.set(reportRef, report.toMap());

        // Conta reports "open" nos últimos 30 dias contra o reportado
        final recentReports = await _fb.reportsRef
            .where('reportedId', isEqualTo: report.reportedId)
            .where('status', isEqualTo: 'open')
            .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 30))))
            .get();

        // Suspende automaticamente com 3+ denúncias
        if (recentReports.docs.length >= 2) {
          // +1 (o atual ainda não foi commitado)
          final workerDoc =
          await _fb.workersRef.doc(report.reportedId).get();
          if (workerDoc.exists) {
            tx.update(_fb.workersRef.doc(report.reportedId),
                {'isSuspended': true, 'isAvailable': false});
          } else {
            tx.update(
                _fb.usersRef.doc(report.reportedId), {'isSuspended': true});
          }
        }
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao enviar denúncia: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BLOCK
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> blockUser(
      {required String currentUserId, required String targetId}) async {
    try {
      await _fb.usersRef
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao bloquear usuário: ${e.message}');
    }
  }

  Future<bool> isBlocked(
      {required String currentUserId, required String targetId}) async {
    final doc = await _fb.usersRef
        .doc(currentUserId)
        .collection('blocked')
        .doc(targetId)
        .get();
    return doc.exists;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  NOTIFICATIONS (Firestore-based — lidas pelo Cloud Function ou pelo app)
  // ─────────────────────────────────────────────────────────────────────────

  /// Salva uma notificação na coleção do destinatário e na coleção global.
  /// Um Cloud Function pode escutar essa coleção e disparar o FCM push.
  Future<void> saveNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,  // 'new_order' | 'order_update' | 'new_review' ...
    String? targetId,      // orderId, workerId, etc.
  }) async {
    try {
      await _fb.notificationsRef.add({
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'type': type,
        'targetId': targetId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar notificação: ${e.message}');
    }
  }

  /// Atualiza status do pedido com o timestamp correto para cada etapa.
  Future<void> updateOrderStatusWithTimestamp(
      String orderId, OrderStatus newStatus) async {
    final now = FieldValue.serverTimestamp();
    final Map<String, dynamic> data = {
      'status': newStatus.name,
      'updatedAt': now,
    };
    switch (newStatus) {
      case OrderStatus.accepted:
        data['acceptedAt'] = now;
        break;
      case OrderStatus.inProgress:
        data['startedAt'] = now;
        break;
      case OrderStatus.done:
        data['completedAt'] = now;
        break;
      case OrderStatus.cancelled:
        data['cancelledAt'] = now;
        break;
      default:
        break;
    }
    try {
      await _fb.ordersRef.doc(orderId).update(data);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar pedido: ${e.message}');
    }
  }

  /// Stream de um pedido específico (tempo real).
  Stream<OrderModel?> watchOrder(String orderId) {
    return _fb.ordersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    });
  }

}
