import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Dashboard completo estilo iFood/Uber Driver.
/// Exibe em tempo real via Obx:
///   • Saudação + status online/offline
///   • Cards de serviços (hoje / semana / mês / total concluídos)
///   • Cards de receita (hoje / semana / mês / total)
///   • Avaliação média + cancelados
///   • Gráfico de barras — serviços por mês (6 meses)
///   • Gráfico de barras — receita por mês (6 meses)
///   • Lista dos últimos serviços concluídos
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
      color: WTheme.primary,
      onRefresh: ctrl.reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _TopBar(ctrl: ctrl, onMenuTap: onMenuTap)),
          SliverToBoxAdapter(child: _DashHeader(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Serviços')),
          SliverToBoxAdapter(child: _ServicesRow(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Receita')),
          SliverToBoxAdapter(child: _EarningsRow(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Desempenho')),
          SliverToBoxAdapter(child: _PerformanceRow(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Serviços por mês')),
          SliverToBoxAdapter(child: _MonthlyServicesChart(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Receita por mês')),
          SliverToBoxAdapter(child: _MonthlyEarningsChart(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SectionTitle('Últimos serviços')),
          SliverToBoxAdapter(child: _RecentServices(ctrl: ctrl)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final WorkerController ctrl;
  final VoidCallback onMenuTap;
  const _TopBar({required this.ctrl, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WTheme.primary,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: onMenuTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Serviço Fácil',
              style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        // Badge de novas solicitações
        Obx(() {
          final count = ctrl.incomingOrders.length;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              // CORREÇÃO: o sino não fazia nada — agora abre as notificações
              onPressed: () => Get.toNamed(AppRoutes.notifications),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (count > 0)
              Positioned(right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: WTheme.red, shape: BoxShape.circle),
                  child: Center(child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800))),
                ),
              ),
          ]);
        }),
        const SizedBox(width: 4),
        Obx(() {
          final w = ctrl.worker.value;
          final initial = w?.name.isNotEmpty == true
              ? w!.name[0].toUpperCase() : 'P';
          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: w?.photoUrl != null
                ? NetworkImage(w!.photoUrl!) : null,
            child: w?.photoUrl == null
                ? Text(initial, style: const TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w800))
                : null,
          );
        }),
      ]),
    );
  }
}

// ─── Header: saudação + toggle online ────────────────────────────────────────
class _DashHeader extends StatelessWidget {
  final WorkerController ctrl;
  const _DashHeader({required this.ctrl});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Obx(() {
        final w     = ctrl.worker.value;
        final first = w?.name.split(' ').first ?? 'Prestador';
        final online = ctrl.isAvailable.value;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('$_greeting, $first! 👋',
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w700, color: WTheme.textDark),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            // Toggle online/offline
            GestureDetector(
              onTap: () => ctrl.toggleAvailability(!online),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: online
                      ? WTheme.primary.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: online
                        ? WTheme.primary.withOpacity(0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: online ? WTheme.greenLight : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(online ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: online ? WTheme.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            online
                ? 'Você está disponível para receber novos chamados.'
                : 'Você está offline. Ative para receber chamados.',
            style: const TextStyle(fontSize: 13, color: WTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 2,
          ),
        ]);
      }),
    );
  }
}

// ─── Título de seção ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: WTheme.textDark),
          overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

// ─── Serviços: hoje / semana / mês / total ────────────────────────────────────
class _ServicesRow extends StatelessWidget {
  final WorkerController ctrl;
  const _ServicesRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _BigCard(
            icon: Icons.today_rounded,
            label: 'Hoje',
            value: '${ctrl.todayOrders}',
            color: WTheme.primary,
            bg: WTheme.primaryLight,
          )),
          const SizedBox(width: 10),
          Expanded(child: _BigCard(
            icon: Icons.date_range_rounded,
            label: 'Semana',
            value: '${ctrl.weekOrders}',
            color: const Color(0xFF6A1B9A),
            bg: const Color(0xFFF3E5F5),
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _BigCard(
            icon: Icons.calendar_month_rounded,
            label: 'Mês',
            value: '${ctrl.monthOrders}',
            color: const Color(0xFF0277BD),
            bg: const Color(0xFFE1F5FE),
          )),
          const SizedBox(width: 10),
          Expanded(child: _BigCard(
            icon: Icons.task_alt_rounded,
            label: 'Total concluídos',
            value: '${ctrl.totalCompleted}',
            color: WTheme.green,
            bg: const Color(0xFFE8F5E9),
          )),
        ]),
      ]),
    ));
  }
}

