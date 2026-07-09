import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';
import '../models/admin_log_model.dart';
import '../models/order_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';

/// AdminDatasource — operações exclusivas do painel administrativo.
/// Separado do FirestoreDatasource para manter responsabilidades claras.
class AdminDatasource {
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─── Workers pendentes ────────────────────────────────────────────────────

  Stream<List<WorkerModel>> watchPendingWorkers() {
    return _fb.workersRef
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => WorkerModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<WorkerModel>> watchAllWorkers() {
    return _fb.workersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => WorkerModel.fromMap(d.data(), d.id)).toList());
  }

  // ─── Aprovar / Rejeitar / Solicitar documentos ───────────────────────────

  Future<void> approveWorker(String workerId) async {
    try {
      await _fb.workersRef.doc(workerId).update({
        'verificationStatus': 'approved',
        'isVerified': true,
        'isAvailable': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _fb.uid,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao aprovar prestador: ${e.message}');
    }
  }

  Future<void> rejectWorker(String workerId, String reason) async {
    try {
      await _fb.workersRef.doc(workerId).update({
        'verificationStatus': 'rejected',
        'isVerified': false,
        'isAvailable': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _fb.uid,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao rejeitar prestador: ${e.message}');
    }
  }

  Future<void> requestMoreDocuments(String workerId, String message) async {
    try {
      await _fb.workersRef.doc(workerId).update({
        'verificationStatus': 'incomplete',
        'documentRequestMessage': message,
        'documentRequestedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao solicitar documentos: ${e.message}');
    }
  }

  // ─── Usuários ─────────────────────────────────────────────────────────────

  Stream<List<UserModel>> watchAllUsers() {
    return _fb.usersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    final snapshot = await _fb.usersRef.get();
    return snapshot.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.cpf ?? '').contains(q))
        .toList();
  }

  Future<void> suspendUser(String userId, {bool isWorker = false}) async {
    try {
      final ref = isWorker ? _fb.workersRef.doc(userId) : _fb.usersRef.doc(userId);
      await ref.update({
        'isSuspended': true,
        'isAvailable': isWorker ? false : null,
        'suspendedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao suspender: ${e.message}');
    }
  }

  Future<void> unsuspendUser(String userId, {bool isWorker = false}) async {
    try {
      final ref = isWorker ? _fb.workersRef.doc(userId) : _fb.usersRef.doc(userId);
      await ref.update({
        'isSuspended': false,
        'suspendedAt': null,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao remover suspensão: ${e.message}');
    }
  }

  Future<void> banUser(String userId, String reason,
      {bool isWorker = false}) async {
    try {
      final ref = isWorker ? _fb.workersRef.doc(userId) : _fb.usersRef.doc(userId);
      await ref.update({
        'isSuspended': true,
        'isBanned': true,
        'isAvailable': isWorker ? false : null,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao banir usuário: ${e.message}');
    }
  }

  // ─── Denúncias ────────────────────────────────────────────────────────────

  Stream<List<ReportModel>> watchAllReports() {
    return _fb.reportsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReportModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<ReportModel>> watchOpenReports() {
    return _fb.reportsRef
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReportModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> resolveReport(String reportId) async {
    try {
      await _fb.reportsRef.doc(reportId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': _fb.uid,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao resolver denúncia: ${e.message}');
    }
  }

  Future<void> dismissReport(String reportId) async {
    try {
      await _fb.reportsRef.doc(reportId).update({
        'status': 'dismissed',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': _fb.uid,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao descartar denúncia: ${e.message}');
    }
  }

  // ─── Avaliações ───────────────────────────────────────────────────────────

  Stream<List<ReviewModel>> watchAllReviews() {
    return _fb.reviewsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> removeReview(String reviewId) async {
    try {
      await _fb.reviewsRef.doc(reviewId).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao remover avaliação: ${e.message}');
    }
  }

  // ─── Pedidos ──────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchAllOrders() {
    return _fb.ordersRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardCounts() async {
    try {
      final results = await Future.wait([
        _fb.usersRef.count().get(),
        _fb.workersRef.count().get(),
        _fb.workersRef
            .where('verificationStatus', isEqualTo: 'pending')
            .count()
            .get(),
        _fb.ordersRef.count().get(),
        _fb.ordersRef.where('status', isEqualTo: 'done').count().get(),
        _fb.ordersRef
            .where('status', isEqualTo: 'cancelled')
            .count()
            .get(),
        _fb.reportsRef.where('status', isEqualTo: 'open').count().get(),
      ]);

      return {
        'totalClients': results[0].count ?? 0,
        'totalWorkers': results[1].count ?? 0,
        'pendingWorkers': results[2].count ?? 0,
        'totalOrders': results[3].count ?? 0,
        'doneOrders': results[4].count ?? 0,
        'cancelledOrders': results[5].count ?? 0,
        'openReports': results[6].count ?? 0,
      };
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao carregar dashboard: ${e.message}');
    }
  }

  // ─── Notificações em massa ────────────────────────────────────────────────

  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String targetGroup, // 'all' | 'clients' | 'workers'
  }) async {
    try {
      await _fb.firestore.collection('broadcast_notifications').add({
        'title': title,
        'body': body,
        'targetGroup': targetGroup,
        'sentBy': _fb.uid,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } on FirebaseException catch (e) {
      throw ServerException('Erro ao enviar notificação: ${e.message}');
    }
  }

  // ─── Log de ações ─────────────────────────────────────────────────────────

  Future<void> logAction(AdminLogModel log) async {
    try {
      await _fb.firestore
          .collection('admin_logs')
          .add(log.toMap());
    } catch (_) {
      // Log silencioso — não bloqueia a ação principal se falhar
    }
  }

  Stream<List<AdminLogModel>> watchAdminLogs() {
    return _fb.firestore
        .collection('admin_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdminLogModel.fromMap(d.data(), d.id))
            .toList());
  }
}
