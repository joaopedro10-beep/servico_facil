import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/worker_model.dart';

class WorkerHomeController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ── Estado ────────────────────────────────────────────────────────────────
  final worker = Rxn<WorkerModel>();
  final isAvailable = true.obs;
  final isTogglingAvailability = false.obs;

  final allOrders = <OrderModel>[].obs;
  final isLoadingOrders = true.obs;
  StreamSubscription? _ordersSub;
  StreamSubscription? _workerSub;

  // ── Computed ──────────────────────────────────────────────────────────────

  List<OrderModel> get pendingOrders =>
      allOrders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get inProgressOrders =>
      allOrders.where((o) => o.status == OrderStatus.inProgress).toList();

  int get todayOrdersCount {
    final today = DateTime.now();
    return allOrders.where((o) {
      return o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day;
    }).length;
  }

  int get totalCompleted =>
      allOrders.where((o) => o.status == OrderStatus.done).length;

  double get currentRating => worker.value?.avgRating ?? 0;

  /// Quantidade de serviços concluídos por dia nos últimos 7 dias.
  List<int> get last7DaysCompleted {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return allOrders.where((o) {
        return o.status == OrderStatus.done &&
            o.completedAt != null &&
            o.completedAt!.year == day.year &&
            o.completedAt!.month == day.month &&
            o.completedAt!.day == day.day;
      }).length;
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadWorker();
    _startOrderStream();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _workerSub?.cancel();
    super.onClose();
  }

  // ── Worker ────────────────────────────────────────────────────────────────

  /// Public reload — chamado pelo pull-to-refresh
  Future<void> reload() => _loadWorker();

  Future<void> _loadWorker() async {
    final w = await _ds.getWorker(_fb.uid);
    if (w != null) {
      worker.value = w;
      isAvailable.value = w.isAvailable;
    }
  }

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

  // ── Orders ────────────────────────────────────────────────────────────────

  void _startOrderStream() {
    isLoadingOrders.value = true;
    _ordersSub = _ds.watchWorkerOrders(_fb.uid).listen((list) {
      allOrders.assignAll(list);
      isLoadingOrders.value = false;
    }, onError: (_) => isLoadingOrders.value = false);
  }

  Future<void> quickAccept(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.accepted);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Pedido aceito!',
      body: 'Seu pedido de ${order.serviceCategory} foi aceito.',
      type: 'order_update',
      targetId: order.id,
    );
  }

  Future<void> quickRefuse(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.cancelled);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Pedido recusado',
      body: 'O profissional não pôde aceitar seu pedido agora.',
      type: 'order_update',
      targetId: order.id,
    );
  }

  Future<void> quickComplete(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.done);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Serviço concluído!',
      body: 'Que tal avaliar o profissional?',
      type: 'order_update',
      targetId: order.id,
    );
  }
}
