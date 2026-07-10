import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

class WorkerDashboardSection extends StatelessWidget {
  final WorkerController ctrl;
  final VoidCallback onMenuTap;
  const WorkerDashboardSection({
    super.key,
    required this.ctrl,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: WTheme.blue,
      onRefresh: ctrl.reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(ctrl: ctrl, onMenuTap: onMenuTap)),
          SliverToBoxAdapter(child: _DashHeader(ctrl: ctrl)),
          SliverToBoxAdapter(child: _StatsGrid(ctrl: ctrl)),
          SliverToBoxAdapter(child: _RequestsList(ctrl: ctrl)),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Top Bar azul ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final WorkerController ctrl;
  final VoidCallback onMenuTap;
  const _TopBar({required this.ctrl, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WTheme.blue,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: onMenuTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        // Logo
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('SF',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Serviço Fácil',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),
        // Badge notificações
        Obx(() {
          final count = ctrl.newOrders.length;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (count > 0)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: WTheme.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(width: 4),
        // Avatar pequeno
        Obx(() {
          final w = ctrl.worker.value;
          final initial =
              w?.name.isNotEmpty == true ? w!.name[0].toUpperCase() : 'P';
          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: w?.photoUrl != null
                ? NetworkImage(w!.photoUrl!)
                : null,
            child: w?.photoUrl == null
                ? Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800))
                : null,
          );
        }),
      ]),
    );
  }
}

// ─── Saudação + status online ─────────────────────────────────────────────────
class _DashHeader extends StatelessWidget {
  final WorkerController ctrl;
  const _DashHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Obx(() {
        final w = ctrl.worker.value;
        final first = w?.name.split(' ').first ?? 'Prestador';
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Olá, $first! 👋',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: WTheme.textDark),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            // Status online pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ctrl.isAvailable.value
                    ? WTheme.greenLight.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ctrl.isAvailable.value
                      ? WTheme.greenLight.withOpacity(0.4)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: ctrl.isAvailable.value
                        ? WTheme.greenLight
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  ctrl.isAvailable.value ? 'Online' : 'Offline',
                  style: TextStyle(
                      color: ctrl.isAvailable.value
                          ? WTheme.green
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            ctrl.isAvailable.value
                ? 'Você está disponível para receber novos serviços.'
                : 'Você está indisponível no momento.',
            style: const TextStyle(
                fontSize: 13, color: WTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 2,
          ),
        ]);
      }),
    );
  }
}

// ─── Grid de 4 cards de stats ─────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final WorkerController ctrl;
  const _StatsGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.receipt_long_outlined,
              label: 'Novas solicitações',
              value: '${ctrl.newOrders.length}',
              sub: 'Você está disponível',
              iconBg: WTheme.blueLight,
              iconColor: WTheme.blue,
              valueColor: WTheme.blue,
            ),
            _StatCard(
              icon: Icons.engineering_outlined,
              label: 'Em andamento',
              value: '${ctrl.activeOrders.length}',
              sub: 'Serviços ativos',
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              valueColor: const Color(0xFFE65100),
            ),
            _StatCard(
              icon: Icons.star_rounded,
              label: 'Avaliação média',
              value: ctrl.avgRating > 0
                  ? ctrl.avgRating.toStringAsFixed(1)
                  : '—',
              sub: '⭐⭐⭐⭐⭐',
              iconBg: const Color(0xFFFFF8E1),
              iconColor: Colors.amber,
              valueColor: Colors.amber.shade700,
              isStar: ctrl.avgRating > 0,
              starValue: ctrl.avgRating,
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ganhos do mês',
              value: money.format(ctrl.filteredEarnings
                  .fold(0.0, (s, o) => s + (o.price ?? 0))),
              sub: 'Total recebido',
              iconBg: const Color(0xFFE8F5E9),
              iconColor: WTheme.green,
              valueColor: WTheme.green,
              smallValue: true,
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;
  final bool isStar;
  final double starValue;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
    this.isStar = false,
    this.starValue = 0,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: smallValue ? 16 : 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor),
                overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: WTheme.textGray),
                overflow: TextOverflow.ellipsis, maxLines: 2),
          ]),
        ],
      ),
    );
  }
}

// ─── Lista de solicitações recebidas ─────────────────────────────────────────
class _RequestsList extends StatelessWidget {
  final WorkerController ctrl;
  const _RequestsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.newOrders;
      if (orders.isEmpty && ctrl.isLoadingOrders.value) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Solicitações recebidas',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: WTheme.textDark),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text('Ver todas',
                  style: TextStyle(
                      fontSize: 12,
                      color: WTheme.blue,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WTheme.border),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle_rounded,
                    color: WTheme.green, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Sem novas solicitações no momento.',
                      style: TextStyle(
                          color: WTheme.textGray, fontSize: 13),
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                ),
              ]),
            )
          else
            ...orders.take(3).map((o) => _RequestCard(order: o, ctrl: ctrl)),
        ]),
      );
    });
  }
}

class _RequestCard extends StatelessWidget {
  final OrderModel order;
  final WorkerController ctrl;
  const _RequestCard({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Foto + info cliente
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
            // Distância (placeholder)
            const Text('2,5 km',
                style: TextStyle(
                    fontSize: 12, color: WTheme.blue,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          // Localização
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: WTheme.textGray),
            const SizedBox(width: 4),
            Expanded(
              child: Text(order.address.fullAddress,
                  style: const TextStyle(
                      fontSize: 12, color: WTheme.textGray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          // Horário
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: WTheme.textGray),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                DateFormat('dd/MM · HH:mm', 'pt_BR')
                    .format(order.scheduledAt),
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
          const SizedBox(height: 12),
          // Botões
          Row(children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.blue,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => ctrl.acceptOrder(order),
                child: const Text('Aceitar',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  side: const BorderSide(color: WTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => Get.toNamed(AppRoutes.orderDetail,
                    arguments: {'order': order, 'isWorker': true}),
                child: const Text('Detalhes',
                    style: TextStyle(
                        fontSize: 13, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  foregroundColor: WTheme.red,
                  side: const BorderSide(color: WTheme.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => ctrl.refuseOrder(order),
                child: const Text('Recusar',
                    style: TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
