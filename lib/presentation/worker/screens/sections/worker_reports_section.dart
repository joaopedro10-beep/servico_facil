import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Relatórios completos do prestador.
/// 5 gráficos dinâmicos + tabela de serviços + exportação CSV e PDF.
class WorkerReportsSection extends StatefulWidget {
  final WorkerController ctrl;
  const WorkerReportsSection({super.key, required this.ctrl});

  @override
  State<WorkerReportsSection> createState() => _WorkerReportsSectionState();
}

class _WorkerReportsSectionState extends State<WorkerReportsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);
  bool _exporting = false;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ─────────────────────────────────────────────────────────────
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Relatórios',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
            // Exportar
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_rounded,
                  color: Colors.white, size: 22),
              tooltip: 'Exportar',
              onSelected: (v) {
                if (v == 'csv')  _exportCsv();
                if (v == 'pdf')  _exportPdf();
                if (v == 'copy') _copyToClipboard();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'csv',
                    child: Row(children: [
                      Icon(Icons.table_chart_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Exportar CSV'),
                    ])),
                PopupMenuItem(value: 'pdf',
                    child: Row(children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Exportar PDF'),
                    ])),
                PopupMenuItem(value: 'copy',
                    child: Row(children: [
                      Icon(Icons.copy_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Copiar dados'),
                    ])),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          TabBar(
            controller: _tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Visão Geral'),
              Tab(text: 'Faturamento'),
              Tab(text: 'Categorias'),
              Tab(text: 'Serviços'),
            ],
          ),
        ]),
      ),

      // ── Abas ───────────────────────────────────────────────────────────────
      Expanded(
        child: Obx(() {
          final done      = widget.ctrl.doneOrders;
          final cancelled = widget.ctrl.cancelledOrders;
          final all       = widget.ctrl.allOrders;

          if (_exporting) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator.adaptive(),
                SizedBox(height: 12),
                Text('Gerando arquivo...',
                    style: TextStyle(color: WTheme.textGray, fontSize: 14)),
              ]),
            );
          }

          return TabBarView(
            controller: _tab,
            children: [
              _OverviewTab(ctrl: widget.ctrl, done: done,
                  cancelled: cancelled),
              _BillingTab(ctrl: widget.ctrl, done: done),
              _CategoriesTab(done: done),
              _ServicesTab(done: done, cancelled: cancelled, all: all,
                  ctrl: widget.ctrl),
            ],
          );
        }),
      ),
    ]);
  }

  // ─── CSV export ─────────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final done = widget.ctrl.doneOrders;
      final money = NumberFormat.currency(locale: 'pt_BR', symbol: '');
      final buf = StringBuffer();
      buf.writeln('Data,Categoria,Cliente,Valor,Status');
      for (final o in done) {
        final d = DateFormat('dd/MM/yyyy').format(
            o.completedAt ?? o.updatedAt);
        final val = o.price != null ? money.format(o.price) : '0';
        buf.writeln('$d,"${o.serviceCategory}","${o.clientName ?? ""}","$val",Concluído');
      }
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/relatorio_servicofacil.csv');
      await file.writeAsString(buf.toString());

      Get.snackbar('CSV gerado!',
          'Arquivo salvo em ${file.path}',
          backgroundColor: WTheme.primary, colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4));
    } catch (_) {
      // Fallback: copia para clipboard
      await _copyToClipboard();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ─── PDF export ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final done  = widget.ctrl.doneOrders;
      final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'RS');
      final now   = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final total = done.fold(0.0, (s, o) => s + (o.price ?? 0));

      final html = StringBuffer();
      html.writeln('''<!DOCTYPE html><html lang="pt-BR"><head>
<meta charset="UTF-8">
<style>
  body{font-family:Arial,sans-serif;margin:24px;color:#222}
  h1{color:#1D9E75;font-size:22px}
  h2{color:#0F6E56;font-size:15px;margin-top:20px}
  .kpi{display:flex;gap:16px;flex-wrap:wrap;margin:12px 0}
  .kpi-card{background:#E8F5F0;border-radius:10px;padding:12px 18px;min-width:140px}
  .kpi-val{font-size:24px;font-weight:900;color:#1D9E75}
  .kpi-lbl{font-size:11px;color:#546E7A}
  table{width:100%;border-collapse:collapse;margin-top:10px;font-size:12px}
  th{background:#1D9E75;color:white;padding:8px 10px;text-align:left}
  td{padding:7px 10px;border-bottom:1px solid #eee}
  tr:nth-child(even){background:#F5F7FA}
  .footer{margin-top:30px;font-size:10px;color:#90A4AE}
</style></head><body>
<h1>ServiçoFácil — Relatório de Serviços</h1>
<p style="color:#546E7A;font-size:12px">Gerado em: $now</p>
<div class="kpi">
  <div class="kpi-card"><div class="kpi-val">${done.length}</div><div class="kpi-lbl">Serviços concluídos</div></div>
  <div class="kpi-card"><div class="kpi-val">${money.format(total)}</div><div class="kpi-lbl">Faturamento total</div></div>
  <div class="kpi-card"><div class="kpi-val">${widget.ctrl.avgRating > 0 ? widget.ctrl.avgRating.toStringAsFixed(1) : '—'}</div><div class="kpi-lbl">Avaliação média</div></div>
  <div class="kpi-card"><div class="kpi-val">${widget.ctrl.cancelledOrders.length}</div><div class="kpi-lbl">Cancelados</div></div>
</div>
<h2>Histórico de serviços</h2>
<table><tr><th>Data</th><th>Categoria</th><th>Cliente</th><th>Valor</th></tr>''');

      for (final o in done) {
        final d = DateFormat('dd/MM/yyyy').format(o.completedAt ?? o.updatedAt);
        html.writeln('<tr><td>$d</td><td>${o.serviceCategory}</td>'
            '<td>${o.clientName ?? "—"}</td>'
            '<td>${o.price != null ? money.format(o.price) : "—"}</td></tr>');
      }
      html.writeln('</table><div class="footer">ServiçoFácil © ${DateTime.now().year}</div></body></html>');

      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/relatorio_servicofacil.html');
      await file.writeAsString(html.toString());

      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Relatório gerado!',
            'Salvo em ${file.path}\nAbra com seu navegador para imprimir como PDF.',
            backgroundColor: WTheme.primary, colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 5));
      }
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível gerar o PDF.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ─── Clipboard copy ─────────────────────────────────────────────────────────
  Future<void> _copyToClipboard() async {
    final done = widget.ctrl.doneOrders;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final buf = StringBuffer();
    buf.writeln('RELATÓRIO SERVIÇOFÁCIL');
    buf.writeln('Total de serviços: ${done.length}');
    buf.writeln('Faturamento total: ${money.format(
        done.fold(0.0, (s, o) => s + (o.price ?? 0)))}');
    buf.writeln('\nData | Categoria | Cliente | Valor');
    buf.writeln('─' * 50);
    for (final o in done.take(50)) {
      final d = DateFormat('dd/MM/yy').format(o.completedAt ?? o.updatedAt);
      buf.writeln('$d | ${o.serviceCategory} | '
          '${o.clientName ?? "—"} | '
          '${o.price != null ? money.format(o.price) : "—"}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    Get.snackbar('Copiado!',
        'Dados copiados para a área de transferência.',
        backgroundColor: WTheme.primary, colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3));
    if (mounted) setState(() => _exporting = false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 1 — VISÃO GERAL
// KPIs + gráfico serviços/mês + gráfico crescimento mensal + avaliações
// ═══════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final WorkerController ctrl;
  final List<OrderModel> done;
  final List<OrderModel> cancelled;
  const _OverviewTab({
      required this.ctrl,
      required this.done,
      required this.cancelled});

  @override
  Widget build(BuildContext context) {
    final total    = done.length;
    final rating   = ctrl.avgRating;
    final reviews  = ctrl.worker.value?.totalReviews ?? 0;
    final taxa     = (total + cancelled.length) > 0
        ? total / (total + cancelled.length) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPI Grid
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _KpiCard(Icons.task_alt_rounded, 'Concluídos',
                '$total', WTheme.primary, WTheme.primaryLight),
            _KpiCard(Icons.star_rounded, 'Avaliação',
                rating > 0 ? rating.toStringAsFixed(1) : '—',
                Colors.amber, const Color(0xFFFFF8E1)),
            _KpiCard(Icons.cancel_outlined, 'Cancelados',
                '${cancelled.length}',
                WTheme.red, const Color(0xFFFFEBEE)),
            _KpiCard(Icons.percent_rounded, 'Taxa conclusão',
                '${taxa.toStringAsFixed(0)}%',
                WTheme.green, const Color(0xFFE8F5E9)),
          ],
        ),
        const SizedBox(height: 24),

        // Gráfico 1: Serviços por mês (barras)
        _ChartHeader('Serviços por mês',
            Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        _ServicesMonthChart(orders: done),
        const SizedBox(height: 24),

        // Gráfico 2: Crescimento mensal (linha)
        _ChartHeader('Crescimento mensal',
            Icons.trending_up_rounded),
        const SizedBox(height: 12),
        _GrowthLineChart(orders: done),
        const SizedBox(height: 24),

        // Gráfico 3: Avaliações por estrela (horizontal)
        if (reviews > 0) ...[
          _ChartHeader('Distribuição de avaliações',
              Icons.reviews_rounded),
          const SizedBox(height: 12),
          _RatingsChart(ctrl: ctrl),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 2 — FATURAMENTO
// Gráfico receita/mês + tabela financeira + indicadores
// ═══════════════════════════════════════════════════════════════════════════
class _BillingTab extends StatelessWidget {
  final WorkerController ctrl;
  final List<OrderModel> done;
  const _BillingTab({required this.ctrl, required this.done});

  @override
  Widget build(BuildContext context) {
    final money    = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final now      = DateTime.now();
    final total    = done.fold(0.0, (s, o) => s + (o.price ?? 0));
    final media    = done.isNotEmpty ? total / done.length : 0.0;
    final fee      = total * 0.05;
    final net      = total - fee;

    final hoje = done.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (s, o) => s + (o.price ?? 0));

    final mes = done.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.year == now.year && d.month == now.month;
    }).fold(0.0, (s, o) => s + (o.price ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [WTheme.primary, WTheme.primaryDark]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Faturamento total acumulado',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(money.format(total),
                style: const TextStyle(color: Colors.white,
                    fontSize: 30, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Líquido (após 5% taxa): ${money.format(net)}',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(height: 14),

        // KPIs financeiros
        Row(children: [
          Expanded(child: _FinCard('Hoje', money.format(hoje),
              Icons.wb_sunny_rounded, WTheme.amber)),
          const SizedBox(width: 10),
          Expanded(child: _FinCard('Este mês', money.format(mes),
              Icons.calendar_month_rounded, WTheme.primary)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _FinCard('Média/serviço', money.format(media),
              Icons.analytics_rounded,
              const Color(0xFF6A1B9A))),
          const SizedBox(width: 10),
          Expanded(child: _FinCard('Taxa plataforma',
              money.format(fee),
              Icons.receipt_outlined, WTheme.red)),
        ]),
        const SizedBox(height: 24),

        // Gráfico faturamento por mês
        _ChartHeader('Faturamento por mês',
            Icons.monetization_on_rounded),
        const SizedBox(height: 12),
        _BillingMonthChart(ctrl: ctrl),
        const SizedBox(height: 24),

        // Tabela de histórico financeiro
        _ChartHeader('Histórico financeiro',
            Icons.table_rows_rounded),
        const SizedBox(height: 10),
        _FinancialTable(orders: done),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 3 — CATEGORIAS
// Gráfico pizza + barras horizontais por categoria
// ═══════════════════════════════════════════════════════════════════════════
class _CategoriesTab extends StatelessWidget {
  final List<OrderModel> done;
  const _CategoriesTab({required this.done});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> byCat = {};
    for (final o in done) {
      byCat[o.serviceCategory] = (byCat[o.serviceCategory] ?? 0) + 1;
    }
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.category_outlined, size: 56, color: WTheme.textLight),
          SizedBox(height: 12),
          Text('Nenhum serviço concluído ainda.',
              style: TextStyle(color: WTheme.textGray, fontSize: 14)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gráfico pizza
        _ChartHeader('Categorias mais atendidas', Icons.pie_chart_rounded),
        const SizedBox(height: 12),
        _CatPieChart(byCat: byCat, total: done.length),
        const SizedBox(height: 24),

        // Barras horizontais
        _ChartHeader('Ranking de categorias', Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        ...sorted.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _HorizontalBar(
              label: e.key,
              count: e.value,
              total: done.length,
              color: _catColor(sorted.indexOf(e))),
        )),
      ]),
    );
  }

  Color _catColor(int i) {
    const colors = [
      WTheme.primary, Color(0xFF6A1B9A), Color(0xFF0277BD),
      WTheme.amber, WTheme.red, Color(0xFF00695C),
      Color(0xFF558B2F), Color(0xFFD84315),
    ];
    return colors[i % colors.length];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 4 — SERVIÇOS
// Tabela completa com filtro + exportação
// ═══════════════════════════════════════════════════════════════════════════
class _ServicesTab extends StatefulWidget {
  final List<OrderModel> done;
  final List<OrderModel> cancelled;
  final List<OrderModel> all;
  final WorkerController ctrl;
  const _ServicesTab({
    required this.done,
    required this.cancelled,
    required this.all,
    required this.ctrl,
  });

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final money   = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yy', 'pt_BR');

    final List<OrderModel> orders;
    switch (_filter) {
      case 'done':
        orders = widget.done;
        break;
      case 'cancelled':
        orders = widget.cancelled;
        break;
      default:
        orders = widget.all;
    }

    return Column(children: [
      // Filtro
      Container(
        color: WTheme.background,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          _FilterChip('Todos', 'all', _filter,
              (v) => setState(() => _filter = v)),
          const SizedBox(width: 8),
          _FilterChip('Concluídos', 'done', _filter,
              (v) => setState(() => _filter = v)),
          const SizedBox(width: 8),
          _FilterChip('Cancelados', 'cancelled', _filter,
              (v) => setState(() => _filter = v)),
        ]),
      ),

      // Resumo rápido
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          Text('${orders.length} serviço(s)',
              style: const TextStyle(
                  fontSize: 12, color: WTheme.textGray,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_filter != 'cancelled')
            Text(money.format(
                orders.fold(0.0, (s, o) => s + (o.price ?? 0))),
                style: const TextStyle(
                    fontSize: 12, color: WTheme.primary,
                    fontWeight: FontWeight.w700)),
        ]),
      ),

      // Tabela / lista de serviços
      Expanded(
        child: orders.isEmpty
            ? const Center(
                child: Text('Nenhum serviço neste filtro.',
                    style: TextStyle(color: WTheme.textGray, fontSize: 14)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o   = orders[i];
                  final date = dateFmt.format(
                      o.completedAt ?? o.updatedAt);
                  final isDone = o.status == OrderStatus.done;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WTheme.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        // Status indicator
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isDone
                                ? WTheme.primaryLight
                                : WTheme.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isDone ? WTheme.primary : WTheme.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.serviceCategory,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${o.clientName ?? "Cliente"} · $date',
                              style: const TextStyle(
                                  fontSize: 11, color: WTheme.textGray),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              o.price != null
                                  ? money.format(o.price)
                                  : '—',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDone
                                      ? WTheme.primary : WTheme.textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? WTheme.primaryLight
                                    : WTheme.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                isDone ? 'Concluído' : 'Cancelado',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: isDone
                                        ? WTheme.primary : WTheme.red,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRÁFICOS
// ═══════════════════════════════════════════════════════════════════════════

// Gráfico 1: Serviços por mês (barras verticais)
class _ServicesMonthChart extends StatelessWidget {
  final List<OrderModel> orders;
  const _ServicesMonthChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final counts = List.generate(6, (i) {
      int m = now.month - (5 - i);
      int y = now.year;
      if (m <= 0) { m += 12; y--; }
      return orders.where((o) {
        final d = o.completedAt ?? o.updatedAt;
        return d.year == y && d.month == m;
      }).length.toDouble();
    });
    final maxY = counts.fold(0.0, (a, b) => a > b ? a : b);

    return _ChartBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: maxY < 3 ? 3 : maxY + 1,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WTheme.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24, interval: 1,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: WTheme.textGray)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              int m = now.month - (5 - v.toInt());
              if (m <= 0) m += 12;
              return Text(DateFormat.MMM('pt').format(DateTime(2024, m)),
                  style: const TextStyle(fontSize: 9, color: WTheme.textGray));
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: counts.asMap().entries.map((e) =>
            BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value,
                color: e.key == 5
                    ? WTheme.primary : WTheme.primary.withOpacity(0.45),
                width: 24,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                rodStackItems: [],
              ),
            ])).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => WTheme.primary,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} serviços',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      )),
    );
  }
}

