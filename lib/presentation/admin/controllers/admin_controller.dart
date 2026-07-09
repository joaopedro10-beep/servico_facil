import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/admin_datasource.dart';
import '../../../data/models/admin_log_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/worker_model.dart';

class AdminController extends GetxController {
  final AdminDatasource _ds = Get.find<AdminDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─── Navegação entre seções ───────────────────────────────────────────────
  final currentSection = 0.obs;
  // 0=dashboard 1=prestadores 2=clientes 3=pedidos 4=denúncias 5=avaliações 6=logs

  // ─── Dashboard ────────────────────────────────────────────────────────────
  final dashboardCounts = <String, int>{}.obs;
  final isLoadingDashboard = true.obs;

  // ─── Prestadores ──────────────────────────────────────────────────────────
  final pendingWorkers = <WorkerModel>[].obs;
  final allWorkers = <WorkerModel>[].obs;
  final workerTab = 0.obs; // 0=pendentes 1=todos

  // ─── Clientes ─────────────────────────────────────────────────────────────
  final allUsers = <UserModel>[].obs;
  final userSearchResults = <UserModel>[].obs;
  final userSearchQuery = ''.obs;
  final isSearchingUsers = false.obs;

  // ─── Pedidos ──────────────────────────────────────────────────────────────
  final allOrders = <OrderModel>[].obs;

  // ─── Denúncias ────────────────────────────────────────────────────────────
  final allReports = <ReportModel>[].obs;
  final openReports = <ReportModel>[].obs;
  final reportTab = 0.obs; // 0=abertas 1=todas

  // ─── Avaliações ───────────────────────────────────────────────────────────
  final allReviews = <ReviewModel>[].obs;

  // ─── Histórico de ações ───────────────────────────────────────────────────
  final adminLogs = <AdminLogModel>[].obs;

  // ─── UI state ─────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Streams
  final List<StreamSubscription> _subs = [];

  // Admin info
  final adminName = 'Admin'.obs;
  String get _adminName => adminName.value;