// ─── Receita: hoje / semana / mês / total ─────────────────────────────────────
class _EarningsRow extends StatelessWidget {
  final WorkerController ctrl;
  const _EarningsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // Card destaque — total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [WTheme.primary, WTheme.primaryDark]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Receita total acumulada',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(money.format(ctrl.earningsTotal),
                style: const TextStyle(color: Colors.white,
                    fontSize: 30, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis, maxLines: 1),
            const SizedBox(height: 2),
            Text('${ctrl.totalCompleted} serviços concluídos',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _EarningCard(
              label: 'Hoje',
              value: money.format(ctrl.earningsToday),
              icon: Icons.wb_sunny_rounded,
              color: WTheme.amber)),
          const SizedBox(width: 10),
          Expanded(child: _EarningCard(
              label: 'Semana',
              value: money.format(ctrl.earningsWeek),
              icon: Icons.view_week_rounded,
              color: WTheme.primary)),
          const SizedBox(width: 10),
          Expanded(child: _EarningCard(
              label: 'Mês',
              value: money.format(ctrl.earningsMonth),
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF6A1B9A))),
        ]),
      ]),
    ));
  }
}

// ─── Desempenho: avaliação + cancelados ───────────────────────────────────────
class _PerformanceRow extends StatelessWidget {
  final WorkerController ctrl;
  const _PerformanceRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final avg       = ctrl.avgRating;
      final total     = ctrl.worker.value?.totalReviews ?? 0;
      final cancelled = ctrl.cancelledOrders.length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          // Avaliação média
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WTheme.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000),
                      blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
              child: Column(children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 30),
                const SizedBox(height: 6),
                Text(avg > 0 ? avg.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: WTheme.textDark),
                    overflow: TextOverflow.ellipsis),
                Text('Avaliação média',
                    style: const TextStyle(
                        fontSize: 11, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
                if (total > 0)
                  Text('$total avaliações',
                      style: const TextStyle(
                          fontSize: 10, color: WTheme.textLight),
                      overflow: TextOverflow.ellipsis),
                if (avg > 0) ...[
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber, size: 12,
                      ))),
                ],
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // Taxa de conclusão
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WTheme.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000),
                      blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
              child: Column(children: [
                Icon(Icons.cancel_outlined,
                    color: WTheme.red.withOpacity(0.8), size: 30),
                const SizedBox(height: 6),
                Text('$cancelled',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: WTheme.red),
                    overflow: TextOverflow.ellipsis),
                const Text('Cancelados',
                    style: TextStyle(fontSize: 11, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                // Taxa de conclusão
                Builder(builder: (_) {
                  final total2 = ctrl.totalCompleted + cancelled;
                  final rate   = total2 > 0
                      ? (ctrl.totalCompleted / total2 * 100).round()
                      : 0;
                  return Column(children: [
                    Text('$rate% conclusão',
                        style: const TextStyle(
                            fontSize: 11, color: WTheme.textLight),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate / 100,
                        backgroundColor: WTheme.border,
                        valueColor: AlwaysStoppedAnimation(
                            rate >= 80 ? WTheme.green : WTheme.amber),
                        minHeight: 5,
                      ),
                    ),
                  ]);
                }),
              ]),
            ),
          ),
        ]),
      );
    });
  }
}

