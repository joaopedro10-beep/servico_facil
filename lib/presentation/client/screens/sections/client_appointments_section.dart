import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/client_controller.dart';
import '../client_home_screen.dart' show CTheme;

/// Tela "Meus Chamados" do cliente.
///
/// Mostra todos os pedidos em 6 abas:
/// Pendentes · Aceitos · Agendados · Em andamento · Concluídos · Cancelados
///
/// Atualiza automaticamente via [ClientController.myOrders] que é
/// alimentado pelo stream Firestore [watchClientOrders].
/// Não usa scheduledAt sem verificar null — corrige o crash anterior.
class ClientAppointmentsSection extends StatefulWidget {
  final ClientController ctrl;
  const ClientAppointmentsSection({super.key, required this.ctrl});

  @override
  State<ClientAppointmentsSection> createState() =>
      _ClientAppointmentsSectionState();
}

class _ClientAppointmentsSectionState
    extends State<ClientAppointmentsSection>
    with SingleTickerProviderStateMixin {

  late final TabController _tab = TabController(length: 6, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header verde + TabBar ──────────────────────────────────────────────
      Container(
        color: CTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meus Chamados',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Badges reativos nas abas
            Obx(() {
              final orders = widget.ctrl.myOrders;

              int count(OrderStatus s) =>
                  orders.where((o) => o.status == s).length;
              int countScheduled() => orders
                  .where((o) =>
                      o.status == OrderStatus.accepted &&
                      o.scheduledAt != null &&
                      o.scheduledAt!.isAfter(DateTime.now()))
                  .length;

              return TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12),
                tabs: [
                  _BadgeTab(
                      label: 'Pendentes',
                      count: count(OrderStatus.pending)),
                  _BadgeTab(
                      label: 'Aceitos',
                      count: count(OrderStatus.accepted) -
                          countScheduled()),
                  _BadgeTab(
                      label: 'Agendados',
                      count: countScheduled()),
                  _BadgeTab(
                      label: 'Em andamento',
                      count: count(OrderStatus.inProgress)),
                  _BadgeTab(
                      label: 'Concluídos',
                      count: count(OrderStatus.done)),
                  _BadgeTab(
                      label: 'Cancelados',
                      count: count(OrderStatus.cancelled)),
                ],
              );
            }),
          ],
        ),
      ),

      // ── Conteúdo das abas ─────────────────────────────────────────────────
      Expanded(
        child: Obx(() {
          final orders = widget.ctrl.myOrders;

          // Listas por status
          final pending    = orders.where((o) => o.status == OrderStatus.pending).toList();
          final accepted   = orders.where((o) =>
              o.status == OrderStatus.accepted &&
              !(o.scheduledAt != null && o.scheduledAt!.isAfter(DateTime.now()))
          ).toList();
          final scheduled  = orders.where((o) =>
              o.status == OrderStatus.accepted &&
              o.scheduledAt != null &&
              o.scheduledAt!.isAfter(DateTime.now())
          ).toList();
          final inProgress = orders.where((o) => o.status == OrderStatus.inProgress).toList();
          final done       = orders.where((o) => o.status == OrderStatus.done).toList();
          final cancelled  = orders.where((o) => o.status == OrderStatus.cancelled).toList();

          // Loading state
          if (widget.ctrl.isLoadingOrders.value && orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          return TabBarView(
            controller: _tab,
            children: [
              _OrderList(
                orders:   pending,
                emptyMsg: 'Nenhum chamado pendente',
                emptyIcon: Icons.hourglass_empty_rounded,
                ctrl: widget.ctrl,
              ),
              _OrderList(
                orders:   accepted,
                emptyMsg: 'Nenhum chamado aceito',
                emptyIcon: Icons.check_circle_outline_rounded,
                ctrl: widget.ctrl,
              ),
              _OrderList(
                orders:   scheduled,
                emptyMsg: 'Nenhum chamado agendado',
                emptyIcon: Icons.calendar_today_outlined,
                ctrl: widget.ctrl,
                showScheduledAt: true,
              ),
              _OrderList(
                orders:   inProgress,
                emptyMsg: 'Nenhum chamado em andamento',
                emptyIcon: Icons.engineering_outlined,
                ctrl: widget.ctrl,
              ),
              _OrderList(
                orders:   done,
                emptyMsg: 'Nenhum chamado concluído',
                emptyIcon: Icons.task_alt_rounded,
                ctrl: widget.ctrl,
              ),
              _OrderList(
                orders:   cancelled,
                emptyMsg: 'Nenhum chamado cancelado',
                emptyIcon: Icons.cancel_outlined,
                ctrl: widget.ctrl,
              ),
            ],
          );
        }),
      ),
    ]);
  }
}

