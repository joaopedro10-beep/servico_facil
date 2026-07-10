import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class WorkerController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─── Estado geral ─────────────────────────────────────────────────────────
  final worker = Rxn<WorkerModel>();
  final isAvailable = true.obs;
  final isTogglingAvailability = false.obs;

  // ─── Pedidos ──────────────────────────────────────────────────────────────
  final allOrders = <OrderModel>[].obs;
  final isLoadingOrders = true.obs;

  // ─── Avaliações ───────────────────────────────────────────────────────────
  final reviews = <ReviewModel>[].obs;

  // ─── Ganhos ───────────────────────────────────────────────────────────────
  final earningsPeriod = 'month'.obs; // 'today' | 'week' | 'month' | 'year'

  // ─── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription? _ordersSub;
  StreamSubscription? _reviewsSub;
  StreamSubscription? _workerSub;

  // ─── Computed: listas de pedidos por status ───────────────────────────────
  List<OrderModel> get newOrders =>
      allOrders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get acceptedOrders =>
      allOrders.where((o) => o.status == OrderStatus.accepted).toList();

  List<OrderModel> get inProgressOrders =>
      allOrders.where((o) => o.status == OrderStatus.inProgress).toList();

  List<OrderModel> get activeOrders => allOrders
      .where((o) =>
          o.status == OrderStatus.accepted ||
          o.status == OrderStatus.inProgress)
      .toList();

  List<OrderModel> get doneOrders =>
      allOrders.where((o) => o.status == OrderStatus.done).toList();

  List<OrderModel> get cancelledOrders =>
      allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

  // ─── Computed: dashboard stats ────────────────────────────────────────────
  int get todayOrders {
    final t = DateTime.now();
    return allOrders
        .where((o) =>
            o.createdAt.year == t.year &&
            o.createdAt.month == t.month &&
            o.createdAt.day == t.day)
        .length;
  }

  int get totalCompleted => doneOrders.length;

  double get avgRating => worker.value?.avgRating ?? 0.0;

  // ─── Computed: ganhos ─────────────────────────────────────────────────────
  List<OrderModel> get filteredEarnings {
    final done = doneOrders;
    final now = DateTime.now();
    switch (earningsPeriod.value) {
      case 'today':
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).toList();
      case 'week':
        return done
            .where((o) =>
                now.difference(o.completedAt ?? o.updatedAt).inDays <= 7)
            .toList();
      case 'year':
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year;
        }).toList();
      default: // month
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year && d.month == now.month;
        }).toList();
    }
  }

  double get totalEarnings =>
      filteredEarnings.fold(0.0, (s, o) => s + (o.price ?? 0));

  /// Ganhos por mês (últimos 6 meses para o gráfico)
  List<double> get earningsByMonth {
    final now = DateTime.now();
    return List.generate(6, (i) {
      int m = now.month - (5 - i);
      int y = now.year;
      if (m <= 0) {
        m += 12;
        y--;
      }
      return doneOrders
          .where((o) {
            final d = o.completedAt ?? o.updatedAt;
            return d.year == y && d.month == m;
          })
          .fold(0.0, (s, o) => s + (o.price ?? 0));
    });
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadWorker();
    _startOrdersStream();
    _startReviewsStream();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _reviewsSub?.cancel();
    _workerSub?.cancel();
    super.onClose();
  }

  // ─── Carregamento ─────────────────────────────────────────────────────────
  Future<void> reload() => _loadWorker();

  Future<void> _loadWorker() async {
    try {
      final w = await _ds.getWorker(_fb.uid);
      if (w != null) {
        worker.value = w;
        isAvailable.value = w.isAvailable;
      }
    } catch (_) {}
  }

  void _startOrdersStream() {
    isLoadingOrders.value = true;
    _ordersSub = _ds.watchWorkerOrders(_fb.uid).listen(
      (list) {
        allOrders.assignAll(list);
        isLoadingOrders.value = false;
      },
      onError: (_) => isLoadingOrders.value = false,
    );
  }

  void _startReviewsStream() {
    _reviewsSub = _ds.watchReviews(_fb.uid).listen(
      (list) => reviews.assignAll(list),
    );
  }

  // ─── Disponibilidade ──────────────────────────────────────────────────────
  Future<void> toggleAvailability(bool value) async {
    isTogglingAvailability.value = true;
    try {
      await _ds.updateWorker(_fb.uid, {'isAvailable': value});
      isAvailable.value = value;
      worker.value = worker.value?.copyWith(isAvailable: value);
    } catch (_) {
      isAvailable.value = !value;
    } finally {
      isTogglingAvailability.value = false;
    }
  }

  // ─── Ações rápidas de pedido ──────────────────────────────────────────────
  Future<void> acceptOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.accepted);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Pedido aceito!',
      body: 'Seu pedido de ${order.serviceCategory} foi aceito.',
      type: 'order_update',
      targetId: order.id,
    );
  }

  Future<void> refuseOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.cancelled);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Pedido recusado',
      body: 'O profissional não pôde aceitar seu pedido agora.',
      type: 'order_update',
      targetId: order.id,
    );
  }

  Future<void> startOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.inProgress);
  }

  Future<void> completeOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.done);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Serviço concluído!',
      body: 'Que tal avaliar o profissional?',
      type: 'order_update',
      targetId: order.id,
    );
  }

  // ─── Navegação ────────────────────────────────────────────────────────────
  void goToEdit() => Get.toNamed(AppRoutes.editWorkerProfile);

  void goToChat(String orderId) =>
      Get.toNamed(AppRoutes.chat, arguments: orderId);

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sair',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = Get.find<AuthRepositoryImpl>();
    await repo.signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
