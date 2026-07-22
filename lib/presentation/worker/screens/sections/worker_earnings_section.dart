import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

class WorkerEarningsSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerEarningsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(children: [
      // Header
      Container(
        color: WTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: const Text('Ganhos',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),

      Expanded(
        child: Obx(() {
          final total = ctrl.totalEarnings;
          final filtered = ctrl.filteredEarnings;
          final byMonth = ctrl.earningsByMonth;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros de período
                _PeriodFilter(ctrl: ctrl),
                const SizedBox(height: 14),

                // Card total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WTheme.blue, WTheme.blueDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _periodLabel(ctrl.earningsPeriod.value),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(money.format(total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      // Percentual vs mês anterior (placeholder)
                      const Row(children: [
                        Icon(Icons.trending_up_rounded,
                            color: Colors.greenAccent, size: 16),
                        SizedBox(width: 4),
                        Text('+12%',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Text('Comparado ao mês anterior',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Resumo
                _SummaryCard(
                  completed: ctrl.doneOrders.length,
                  net: total,
                  taxes: total * 0.05,
                  avg: ctrl.doneOrders.isNotEmpty
                      ? total / ctrl.doneOrders.length
                      : 0,
                  money: money,
                ),
                const SizedBox(height: 16),

                // Gráfico de barras por mês
                const Text('Ganhos por mês (2025)',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: WTheme.textDark)),
                const SizedBox(height: 12),
                _BarChart(byMonth: byMonth, money: money),
                const SizedBox(height: 20),

                // Detalhamento
                if (filtered.isNotEmpty) ...[
                  const Text('Detalhamento',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WTheme.textDark)),
                  const SizedBox(height: 10),
                  ...filtered.map((o) {
                    final date = DateFormat('dd/MM/yy')
                        .format(o.completedAt ?? o.updatedAt);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WTheme.border),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WTheme.blueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.handyman_outlined,
                              color: WTheme.blue, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.serviceCategory,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                '${o.clientName ?? "Cliente"} · $date',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: WTheme.textGray),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          o.price != null
                              ? money.format(o.price)
                              : '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: WTheme.blue),
                        ),
                      ]),
                    );
                  }),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              size: 48, color: WTheme.textLight),
                          const SizedBox(height: 10),
                          const Text('Nenhum serviço no período.',
                              style: TextStyle(
                                  color: WTheme.textGray,
                                  fontSize: 14),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    ]);
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'today': return 'Ganhos de hoje';
      case 'week':  return 'Ganhos desta semana';
      case 'year':  return 'Ganhos deste ano';
      default:      return 'Ganhos do mês';
    }
  }
}

class _PeriodFilter extends StatelessWidget {
  final WorkerController ctrl;
  const _PeriodFilter({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const periods = [
      ('today', 'Hoje'),
      ('week', 'Semana'),
      ('month', 'Mês'),
      ('year', 'Ano'),
    ];
    return Obx(() => Row(
          children: periods.map((p) {
            final sel = ctrl.earningsPeriod.value == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => ctrl.earningsPeriod.value = p.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? WTheme.blue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? WTheme.blue : WTheme.border),
                  ),
                  child: Center(
                    child: Text(p.$2,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : WTheme.textGray),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }
}

class _SummaryCard extends StatelessWidget {
  final int completed;
  final double net;
  final double taxes;
  final double avg;
  final NumberFormat money;

  const _SummaryCard({
    required this.completed,
    required this.net,
    required this.taxes,
    required this.avg,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
      ),
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Resumo',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        _Row('Serviços concluídos', '$completed'),
        const Divider(height: 14),
        _Row('Ganhos líquidos', money.format(net)),
        const Divider(height: 14),
        _Row('Taxas (5%)', money.format(taxes)),
        const Divider(height: 14),
        _Row('Média por serviço', completed > 0 ? money.format(avg) : '—'),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(label,
            style: const TextStyle(
                fontSize: 13, color: WTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      Text(value,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _BarChart extends StatelessWidget {
  final List<double> byMonth;
  final NumberFormat money;
  const _BarChart({required this.byMonth, required this.money});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxY = byMonth.fold(0.0, (a, b) => a > b ? a : b) + 500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(BarChartData(
          maxY: maxY < 1000 ? 4000 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 < 1 ? 1000 : maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: WTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) {
                  if (v == 0) return const Text('');
                  return Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : '${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 9, color: WTheme.textGray),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  int m = now.month - (5 - v.toInt());
                  if (m <= 0) m += 12;
                  return Text(
                    DateFormat.MMM('pt_BR').format(DateTime(2024, m)),
                    style: const TextStyle(
                        fontSize: 10, color: WTheme.textGray),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: byMonth.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  gradient: const LinearGradient(
                    colors: [WTheme.blue, Color(0xFF5e92f3)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        )),
      ),
    );
  }
}