// Gráfico 2: Crescimento mensal (linha)
class _GrowthLineChart extends StatelessWidget {
  final List<OrderModel> orders;
  const _GrowthLineChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final counts = List.generate(6, (i) {
      int m = now.month - (5 - i);
      int y = now.year;
      if (m <= 0) { m += 12; y--; }
      return orders.where((o) {
        final d = o.completedAt ?? o.updatedAt;
        return d.year == y && d.month == m;
      }).length.toDouble();
    });
    final maxY = counts.fold(0.0, (a, b) => a > b ? a : b);

    return _ChartBox(
      height: 200,
      child: LineChart(LineChartData(
        maxY: maxY < 3 ? 3 : maxY + 1,
        minY: 0,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WTheme.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24, interval: 1,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: WTheme.textGray)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              int m = now.month - (5 - v.toInt());
              if (m <= 0) m += 12;
              return Text(DateFormat.MMM('pt').format(DateTime(2024, m)),
                  style: const TextStyle(fontSize: 9, color: WTheme.textGray));
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: counts.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: WTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, i) => FlDotCirclePainter(
                radius: 4,
                color: i == 5 ? WTheme.primary : Colors.white,
                strokeWidth: 2,
                strokeColor: WTheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  WTheme.primary.withOpacity(0.25),
                  WTheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => WTheme.primary,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.y.toInt()} serviços',
              const TextStyle(color: Colors.white, fontSize: 11),
            )).toList(),
          ),
        ),
      )),
    );
  }
}

