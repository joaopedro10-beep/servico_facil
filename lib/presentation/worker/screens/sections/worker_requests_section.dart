import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

class WorkerRequestsSection extends StatefulWidget {
  final WorkerController ctrl;
  const WorkerRequestsSection({super.key, required this.ctrl});

  @override
  State<WorkerRequestsSection> createState() => _WorkerRequestsSectionState();
}

class _WorkerRequestsSectionState extends State<WorkerRequestsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: WTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Solicitações',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Obx(() => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Novas',
                            overflow: TextOverflow.ellipsis),
                        if (widget.ctrl.incomingOrders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WTheme.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.ctrl.incomingOrders.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
              const Tab(text: 'Aceitas'),
              const Tab(text: 'Recusadas'),
            ],
          ),
        ]),
      ),

      // Conteúdo
      Expanded(
        child: Obx(() {
          // Toca os observáveis para o Obx reagir a ambos os streams
          widget.ctrl.allOrders.length;
          widget.ctrl.availableOrders.length;

          // CORREÇÃO: "Novas" agora inclui pedidos disponíveis da
          // plataforma (workerId == '') — antes só mostrava pedidos já
          // vinculados, e as solicitações dos clientes nunca apareciam.
          final novo = widget.ctrl.incomingOrders;
          final aceitas = widget.ctrl.acceptedOrders +
              widget.ctrl.inProgressOrders +
              widget.ctrl.doneOrders;
          final recusadas = widget.ctrl.cancelledOrders;
          return TabBarView(
            controller: _tab,
            children: [
              _OrderList(
                orders: novo,
                ctrl: widget.ctrl,
                emptyMsg: 'Nenhuma nova solicitação',
                emptyIcon: Icons.receipt_long_outlined,
                showActions: true,
              ),
              _OrderList(
                orders: aceitas,
                ctrl: widget.ctrl,
                emptyMsg: 'Nenhuma solicitação aceita',
                emptyIcon: Icons.check_circle_outline,
              ),
              _OrderList(
                orders: recusadas,
                ctrl: widget.ctrl,
                emptyMsg: 'Nenhuma solicitação recusada',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          );
        }),
      ),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final WorkerController ctrl;
  final String emptyMsg;
  final IconData emptyIcon;
  final bool showActions;

  const _OrderList({
    required this.orders,
    required this.ctrl,
    required this.emptyMsg,
    required this.emptyIcon,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, size: 54, color: WTheme.textLight),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: const TextStyle(
                  color: WTheme.textGray, fontSize: 14),
              textAlign: TextAlign.center),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        order: orders[i],
        ctrl: ctrl,
        showActions: showActions,
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final OrderModel order;
  final WorkerController ctrl;
  final bool showActions;
  const _RequestCard({
    required this.order,
    required this.ctrl,
    required this.showActions,
  });

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return WTheme.amber;
      case OrderStatus.accepted:   return WTheme.blue;
      case OrderStatus.arrived:    return WTheme.blue;
      case OrderStatus.inProgress: return WTheme.purple;
      case OrderStatus.done:       return WTheme.green;
      case OrderStatus.cancelled:  return WTheme.red;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:    return 'Pendente';
      case OrderStatus.accepted:   return 'Aceito';
      case OrderStatus.arrived:    return 'No local';
      case OrderStatus.inProgress: return 'Em andamento';
      case OrderStatus.done:       return 'Concluído';
      case OrderStatus.cancelled:  return 'Recusado';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pendente → abre a tela de solicitação (apenas Aceitar/Recusar).
    // Em atendimento → retoma a tela de navegação estilo 99.
    final isPendingRequest = order.status == OrderStatus.pending;
    final isOngoing = order.status == OrderStatus.accepted ||
        order.status == OrderStatus.arrived ||
        order.status == OrderStatus.inProgress;

    void open() {
      if (isPendingRequest) {
        Get.toNamed(AppRoutes.workerRequestDetail,
            arguments: {'order': order});
      } else if (isOngoing) {
        Get.toNamed(AppRoutes.workerNavigation,
            arguments: {'orderId': order.id});
      } else {
        Get.toNamed(AppRoutes.orderDetail,
            arguments: {'order': order, 'isWorker': true});
      }
    }

    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: WTheme.blue.withOpacity(0.1),
              child: Text(
                order.clientName?.isNotEmpty == true
                    ? order.clientName![0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: WTheme.blue, fontSize: 17),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.clientName ?? 'Cliente',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(order.serviceCategory,
                      style: const TextStyle(
                          fontSize: 12, color: WTheme.textGray),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: _statusColor,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: WTheme.textLight),
            const SizedBox(width: 4),
            Expanded(
              child: Text(order.address.fullAddress,
                  style: const TextStyle(
                      fontSize: 12, color: WTheme.textGray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.access_time,
                size: 13, color: WTheme.textLight),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR')
                    .format(order.scheduledAt ?? DateTime.now()),
                style: const TextStyle(
                    fontSize: 12, color: WTheme.textGray),
                overflow: TextOverflow.ellipsis, maxLines: 1,
              ),
            ),
            if (order.price != null)
              Text(
                'R\$ ${order.price!.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: WTheme.blue),
              ),
          ]),
          if (order.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(order.description,
                style: const TextStyle(
                    fontSize: 12, color: WTheme.textGray),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (showActions && isPendingRequest) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.blue,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: open,
                icon: const Icon(Icons.open_in_new_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Ver solicitação',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          if (isOngoing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: open,
                icon: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Continuar atendimento',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
      ),
    );
  }
}