// ─── Gráfico: serviços por mês ────────────────────────────────────────────────
class _MonthlyServicesChart extends StatelessWidget {
  final WorkerController ctrl;
  const _MonthlyServicesChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final now = DateTime.now();
      final counts = List.generate(6, (i) {
        int m = now.month - (5 - i);
        int y = now.year;
        if (m <= 0) { m += 12; y--; }
        return ctrl.doneOrders.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == y && d.month == m;
        }).length.toDouble();
      });
      final maxY = counts.fold(0.0, (a, b) => a > b ? a : b) + 1;

      return _ChartCard(
        child: BarChart(BarChartData(
          maxY: maxY < 3 ? 3 : maxY,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 24, interval: 1,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 9, color: WTheme.textGray)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                int m = now.month - (5 - v.toInt());
                if (m <= 0) m += 12;
                return Text(
                    DateFormat.MMM('pt_BR').format(DateTime(2024, m)),
                    style: const TextStyle(
                        fontSize: 9, color: WTheme.textGray));
              },
            )),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: counts.asMap().entries.map((e) =>
              BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: e.key == 5
                      ? WTheme.primary : WTheme.primary.withOpacity(0.5),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ])).toList(),
        )),
      );
    });
  }
}

// ─── Gráfico: receita por mês ─────────────────────────────────────────────────
class _MonthlyEarningsChart extends StatelessWidget {
  final WorkerController ctrl;
  const _MonthlyEarningsChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.compactCurrency(
        locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return Obx(() {
      final now    = DateTime.now();
      final values = ctrl.earningsByMonth;
      final maxY   = values.fold(0.0, (a, b) => a > b ? a : b) * 1.2;

      return _ChartCard(
        child: BarChart(BarChartData(
          maxY: maxY < 100 ? 100 : maxY,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 42,
              getTitlesWidget: (v, _) => Text(money.format(v),
                  style: const TextStyle(
                      fontSize: 8, color: WTheme.textGray)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                int m = now.month - (5 - v.toInt());
                if (m <= 0) m += 12;
                return Text(
                    DateFormat.MMM('pt_BR').format(DateTime(2024, m)),
                    style: const TextStyle(
                        fontSize: 9, color: WTheme.textGray));
              },
            )),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: values.asMap().entries.map((e) =>
              BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value,
                  gradient: LinearGradient(
                    colors: [
                      WTheme.primary,
                      WTheme.primary.withOpacity(
                          e.key == 5 ? 1.0 : 0.5),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ])).toList(),
        )),
      );
    });
  }
}

// ─── Últimos serviços ─────────────────────────────────────────────────────────
class _RecentServices extends StatelessWidget {
  final WorkerController ctrl;
  const _RecentServices({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money  = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yy · HH:mm', 'pt_BR');

    return Obx(() {
      final recent = ctrl.doneOrders.take(5).toList();
      if (recent.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WTheme.border),
          ),
          child: const Row(children: [
            Icon(Icons.history_rounded, color: WTheme.textLight, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum serviço concluído ainda.',
                style: TextStyle(color: WTheme.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        );
      }

      return Column(
        children: [
          ...recent.map((o) => GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.orderDetail,
                arguments: {'order': o, 'isWorker': true}),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WTheme.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000),
                      blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: WTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.serviceCategory,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${o.clientName ?? "Cliente"} · '
                        '${dateFmt.format(o.completedAt ?? o.updatedAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: WTheme.textGray),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    o.price != null ? money.format(o.price) : '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13, color: WTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WTheme.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Concluído',
                        style: TextStyle(fontSize: 9,
                            color: WTheme.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
          )),
          // Ver todos
          if (ctrl.doneOrders.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.workerReports),
                child: const Text('Ver todos os serviços →',
                    style: TextStyle(color: WTheme.primary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _BigCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _BigCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000),
              blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: color),
                overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(label, style: const TextStyle(
                fontSize: 11, color: WTheme.textGray),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        )),
      ]),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _EarningCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000),
              blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        Text(label, style: const TextStyle(
            fontSize: 10, color: WTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ]),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000),
              blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