// Gráfico 3: Avaliações por estrela (barras horizontais)
class _RatingsChart extends StatelessWidget {
  final WorkerController ctrl;
  const _RatingsChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final reviews = ctrl.reviews;
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final s = r.rating.round().clamp(1, 5);
      dist[s] = (dist[s] ?? 0) + 1;
    }
    final total = reviews.length;
    final avg   = ctrl.avgRating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
      ),
      child: Row(children: [
        // Média grande
        Column(children: [
          Text(avg > 0 ? avg.toStringAsFixed(1) : '—',
              style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w900,
                  color: WTheme.textDark),
              overflow: TextOverflow.ellipsis),
          Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Icon(
                i < avg.round()
                    ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 14,
              ))),
          const SizedBox(height: 4),
          Text('$total avaliações',
              style: const TextStyle(fontSize: 10, color: WTheme.textGray),
              overflow: TextOverflow.ellipsis),
        ]),
        const SizedBox(width: 16),
        // Barras
        Expanded(child: Column(
          children: [5, 4, 3, 2, 1].map((star) {
            final count = dist[star] ?? 0;
            final pct   = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Text('$star', style: const TextStyle(
                    fontSize: 11, color: WTheme.textGray)),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 11),
                const SizedBox(width: 6),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: WTheme.border,
                    valueColor: const AlwaysStoppedAnimation(Colors.amber),
                    minHeight: 7,
                  ),
                )),
                const SizedBox(width: 6),
                SizedBox(width: 22,
                  child: Text('$count',
                      style: const TextStyle(
                          fontSize: 10, color: WTheme.textGray),
                      textAlign: TextAlign.right)),
              ]),
            );
          }).toList(),
        )),
      ]),
    );
  }
}