// ─── Tab com badge ────────────────────────────────────────────────────────────
class _BadgeTab extends StatelessWidget {
  final String label;
  final int count;
  const _BadgeTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, overflow: TextOverflow.ellipsis),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Lista de pedidos ─────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMsg;
  final IconData emptyIcon;
  final ClientController ctrl;
  final bool showScheduledAt;

  const _OrderList({
    required this.orders,
    required this.emptyMsg,
    required this.emptyIcon,
    required this.ctrl,
    this.showScheduledAt = false,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, size: 54, color: CTheme.textLight),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: const TextStyle(
                  color: CTheme.textGray, fontSize: 14),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return RefreshIndicator(
      color: CTheme.primary,
      onRefresh: ctrl.reload,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          ctrl: ctrl,
          showScheduledAt: showScheduledAt,
        ),
      ),
    );
  }
}

// ─── Card de pedido ───────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final ClientController ctrl;
  final bool showScheduledAt;

  const _OrderCard({
    required this.order,
    required this.ctrl,
    required this.showScheduledAt,
  });

  // ── Status ────────────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return CTheme.amber;
      case OrderStatus.accepted:
        return order.isScheduled ? CTheme.primary : const Color(0xFF2196F3);
      case OrderStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case OrderStatus.done:
        return CTheme.primary;
      case OrderStatus.cancelled:
        return CTheme.red;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Aguardando profissional';
      case OrderStatus.accepted:
        return order.isScheduled ? 'Agendado' : 'Aceito';
      case OrderStatus.inProgress:
        return 'Em andamento';
      case OrderStatus.done:
        return 'Concluído';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  IconData get _statusIcon {
    switch (order.status) {
      case OrderStatus.pending:    return Icons.hourglass_empty_rounded;
      case OrderStatus.accepted:   return order.isScheduled
          ? Icons.calendar_today_rounded : Icons.check_circle_rounded;
      case OrderStatus.inProgress: return Icons.engineering_rounded;
      case OrderStatus.done:       return Icons.task_alt_rounded;
      case OrderStatus.cancelled:  return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yy', 'pt_BR');
    final timeFmt = DateFormat('HH:mm', 'pt_BR');

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.status == OrderStatus.pending
                ? CTheme.amber.withOpacity(0.4)
                : CTheme.border,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Linha principal ───────────────────────────────────────────
              Row(children: [
                // Avatar do prestador (ou ícone de busca se ainda pendente)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _statusColor.withOpacity(0.12),
                  child: order.status == OrderStatus.pending
                      ? Icon(_statusIcon,
                            color: _statusColor, size: 22)
                      : Text(
                          order.workerName?.isNotEmpty == true
                              ? order.workerName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                              fontSize: 18),
                        ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prestador ou estado de busca
                      Text(
                        order.status == OrderStatus.pending
                            ? 'Procurando profissional...'
                            : (order.workerName ?? 'Profissional'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.serviceCategory,
                        style: const TextStyle(
                            fontSize: 12, color: CTheme.textGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge de status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon,
                        color: _statusColor, size: 11),
                    const SizedBox(width: 4),
                    Text(_statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: _statusColor,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ]),
                ),
              ]),

              const SizedBox(height: 10),

              // ── Descrição ─────────────────────────────────────────────────
              if (order.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    order.description,
                    style: const TextStyle(
                        fontSize: 12, color: CTheme.textGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // ── Infos extras ──────────────────────────────────────────────
              Row(children: [
                // Data de criação
                const Icon(Icons.access_time_rounded,
                    size: 13, color: CTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  'Aberto em ${dateFmt.format(order.createdAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: CTheme.textGray),
                  overflow: TextOverflow.ellipsis,
                ),

                // Data agendada (se houver)
                if (order.scheduledAt != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: CTheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${dateFmt.format(order.scheduledAt!)} às '
                      '${timeFmt.format(order.scheduledAt!)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: CTheme.primary,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ] else
                  const Spacer(),

                // Preço (se definido)
                if (order.price != null)
                  Text(
                    'R\$ ${order.price!.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CTheme.primary),
                  ),
              ]),

              // ── Ações contextuais ─────────────────────────────────────────
              if (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.done) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ctrl.cancelOrder(order),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          foregroundColor: CTheme.red,
                          side: BorderSide(
                              color: CTheme.red.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(
                          AppRoutes.orderDetail, arguments: order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        order.status == OrderStatus.done
                            ? 'Ver detalhes'
                            : 'Acompanhar',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
