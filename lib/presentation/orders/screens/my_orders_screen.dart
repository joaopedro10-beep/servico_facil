import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/order_model.dart';
import '../controllers/order_controller.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, this.isWorker = false});
  final bool isWorker;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OrderController ctrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    ctrl = Get.find<OrderController>();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ctrl.myOrdersTab.value = _tabController.index;
        ctrl.selectedStatusFilter.value = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isWorker) {
        ctrl.loadWorkerOrders();
      } else {
        ctrl.loadClientOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWorker ? 'Meus serviços' : 'Meus pedidos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Ativos'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoadingOrders.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final orders = ctrl.filteredOrdersFor(isWorker: widget.isWorker);

        return Column(
          children: [
            _buildStatusFilter(),
            Expanded(
              child: orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: orders.length,
                      itemBuilder: (_, i) => _OrderCard(
                        order: orders[i],
                        isWorker: widget.isWorker,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusFilter() {
    final isActive = ctrl.myOrdersTab.value == 0;
    final activeStatuses = isActive
        ? [OrderStatus.pending, OrderStatus.accepted, OrderStatus.inProgress]
        : [OrderStatus.done, OrderStatus.cancelled];

    return Obx(() => SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _StatusFilterChip(
                label: 'Todos',
                color: AppColors.textSecondary,
                selected: ctrl.selectedStatusFilter.value == null,
                onTap: () => ctrl.selectedStatusFilter.value = null,
              ),
              ...activeStatuses.map((s) => _StatusFilterChip(
                    label: _statusLabel(s),
                    color: _statusColor(s),
                    selected: ctrl.selectedStatusFilter.value == s,
                    onTap: () => ctrl.selectedStatusFilter.value =
                        ctrl.selectedStatusFilter.value == s ? null : s,
                  )),
            ],
          ),
        ));
  }

  Widget _buildEmptyState() {
    final isActive = ctrl.myOrdersTab.value == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.inbox_outlined : Icons.history_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Nenhum pedido ativo' : 'Nenhum pedido no histórico',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Seus pedidos ativos aparecerão aqui.'
                  : 'Pedidos concluídos e cancelados aparecem aqui.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de pedido ───────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.isWorker});
  final OrderModel order;
  final bool isWorker;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy · HH:mm', 'pt_BR');
    final color = _statusColor(order.status);

    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.orderDetail,
        arguments: {'order': order, 'isWorker': isWorker},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Status header
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(order.status),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmt.format(order.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handyman_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.serviceCategory,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          isWorker
                              ? (order.clientName ?? 'Cliente')
                              : (order.workerName ?? 'Profissional'),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.description.length > 60
                              ? '${order.description.substring(0, 60)}...'
                              : order.description,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip de filtro ───────────────────────────────────────────────────────────

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _statusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:     return 'Pendente';
    case OrderStatus.accepted:    return 'Aceito';
    case OrderStatus.arrived:     return 'Chegou ao local';
    case OrderStatus.inProgress:  return 'Em andamento';
    case OrderStatus.done:        return 'Concluído';
    case OrderStatus.cancelled:   return 'Cancelado';
  }
}

Color _statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:     return AppColors.statusPending;
    case OrderStatus.accepted:    return AppColors.statusAccepted;
    case OrderStatus.arrived:     return AppColors.statusAccepted;
    case OrderStatus.inProgress:  return AppColors.statusInProgress;
    case OrderStatus.done:        return AppColors.statusDone;
    case OrderStatus.cancelled:   return AppColors.statusCancelled;
  }
}