  @override
  void onInit() {
    super.onInit();
    _loadAdminInfo();
    _loadDashboard();
    _subscribePendingWorkers();
    _subscribeAllWorkers();
    _subscribeUsers();
    _subscribeOrders();
    _subscribeReports();
    _subscribeReviews();
    _subscribeLogs();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  // ─── Carregamento inicial ─────────────────────────────────────────────────

  Future<void> _loadAdminInfo() async {
    try {
      final uid = _fb.uid;
      // O admin pode estar em users ou ser um usuário especial
      final doc = await _fb.usersRef.doc(uid).get();
      if (doc.exists) {
        adminName.value = doc.data()?['name'] ?? 'Admin';
      }
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    isLoadingDashboard.value = true;
    try {
      final counts = await _ds.getDashboardCounts();
      dashboardCounts.assignAll(counts);
    } catch (_) {
      errorMessage.value = 'Erro ao carregar indicadores.';
    } finally {
      isLoadingDashboard.value = false;
    }
  }

  Future<void> refreshDashboard() => _loadDashboard();

  // ─── Streams ──────────────────────────────────────────────────────────────

  void _subscribePendingWorkers() {
    _subs.add(_ds.watchPendingWorkers().listen(
      (list) => pendingWorkers.assignAll(list),
    ));
  }

  void _subscribeAllWorkers() {
    _subs.add(_ds.watchAllWorkers().listen(
      (list) => allWorkers.assignAll(list),
    ));
  }

  void _subscribeUsers() {
    _subs.add(_ds.watchAllUsers().listen(
      (list) {
        allUsers.assignAll(list);
        if (userSearchQuery.value.isEmpty) {
          userSearchResults.assignAll(list);
        }
      },
    ));
  }

  void _subscribeOrders() {
    _subs.add(_ds.watchAllOrders().listen(
      (list) => allOrders.assignAll(list),
    ));
  }

  void _subscribeReports() {
    _subs.add(_ds.watchOpenReports().listen(
      (list) => openReports.assignAll(list),
    ));
    _subs.add(_ds.watchAllReports().listen(
      (list) => allReports.assignAll(list),
    ));
  }

  void _subscribeReviews() {
    _subs.add(_ds.watchAllReviews().listen(
      (list) => allReviews.assignAll(list),
    ));
  }

  void _subscribeLogs() {
    _subs.add(_ds.watchAdminLogs().listen(
      (list) => adminLogs.assignAll(list),
    ));
  }

  // ─── Prestadores ──────────────────────────────────────────────────────────

  List<WorkerModel> get displayedWorkers =>
      workerTab.value == 0 ? pendingWorkers : allWorkers;

  Future<void> approveWorker(WorkerModel worker) async {
    final confirm = await _confirmDialog(
      title: 'Aprovar prestador',
      content:
          'Deseja aprovar ${worker.name}? Ele passará a aparecer nas buscas e poderá receber solicitações.',
      confirmLabel: 'Aprovar',
      confirmColor: Colors.green,
    );
    if (confirm != true) return;

    _setLoading(true);
    try {
      await _ds.approveWorker(worker.id);
      await _logAction(
        action: AdminActionType.approveWorker,
        targetId: worker.id,
        targetName: worker.name,
      );
      await _loadDashboard();
      _showSuccess('${worker.name} aprovado com sucesso!');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectWorker(WorkerModel worker) async {
    final reason = await _reasonDialog(
      title: 'Rejeitar prestador',
      hint: 'Informe o motivo da rejeição...',
    );
    if (reason == null) return;

    _setLoading(true);
    try {
      await _ds.rejectWorker(worker.id, reason);
      await _logAction(
        action: AdminActionType.rejectWorker,
        targetId: worker.id,
        targetName: worker.name,
        reason: reason,
      );
      await _loadDashboard();
      _showSuccess('Cadastro de ${worker.name} rejeitado.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestDocuments(WorkerModel worker) async {
    final message = await _reasonDialog(
      title: 'Solicitar documentos',
      hint: 'O que está faltando ou precisa ser corrigido?',
    );
    if (message == null) return;

    _setLoading(true);
    try {
      await _ds.requestMoreDocuments(worker.id, message);
      await _logAction(
        action: AdminActionType.requestDocuments,
        targetId: worker.id,
        targetName: worker.name,
        reason: message,
      );
      _showSuccess('Solicitação enviada para ${worker.name}.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Usuários ─────────────────────────────────────────────────────────────

  void searchUsers(String query) {
    userSearchQuery.value = query;
    if (query.trim().isEmpty) {
      userSearchResults.assignAll(allUsers);
      return;
    }
    final q = query.toLowerCase();
    userSearchResults.assignAll(allUsers.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        (u.cpf ?? '').contains(q)));
  }

  Future<void> suspendUser(UserModel user) async {
    final reason = await _reasonDialog(
      title: 'Suspender ${user.name}',
      hint: 'Motivo da suspensão...',
    );
    if (reason == null) return;
    _setLoading(true);
    try {
      await _ds.suspendUser(user.id);
      await _logAction(
        action: AdminActionType.suspendUser,
        targetId: user.id,
        targetName: user.name,
        reason: reason,
      );
      _showSuccess('${user.name} suspenso.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unsuspendUser(UserModel user) async {
    _setLoading(true);
    try {
      await _ds.unsuspendUser(user.id);
      await _logAction(
        action: AdminActionType.unsuspendUser,
        targetId: user.id,
        targetName: user.name,
      );
      _showSuccess('Suspensão de ${user.name} removida.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> banUser(UserModel user) async {
    final reason = await _reasonDialog(
      title: 'Banir ${user.name}',
      hint: 'Motivo do banimento (permanente)...',
    );
    if (reason == null) return;
    final confirm = await _confirmDialog(
      title: 'Confirmar banimento',
      content:
          'Essa ação é permanente. ${user.name} será banido da plataforma.',
      confirmLabel: 'Banir',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    _setLoading(true);
    try {
      await _ds.banUser(user.id, reason);
      await _logAction(
        action: AdminActionType.banUser,
        targetId: user.id,
        targetName: user.name,
        reason: reason,
      );
      _showSuccess('${user.name} banido.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> unsuspendWorker(WorkerModel worker) async {
    _setLoading(true);
    try {
      await _ds.unsuspendUser(worker.id, isWorker: true);
      await _logAction(
        action: AdminActionType.unsuspendUser,
        targetId: worker.id,
        targetName: worker.name,
      );
      _showSuccess('Suspensão removida.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> suspendWorker(WorkerModel worker) async {
    final reason = await _reasonDialog(
      title: 'Suspender ${worker.name}',
      hint: 'Motivo da suspensão...',
    );
    if (reason == null) return;
    _setLoading(true);
    try {
      await _ds.suspendUser(worker.id, isWorker: true);
      await _logAction(
        action: AdminActionType.suspendUser,
        targetId: worker.id,
        targetName: worker.name,
        reason: reason,
      );
      _showSuccess('${worker.name} suspenso.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Denúncias ────────────────────────────────────────────────────────────

  List<ReportModel> get displayedReports =>
      reportTab.value == 0 ? openReports : allReports;

  Future<void> resolveReport(ReportModel report) async {
    _setLoading(true);
    try {
      await _ds.resolveReport(report.id);
      await _logAction(
        action: AdminActionType.resolveReport,
        targetId: report.reportedId,
        targetName: 'Denúncia #${report.id.substring(0, 6)}',
      );
      _showSuccess('Denúncia resolvida.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> dismissReport(ReportModel report) async {
    _setLoading(true);
    try {
      await _ds.dismissReport(report.id);
      await _logAction(
        action: AdminActionType.dismissReport,
        targetId: report.reportedId,
        targetName: 'Denúncia #${report.id.substring(0, 6)}',
      );
      _showSuccess('Denúncia descartada.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Avaliações ───────────────────────────────────────────────────────────

  Future<void> removeReview(ReviewModel review) async {
    final confirm = await _confirmDialog(
      title: 'Remover avaliação',
      content:
          'Deseja remover esta avaliação de ${review.authorName}? Essa ação não pode ser desfeita.',
      confirmLabel: 'Remover',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    _setLoading(true);
    try {
      await _ds.removeReview(review.id);
      await _logAction(
        action: AdminActionType.removeReview,
        targetId: review.targetId,
        targetName: 'Avaliação de ${review.authorName}',
      );
      _showSuccess('Avaliação removida.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Notificação em massa ─────────────────────────────────────────────────

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String targetGroup,
  }) async {
    _setLoading(true);
    try {
      await _ds.sendBroadcastNotification(
          title: title, body: body, targetGroup: targetGroup);
      await _logAction(
        action: AdminActionType.sendNotification,
        targetId: targetGroup,
        targetName: 'Notificação: $title',
      );
      _showSuccess('Notificação enviada para $targetGroup.');
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────


  // ─── Busca global ─────────────────────────────────────────────────────────
  void globalSearch(String query) {
    if (query.trim().isEmpty) {
      userSearchResults.assignAll(allUsers);
      return;
    }
    searchUsers(query);
    currentSection.value = 3;
  }

  Future<void> _logAction({
    required AdminActionType action,
    required String targetId,
    required String targetName,
    String? reason,
  }) async {
    final log = AdminLogModel(
      id: '',
      adminId: _fb.uid,
      adminName: _adminName,
      action: action,
      targetId: targetId,
      targetName: targetName,
      reason: reason,
      createdAt: DateTime.now(),
    );
    await _ds.logAction(log);
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    Color confirmColor = Colors.red,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<String?> _reasonDialog({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Get.back(result: ctrl.text.trim());
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _setLoading(bool v) => isLoading.value = v;

  void _showSuccess(String msg) {
    Get.snackbar(
      'Sucesso',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1D9E75).withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