// Gráfico 4: Faturamento por mês (barras com gradiente)
class _BillingMonthChart extends StatelessWidget {
  final WorkerController ctrl;
  const _BillingMonthChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money  = NumberFormat.compactCurrency(
        locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
    final now    = DateTime.now();
    final values = ctrl.earningsByMonth;
    final maxY   = values.fold(0.0, (a, b) => a > b ? a : b) * 1.2;

    return _ChartBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: maxY < 50 ? 50 : maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: WTheme.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 46,
            getTitlesWidget: (v, _) => Text(money.format(v),
                style: const TextStyle(fontSize: 8, color: WTheme.textGray)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              int m = now.month - (5 - v.toInt());
              if (m <= 0) m += 12;
              return Text(DateFormat.MMM('pt').format(DateTime(2024, m)),
                  style: const TextStyle(fontSize: 9, color: WTheme.textGray));
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: values.asMap().entries.map((e) =>
            BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value,
                gradient: LinearGradient(
                  colors: [
                    WTheme.primary.withOpacity(e.key == 5 ? 1.0 : 0.5),
                    WTheme.primary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 24,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ])).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => WTheme.primary,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(rod.toY),
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      )),
    );
  }
}

// Gráfico 5: Categorias — pizza
class _CatPieChart extends StatefulWidget {
  final Map<String, int> byCat;
  final int total;
  const _CatPieChart({required this.byCat, required this.total});

