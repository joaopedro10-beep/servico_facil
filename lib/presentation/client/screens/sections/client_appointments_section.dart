// ═══════════════════════════════════════════════════════════════════════════
// BUSCAR
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/client_controller.dart';
import '../client_home_screen.dart' show CTheme;

class ClientAppointmentsSection extends StatefulWidget {
  final ClientController ctrl;
  const ClientAppointmentsSection({super.key, required this.ctrl});

  @override
  State<ClientAppointmentsSection> createState() =>
      _ClientAppointmentsSectionState();
}

class _ClientAppointmentsSectionState extends State<ClientAppointmentsSection>
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
      Container(
        color: CTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Meus Agendamentos',
              style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Concluídos'),
              Tab(text: 'Cancelados'),
            ],
          ),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final all    = widget.ctrl.myOrders;
          final done   = widget.ctrl.doneOrders;
          final cancelled = all
              .where((o) => o.status == OrderStatus.cancelled)
              .toList();
          return TabBarView(
            controller: _tab,
            children: [
              _OrderList(orders: all,       emptyMsg: 'Nenhum agendamento'),
              _OrderList(orders: done,      emptyMsg: 'Nenhum serviço concluído'),
              _OrderList(orders: cancelled, emptyMsg: 'Nenhum cancelado'),
            ],
          );
        }),
      ),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMsg;
  const _OrderList({required this.orders, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined,
              size: 54, color: CTheme.textLight),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: const TextStyle(color: CTheme.textGray, fontSize: 14)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AppointmentCard(order: orders[i]),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final OrderModel order;
  const _AppointmentCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return CTheme.amber;
      case OrderStatus.accepted:   return CTheme.blue;
      case OrderStatus.inProgress: return const Color(0xFF8B5CF6);
      case OrderStatus.done: return CTheme.primary;
      case OrderStatus.cancelled:  return CTheme.red;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:    return 'Pendente';
      case OrderStatus.accepted:   return 'Aceito';
      case OrderStatus.inProgress: return 'Em andamento';
      case OrderStatus.done:       return 'Concluído';
      case OrderStatus.cancelled:  return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR');
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: CTheme.blueLight,
              child: Text(
                order.workerName?.isNotEmpty == true
                    ? order.workerName![0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: CTheme.blue,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.workerName ?? 'Prestador',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(order.serviceCategory,
                      style: const TextStyle(
                          fontSize: 13, color: CTheme.textGray),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(children: [
                    const Icon(Icons.attach_money_rounded,
                        size: 13, color: CTheme.textLight),
                    Text(
                      order.price != null
                          ? 'R\$ ${order.price!.toStringAsFixed(2).replaceAll('.', ',')}'
                          : '—',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: CTheme.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(fmt.format(order.scheduledAt),
                          style: const TextStyle(
                              fontSize: 11, color: CTheme.textGray),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(
                            fontSize: 10, color: _statusColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: CTheme.textLight, size: 20),
          ]),
        ),
      ),
    );
  }
}


