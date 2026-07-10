import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../client_home_screen.dart' show CTheme;
import '../../controllers/client_controller.dart';

class ClientHomeSection extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onMenuTap;
  final VoidCallback onSolicitar;
  const ClientHomeSection({
    super.key,
    required this.ctrl,
    required this.onMenuTap,
    required this.onSolicitar,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CTheme.primary,
      onRefresh: ctrl.reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(ctrl: ctrl, onMenuTap: onMenuTap)),
          SliverToBoxAdapter(child: _Greeting(ctrl: ctrl)),
          SliverToBoxAdapter(child: _ActiveOrderBanner(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SolicitarButton(ctrl: ctrl, onTap: onSolicitar)),
          SliverToBoxAdapter(child: _CategoriesGrid(ctrl: ctrl)),
          SliverToBoxAdapter(child: _RecentOrders(ctrl: ctrl)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onMenuTap;
  const _TopBar({required this.ctrl, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CTheme.primary,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: onMenuTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Serviço Fácil',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        Obx(() {
          final count = ctrl.notificationCount.value;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: () => Get.toNamed(AppRoutes.notifications),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (count > 0)
              Positioned(right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: CTheme.red, shape: BoxShape.circle),
                  child: Center(child: Text('$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800))),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}

// ─── Saudação ─────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final ClientController ctrl;
  const _Greeting({required this.ctrl});

  String get _hour {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Obx(() {
        final name = ctrl.currentUser.value?.name.split(' ').first
            ?? ctrl.firstName;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$_hour, $name! 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: CTheme.textDark),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 4),
          const Text('Encontre o profissional ideal para você.',
              style: TextStyle(fontSize: 13, color: CTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 2),
        ]);
      }),
    );
  }
}

// ─── Banner de pedido ativo ───────────────────────────────────────────────────
class _ActiveOrderBanner extends StatelessWidget {
  final ClientController ctrl;
  const _ActiveOrderBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = ctrl.latestActiveOrder;
      if (active == null) return const SizedBox.shrink();

      Color statusColor;
      String statusText;
      IconData statusIcon;

      switch (active.status) {
        case OrderStatus.pending:
          statusColor = CTheme.amber;
          statusText  = 'Buscando profissional...';
          statusIcon  = Icons.search_rounded;
          break;
        case OrderStatus.accepted:
          statusColor = CTheme.primary;
          statusText  = 'Profissional a caminho!';
          statusIcon  = Icons.directions_run_rounded;
          break;
        case OrderStatus.inProgress:
          statusColor = const Color(0xFF8B5CF6);
          statusText  = 'Serviço em andamento';
          statusIcon  = Icons.engineering_rounded;
          break;
        default:
          return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: active),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText,
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 14, color: statusColor),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    Text(active.serviceCategory,
                        style: const TextStyle(fontSize: 12, color: CTheme.textGray),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded, color: statusColor),
          ]),
        ),
      );
    });
  }
}

// ─── Botão Solicitar Serviço ──────────────────────────────────────────────────
class _SolicitarButton extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onTap;
  const _SolicitarButton({required this.ctrl, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: CTheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CTheme.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Solicitar Serviço',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grid de categorias ───────────────────────────────────────────────────────
class _CategoriesGrid extends StatelessWidget {
  final ClientController ctrl;
  const _CategoriesGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Expanded(
            child: Text('Categorias',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: CTheme.textDark),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: serviceCategories.map((cat) {
            return Obx(() {
              final sel = ctrl.selectedCategory.value == cat.name;
              return GestureDetector(
                onTap: () => ctrl.selectCategory(cat.name),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: sel ? CTheme.primary : CTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: sel ? null
                            : Border.all(color: CTheme.border),
                      ),
                      child: Center(
                        child: Icon(cat.icon,
                            color: sel ? Colors.white : CTheme.primary,
                            size: 24),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(cat.name,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel
                                ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? CTheme.primary : CTheme.textGray),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, maxLines: 2),
                  ],
                ),
              );
            });
          }).toList(),
        ),
      ]),
    );
  }
}

// ─── Histórico recente ────────────────────────────────────────────────────────
class _RecentOrders extends StatelessWidget {
  final ClientController ctrl;
  const _RecentOrders({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recent = ctrl.doneOrders.take(3).toList();
      if (recent.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Serviços recentes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: CTheme.textDark),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 10),
          ...recent.map((o) => _RecentCard(order: o, ctrl: ctrl)),
        ]),
      );
    });
  }
}

class _RecentCard extends StatelessWidget {
  final OrderModel order;
  final ClientController ctrl;
  const _RecentCard({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy · HH:mm', 'pt_BR');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CTheme.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: CTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.serviceCategory,
                style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(fmt.format(order.completedAt ?? order.updatedAt),
                style: const TextStyle(fontSize: 11, color: CTheme.textGray),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ]),
        ),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.rateService, arguments: order),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Avaliar',
                style: TextStyle(fontSize: 11, color: CTheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
