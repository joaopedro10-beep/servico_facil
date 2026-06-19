import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/order_model.dart';
import '../controllers/worker_home_controller.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerHomeController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ctrl.reload(),
          child: Obx(() {
            if (ctrl.isLoadingOrders.value && ctrl.allOrders.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator.adaptive());
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(ctrl)),
                SliverToBoxAdapter(child: _buildSummaryCards(ctrl)),
                SliverToBoxAdapter(child: _buildPendingSection(ctrl)),
                SliverToBoxAdapter(child: _buildInProgressSection(ctrl)),
                SliverToBoxAdapter(child: _buildChart(ctrl)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(WorkerHomeController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      'Olá, ${ctrl.worker.value?.name.split(' ').first ?? ''}! 👷',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    )),
                const Text('Gerencie seus serviços',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Switch de disponibilidade
          Obx(() => Column(
                children: [
                  Switch.adaptive(
                    value: ctrl.isAvailable.value,
                    activeColor: AppColors.primary,
                    onChanged: ctrl.isTogglingAvailability.value
                        ? null
                        : ctrl.toggleAvailability,
                  ),
                  Text(
                    ctrl.isAvailable.value ? 'Disponível' : 'Ocupado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ctrl.isAvailable.value
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  // ── Summary Cards ──────────────────────────────────────────────────────────

  Widget _buildSummaryCards(WorkerHomeController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Obx(() => GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _SummaryCard(
                label: 'Hoje',
                value: '${ctrl.todayOrdersCount}',
                icon: Icons.today_outlined,
                color: AppColors.info,
              ),
              _SummaryCard(
                label: 'Avaliação',
                value: ctrl.currentRating > 0
                    ? ctrl.currentRating.toStringAsFixed(1)
                    : '—',
                icon: Icons.star_rounded,
                color: Colors.amber,
                suffix: ctrl.currentRating > 0 ? '★' : '',
              ),
              _SummaryCard(
                label: 'Concluídos',
                value: '${ctrl.totalCompleted}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ],
          )),
    );
  }

  // ── Pedidos pendentes ──────────────────────────────────────────────────────

  Widget _buildPendingSection(WorkerHomeController ctrl) {
    return Obx(() {
      final pending = ctrl.pendingOrders;
      if (pending.isEmpty) return const SizedBox.shrink();

      return _Section(
        title: 'Aguardando resposta (${pending.length})',
        child: Column(
          children: pending
              .map((o) => _PendingOrderCard(order: o, ctrl: ctrl))
              .toList(),
        ),
      );
    });
  }

  // ── Em andamento ───────────────────────────────────────────────────────────

  Widget _buildInProgressSection(WorkerHomeController ctrl) {
    return Obx(() {
      final inProgress = ctrl.inProgressOrders;
      if (inProgress.isEmpty) return const SizedBox.shrink();

      return _Section(
        title: 'Em andamento',
        child: Column(
          children: inProgress
              .map((o) => _InProgressCard(order: o, ctrl: ctrl))
              .toList(),
        ),
      );
    });
  }

  // ── Gráfico de barras ──────────────────────────────────────────────────────

  Widget _buildChart(WorkerHomeController ctrl) {
    return Obx(() {
      final data = ctrl.last7DaysCompleted;
      final maxY = (data.reduce((a, b) => a > b ? a : b) + 1).toDouble();

      return _Section(
        title: 'Serviços concluídos — últimos 7 dias',
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY < 2 ? 3 : maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final day = DateTime.now()
                          .subtract(Duration(days: 6 - v.toInt()));
                      return Text(
                        DateFormat('E', 'pt_BR').format(day),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].toDouble(),
                      color: AppColors.primary,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY < 2 ? 3 : maxY,
                        color: AppColors.primary.withOpacity(0.06),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            suffix.isNotEmpty ? '$value $suffix' : value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PendingOrderCard extends StatefulWidget {
  const _PendingOrderCard(
      {required this.order, required this.ctrl});
  final OrderModel order;
  final WorkerHomeController ctrl;

  @override
  State<_PendingOrderCard> createState() => _PendingOrderCardState();
}

class _PendingOrderCardState extends State<_PendingOrderCard> {
  late final _ticker = Stream.periodic(const Duration(seconds: 60));
  late final _sub = _ticker.listen((_) => setState(() {}));

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  String _elapsed() {
    final diff =
        DateTime.now().difference(widget.order.createdAt);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    return 'há ${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusPending.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(o.serviceCategory,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusPending)),
                ),
                const Spacer(),
                const Icon(Icons.access_time,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 3),
                Text(_elapsed(),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              o.description.length > 80
                  ? '${o.description.substring(0, 80)}...'
                  : o.description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed: () => widget.ctrl.quickRefuse(o),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Recusar',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38)),
                    onPressed: () => widget.ctrl.quickAccept(o),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Aceitar',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InProgressCard extends StatelessWidget {
  const _InProgressCard(
      {required this.order, required this.ctrl});
  final OrderModel order;
  final WorkerHomeController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.statusInProgress.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusInProgress.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.engineering_outlined,
                  color: AppColors.statusInProgress, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.serviceCategory,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(
                    order.description.length > 50
                        ? '${order.description.substring(0, 50)}...'
                        : order.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(90, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => ctrl.quickComplete(order),
              child: const Text('Concluir',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