  @override
  State<_CatPieChart> createState() => _CatPieChartState();
}

class _CatPieChartState extends State<_CatPieChart> {
  int _touched = -1;

  static const _colors = [
    WTheme.primary, Color(0xFF6A1B9A), Color(0xFF0277BD),
    WTheme.amber, WTheme.red, Color(0xFF00695C),
    Color(0xFF558B2F), Color(0xFFD84315),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ChartBox(
      height: 240,
      child: Row(children: [
        // Pizza
        Expanded(
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (ev, resp) => setState(() =>
                  _touched = resp?.touchedSection?.touchedSectionIndex ?? -1),
            ),
            sections: entries.asMap().entries.map((e) {
              final i   = e.key;
              final pct = e.value.value / widget.total * 100;
              final isTouched = i == _touched;
              return PieChartSectionData(
                color: _colors[i % _colors.length],
                value: e.value.value.toDouble(),
                title: '${pct.toStringAsFixed(0)}%',
                radius: isTouched ? 75 : 62,
                titleStyle: TextStyle(
                  fontSize: isTouched ? 14 : 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 32,
          )),
        ),
        // Legenda
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.take(5).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _colors[e.key % _colors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 100,
                  child: Text(e.value.key,
                      style: const TextStyle(
                          fontSize: 10, color: WTheme.textDark,
                          fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Text('${e.value.value}',
                    style: TextStyle(
                        fontSize: 10, color: _colors[e.key % _colors.length],
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// Tabela financeira
class _FinancialTable extends StatelessWidget {
  final List<OrderModel> orders;
  const _FinancialTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    final money   = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yy');
    final recent  = orders.take(15).toList();

    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nenhuma transação ainda.',
            style: TextStyle(color: WTheme.textGray, fontSize: 13)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
      ),
      child: Column(children: [
        // Cabeçalho
        Container(
          decoration: const BoxDecoration(
            color: WTheme.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
          ),
          child: const Row(children: [
            _TH('Data', flex: 2),
            _TH('Serviço', flex: 3),
            _TH('Valor', flex: 2, right: true),
          ]),
        ),
        // Linhas
        ...recent.asMap().entries.map((e) {
          final o    = e.value;
          final even = e.key % 2 == 0;
          return Container(
            color: even ? Colors.white : WTheme.background,
            child: Row(children: [
              _TD(dateFmt.format(o.completedAt ?? o.updatedAt), flex: 2),
              _TD(o.serviceCategory, flex: 3),
              _TD(o.price != null ? money.format(o.price) : '—',
                  flex: 2, right: true, color: WTheme.primary),
            ]),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _ChartBox extends StatelessWidget {
  final Widget child;
  final double height;
  const _ChartBox({required this.child, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ChartHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: WTheme.primary, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: WTheme.textDark),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _KpiCard(this.icon, this.label, this.value,
      this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w900, color: color),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          Text(label, style: const TextStyle(
              fontSize: 11, color: WTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 2),
        ]),
      ]),
    );
  }
}

class _FinCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _FinCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(value, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w800, color: color),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          Text(label, style: const TextStyle(
              fontSize: 10, color: WTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ])),
      ]),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _HorizontalBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: WTheme.textDark),
            overflow: TextOverflow.ellipsis, maxLines: 1)),
        Text('$count',
            style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 6),
        Text('(${(pct * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 10, color: WTheme.textGray)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: WTheme.border,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  const _FilterChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? WTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? WTheme.primary : WTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : WTheme.textGray),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final bool right;
  const _TH(this.text, {required this.flex, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700),
            textAlign: right ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  final bool right;
  final Color? color;
  const _TD(this.text, {required this.flex, this.right = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color ?? WTheme.textDark),
            textAlign: right ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }
}
