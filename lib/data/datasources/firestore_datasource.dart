import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';
import '../models/message_model.dart';
import '../models/order_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../models/user_address.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';

/// FirestoreDatasource — camada única de acesso ao Firestore.
///
/// REGRA ARQUITETURAL:
/// Nenhum Controller acessa o Firebase diretamente.
/// Toda operação obrigatoriamente passa por este datasource.
///
/// Lança [ServerException] em caso de erro no Firestore.
/// Lança [ValidationException] em caso de violação de regra de negócio.
class FirestoreDatasource {
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

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

  Future<void> updateUser(
      String userId, Map<String, dynamic> data) async {
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

  /// Busca um usuário pelo nome para admin — aceita pelo datasource,
  /// não pelo controller.
  Future<String?> getUserName(String userId) async {
    try {
      final doc = await _fb.usersRef.doc(userId).get();
      return doc.data()?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Verifica se CPF já está em uso (para validação de perfil).
  Future<bool> isCpfInUse(String cpf, String currentUserId) async {
    try {
      final q = await _fb.usersRef
          .where('cpf', isEqualTo: cpf)
          .limit(2)
          .get();
      return q.docs.any((d) => d.id != currentUserId);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao verificar CPF: ${e.message}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WORKERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> createWorker(WorkerModel worker) async {
    try {
      await _fb.workersRef.doc(worker.id).set(worker.toMap());
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar prestador: ${e.message}');
    }
  }

  Future<WorkerModel?> getWorker(String workerId) async {
    try {
      final doc = await _fb.workersRef.doc(workerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return WorkerModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao buscar prestador: ${e.message}');
    }
  }

  /// Stream de prestadores verificados, disponíveis e não suspensos.
  Stream<List<WorkerModel>> watchAvailableWorkers({String? category}) {
    Query<Map<String, dynamic>> query = _fb.workersRef
        .where('isVerified', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('isSuspended', isEqualTo: false);
    if (category != null) {
      query = query.where('categories', arrayContains: category);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) => WorkerModel.fromMap(d.data(), d.id))
        .where((w) => w.rating >= 2.5 || w.totalReviews == 0)
        .toList());
  }

  Future<void> updateWorker(
      String workerId, Map<String, dynamic> data) async {
    try {
      await _fb.workersRef.doc(workerId).update(data);
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar prestador: ${e.message}');
    }
  }

  Future<void> updateWorkerAvailability(
      String workerId, bool isAvailable) async {
    await updateWorker(workerId, {'isAvailable': isAvailable});
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ORDERS — Streams
  // ══════════════════════════════════════════════════════════════════════════

  /// [watchOrders] — stream de UM pedido específico por ID.
  /// Atualiza em tempo real quando qualquer campo muda.
  Stream<OrderModel?> watchOrders(String orderId) {
    return _fb.ordersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Alias explícito de [watchOrders] para manter compatibilidade.
  Stream<OrderModel?> watchOrder(String orderId) => watchOrders(orderId);

  /// [watchClientOrders] — todos os pedidos do cliente, sorted por createdAt desc.
  /// Sem orderBy no Firestore (evita composite index).
  Stream<List<OrderModel>> watchClientOrders(String userId) {
    return _fb.ordersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => OrderModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// [watchWorkerOrders] — todos os pedidos vinculados ao prestador (workerId=uid).
  /// Atualiza em tempo real; sorted por createdAt desc em memória.
  Stream<List<OrderModel>> watchWorkerOrders(String workerId) {
    return _fb.ordersRef
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => OrderModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// [watchAvailableOrders] — pedidos pendentes ainda sem prestador.
  ///
  /// Filtra APENAS prestadores elegíveis:
  ///   • isVerified == true
  ///   • isAvailable == true
  ///   • isSuspended == false
  ///   • verificationStatus == 'approved'
  ///   • hasActiveJob == false
  ///   • activeCategories não vazio
  ///
  /// Matching de categoria: igualdade exata case-insensitive.
  /// Sem orderBy no Firestore (evita composite index — sort em memória).
  Stream<List<OrderModel>> watchAvailableOrders({
    required List<String> activeCategories,
    required bool hasActiveJob,
    required bool isVerified,
    required bool isAvailable,
    required bool isSuspended,
    required String verificationStatus,
  }) {
    final eligible = isVerified &&
        isAvailable &&
        !isSuspended &&
        verificationStatus == 'approved' &&
        !hasActiveJob &&
        activeCategories.isNotEmpty;

    if (!eligible) return Stream.value([]);

    final normalizedCats = activeCategories
        .map((c) => c.trim().toLowerCase())
        .toSet();

    return _fb.ordersRef
        .where('workerId', isEqualTo: '')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((d) => OrderModel.fromMap(d.data(), d.id))
              .toList();

          final filtered = orders.where((order) {
            final orderCat = order.serviceCategory.trim().toLowerCase();
            return normalizedCats.contains(orderCat);
          }).toList();

          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return filtered;
        });
  }

  // Alias do nome anterior para compatibilidade
  Stream<List<OrderModel>> watchAvailableOrdersForWorker({
    required List<String> activeCategories,
    required bool hasActiveJob,
    required bool isVerified,
    required bool isAvailable,
    required bool isSuspended,
    required String verificationStatus,
  }) => watchAvailableOrders(
    activeCategories:   activeCategories,
    hasActiveJob:       hasActiveJob,
    isVerified:         isVerified,
    isAvailable:        isAvailable,
    isSuspended:        isSuspended,
    verificationStatus: verificationStatus,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ORDERS — Ciclo de vida completo
  // ══════════════════════════════════════════════════════════════════════════

  /// [createOrder] — cria pedido com workerId='' e scheduledAt=null.
  /// Status inicial: pending.
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final ref = _fb.ordersRef.doc();
      final now = DateTime.now();
      final newOrder = OrderModel(
        id:              ref.id,
        userId:          order.userId,
        workerId:        null,
        serviceCategory: order.serviceCategory,
        description:     order.description,
        photoUrls:       order.photoUrls,
        scheduledAt:     null,
        status:          OrderStatus.pending,
        address:         order.address,
        price:           null,
        createdAt:       now,
        updatedAt:       now,
        clientName:      order.clientName,
        workerName:      null,
      );
      final map      = newOrder.toMap();
      map['status']   = 'pending';
      map['workerId'] = ''; // string vazia para query .where('workerId', isEqualTo: '')
      await ref.set(map);
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

  /// [acceptOrder] — transação atômica: verifica workerId=='' dentro da
  /// transação e atualiza workerId, workerName, acceptedAt, status=accepted.
  /// Lança [ValidationException] se outro prestador já aceitou.
  Future<void> acceptOrder(
    String orderId,
    String workerId,
    String workerName,
  ) async {
    try {
      await _fb.runTransaction((tx) async {
        final orderRef = _fb.ordersRef.doc(orderId);
        final snapshot = await tx.get(orderRef);

        if (!snapshot.exists || snapshot.data() == null) {
          throw const ValidationException('Pedido não encontrado.');
        }

        final currentWorkerId =
            snapshot.data()!['workerId'] as String? ?? '';
        final currentStatus =
            snapshot.data()!['status'] as String? ?? '';

        if (currentWorkerId.isNotEmpty || currentStatus != 'pending') {
          throw const ValidationException(
              'Este pedido já foi aceito por outro profissional.');
        }

        tx.update(orderRef, {
          'workerId':   workerId,
          'workerName': workerName,
          'status':     'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt':  FieldValue.serverTimestamp(),
        });
      });
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao aceitar pedido: ${e.message}');
    }
  }

  // Alias do nome anterior para compatibilidade
  Future<void> claimOrder(
      String orderId, String workerId, String workerName) =>
      acceptOrder(orderId, workerId, workerName);

  /// [refuseOrder] — prestador recusa: pedido volta para pending com workerId=''.
  Future<void> refuseOrder(String orderId) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status':    'pending',
        'workerId':  '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao recusar pedido: ${e.message}');
    }
  }

  /// [scheduleOrder] — prestador define data e hora do serviço.
  /// Salva scheduledAt como Timestamp (obrigatório — DateTime direto não funciona).
  Future<void> scheduleOrder(
      String orderId, DateTime scheduledAt) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'status':      'accepted',
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao agendar: ${e.message}');
    }
  }

  // Alias do nome anterior para compatibilidade
  Future<void> updateOrderSchedule(
    String orderId,
    DateTime scheduledAt, {
    OrderStatus status = OrderStatus.accepted,
  }) => scheduleOrder(orderId, scheduledAt);

  /// [startOrder] — prestador inicia o serviço: status = inProgress.
  Future<void> startOrder(String orderId) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status':    'inProgress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao iniciar serviço: ${e.message}');
    }
  }

  /// [finishOrder] — prestador conclui o serviço: status = done.
  Future<void> finishOrder(String orderId) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status':      'done',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao finalizar serviço: ${e.message}');
    }
  }

  /// [cancelOrder] — cliente ou sistema cancela: status = cancelled.
  Future<void> cancelOrder(String orderId) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status':      'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao cancelar pedido: ${e.message}');
    }
  }

  /// Método genérico de atualização de status com timestamp correto.
  /// Usado pelo OrderController e pelos métodos acima.
  Future<void> updateOrderStatusWithTimestamp(
      String orderId, OrderStatus newStatus) async {
    switch (newStatus) {
      case OrderStatus.accepted:
        await _fb.ordersRef.doc(orderId).update({
          'status':     'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt':  FieldValue.serverTimestamp(),
        });
        break;
      case OrderStatus.inProgress:
        await startOrder(orderId);
        break;
      case OrderStatus.done:
        await finishOrder(orderId);
        break;
      case OrderStatus.cancelled:
        await cancelOrder(orderId);
        break;
      default:
        await _fb.ordersRef.doc(orderId).update({
          'status':    newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    }
  }

  /// Atualização genérica de campos de um pedido.
  Future<void> updateOrderStatus(
      String orderId, String status) async {
    try {
      await _fb.ordersRef.doc(orderId).update({
        'status':    status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao atualizar pedido: ${e.message}');
    }
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

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// [saveNotification] — persiste uma notificação para ser lida pelo app
  /// ou enviada via FCM por Cloud Function.
  Future<void> saveNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? targetId,
  }) async {
    try {
      await _fb.notificationsRef.add({
        'targetUserId': targetUserId,
        'title':    title,
        'body':     body,
        'type':     type,
        'targetId': targetId,
        'isRead':   false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar notificação: ${e.message}');
    }
  }

  /// [watchNotifications] — stream de notificações do usuário atual.
  /// Sem orderBy (evita composite index). Sort em memória.
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _fb.notificationsRef
        .where('targetUserId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList();
          list.sort((a, b) {
            final ta = a['createdAt'];
            final tb = b['createdAt'];
            if (ta == null || tb == null) return 0;
            final da = (ta as Timestamp).toDate();
            final db = (tb as Timestamp).toDate();
            return db.compareTo(da);
          });
          return list;
        });
  }

  /// [markNotificationRead] — marca uma notificação como lida.
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _fb.notificationsRef
          .doc(notificationId)
          .update({'isRead': true});
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao marcar notificação: ${e.message}');
    }
  }

  /// [markAllNotificationsRead] — marca todas as notificações do usuário como lidas.
  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final unread = await _fb.notificationsRef
          .where('targetUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      await _fb.runBatch((batch) async {
        for (final doc in unread.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
      });
    } on FirebaseException catch (e) {
      throw ServerException(
          'Erro ao marcar notificações: ${e.message}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWS
  // ══════════════════════════════════════════════════════════════════════════

  /// [watchReviews] — stream de avaliações de um alvo (workerId ou userId).
  /// Sem orderBy (evita composite index). Sort por createdAt desc em memória.
  Stream<List<ReviewModel>> watchReviews(String targetId) {
    return _fb.reviewsRef
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ReviewModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Cria uma review e atualiza o rating do alvo em transação atômica.
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

        final workerDoc =
            await _fb.workersRef.doc(review.targetId).get();
        final isWorkerTarget = workerDoc.exists;
        final targetRef = isWorkerTarget
            ? _fb.workersRef.doc(review.targetId)
            : _fb.usersRef.doc(review.targetId);

        tx.update(targetRef, {
          'rating':       FieldValue.increment(review.rating),
          'totalReviews': FieldValue.increment(1),
        });

        if (isWorkerTarget) {
          final data     = workerDoc.data()!;
          final oldSum   = (data['rating'] ?? 0.0).toDouble();
          final oldCount = (data['totalReviews'] ?? 0) as int;
          final newAvg   = (oldSum + review.rating) / (oldCount + 1);
          if (newAvg < 2.5 && (data['isAvailable'] == true)) {
            tx.update(_fb.workersRef.doc(review.targetId),
                {'isAvailable': false});
          }
        }
      });
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao salvar avaliação: ${e.message}');
    }
  }

  /// Paginação de avaliações — sem orderBy na stream, mas aceito aqui
  /// pois é uma query única (não stream), logo sem composite index runtime.
  Future<List<ReviewModel>> getReviewsPaged(
    String targetId, {
    DocumentSnapshot? lastDoc,
    double? starFilter,
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
    return snap.docs
        .map((d) => ReviewModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT / MESSAGES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initChat({
    required String orderId,
    required String userId,
    required String workerId,
  }) async {
    try {
      await _fb.chatsRef.doc(orderId).set({
        'orderId':       orderId,
        'participants':  [userId, workerId],
        'lastMessage':   null,
        'lastMessageAt': null,
        'createdAt':     FieldValue.serverTimestamp(),
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
        batch.update(_fb.chatsRef.doc(message.chatId), {
          'lastMessage':   message.content ?? '📷 Foto',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao enviar mensagem: ${e.message}');
    }
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _fb.messagesRef(chatId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => MessageModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
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
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList();
          list.sort((a, b) {
            final ta = a['lastMessageAt'];
            final tb = b['lastMessageAt'];
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return (tb as Timestamp)
                .toDate()
                .compareTo((ta as Timestamp).toDate());
          });
          return list;
        });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REPORTS / DENÚNCIAS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> createReport(ReportModel report) async {
    try {
      await _fb.runTransaction((tx) async {
        final reportRef = _fb.reportsRef.doc();
        tx.set(reportRef, report.toMap());

        final recentReports = await _fb.reportsRef
            .where('reportedId', isEqualTo: report.reportedId)
            .where('status', isEqualTo: 'open')
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 30))))
            .get();

        if (recentReports.docs.length >= 2) {
          final workerDoc =
              await _fb.workersRef.doc(report.reportedId).get();
          if (workerDoc.exists) {
            tx.update(_fb.workersRef.doc(report.reportedId),
                {'isSuspended': true, 'isAvailable': false});
          } else {
            tx.update(_fb.usersRef.doc(report.reportedId),
                {'isSuspended': true});
          }
        }
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao enviar denúncia: ${e.message}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLOCK
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> blockUser({
    required String currentUserId,
    required String targetId,
  }) async {
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

  Future<bool> isBlocked({
    required String currentUserId,
    required String targetId,
  }) async {
    final doc = await _fb.usersRef
        .doc(currentUserId)
        .collection('blocked')
        .doc(targetId)
        .get();
    return doc.exists;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRESENÇA / LAST SEEN
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> updateLastSeen(String uid, {required bool isWorker}) async {
    final ref =
        isWorker ? _fb.workersRef.doc(uid) : _fb.usersRef.doc(uid);
    await ref.update({'lastSeen': FieldValue.serverTimestamp()});
  }

  Stream<DateTime?> watchLastSeen(String uid, {required bool isWorker}) {
    final ref =
        isWorker ? _fb.workersRef.doc(uid) : _fb.usersRef.doc(uid);
    return ref.snapshots().map((doc) {
      final ts = doc.data()?['lastSeen'] as Timestamp?;
      return ts?.toDate();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAFETY TIPS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<dynamic>> getSafetyTips() async {
    try {
      final snap = await _fb.firestore
          .collection('safety_tips')
          .orderBy('order')
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }
}
