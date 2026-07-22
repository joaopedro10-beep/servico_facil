import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/admin_log_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/worker_model.dart';
import '../../admin_theme.dart';
import '../../controllers/admin_controller.dart';

class AdminDashboardSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminDashboardSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminTheme.primary,
      onRefresh: ctrl.refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Saudação ─────────────────────────────────────────────────
            _Greeting(ctrl: ctrl),
            const SizedBox(height: 20),

            // ── Cards KPI ────────────────────────────────────────────────
            _KpiGrid(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Operação em tempo real (fluxo 99) ────────────────────────
            const _SectionHeader(title: 'Operação em Tempo Real'),
            const SizedBox(height: 12),
            _LiveOperationsCard(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Indicadores financeiros da plataforma ────────────────────
            const _SectionHeader(title: 'Financeiro da Plataforma'),
            const SizedBox(height: 12),
            _PlatformFinanceCard(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Prestadores pendentes ─────────────────────────────────────
            _SectionHeader(
              title: 'Prestadores Pendentes',
              onSeeAll: () => ctrl.currentSection.value = 1,
            ),
            const SizedBox(height: 12),
            _PendingWorkersList(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Resumo geral ──────────────────────────────────────────────
            const _SectionHeader(title: 'Resumo Geral'),
            const SizedBox(height: 12),
            _SummaryCards(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Gráficos ─────────────────────────────────────────────────
            _BarChartCard(ctrl: ctrl),
            const SizedBox(height: 16),
            _PieChartCard(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Atividades recentes ───────────────────────────────────────
            _SectionHeader(
              title: 'Atividades Recentes',
              onSeeAll: () => ctrl.currentSection.value = 7,
            ),
            const SizedBox(height: 12),
            _RecentActivities(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Denúncias recentes ────────────────────────────────────────
            _SectionHeader(
              title: 'Denúncias Recentes',
              onSeeAll: () => ctrl.currentSection.value = 6,
            ),
            const SizedBox(height: 12),
            _RecentReports(ctrl: ctrl),
            const SizedBox(height: 24),

            // ── Notificações ──────────────────────────────────────────────
            const _SectionHeader(title: 'Notificações'),
            const SizedBox(height: 12),
            _NotificationsSection(ctrl: ctrl),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Saudação ─────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final AdminController ctrl;
  const _Greeting({required this.ctrl});

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              '$_timeGreeting, ${ctrl.adminName.value} 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR')
              .format(DateTime.now()),
          style: const TextStyle(fontSize: 13, color: AdminTheme.textGray),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    ));
  }
}

// ─── Cards KPI ────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final AdminController ctrl;
  const _KpiGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingDashboard.value) {
        return const SizedBox(
          height: 120,
          child: Center(
              child: CircularProgressIndicator(color: AdminTheme.primary)),
        );
      }
      final c = ctrl.dashboardCounts;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _KpiCard(
            icon: Icons.hourglass_top_rounded,
            label: 'Aguardando Aprovação',
            value: '${c['pendingWorkers'] ?? 0}',
            color: AdminTheme.amber,
            bgColor: const Color(0xFFFFF8E1),
            onTap: () => ctrl.currentSection.value = 1,
            alert: (c['pendingWorkers'] ?? 0) > 0,
          ),
          _KpiCard(
            icon: Icons.engineering_rounded,
            label: 'Prestadores Ativos',
            value: '${c['totalWorkers'] ?? 0}',
            color: AdminTheme.primary,
            bgColor: const Color(0xFFE3F2FD),
            onTap: () => ctrl.currentSection.value = 2,
          ),
          _KpiCard(
            icon: Icons.people_rounded,
            label: 'Clientes Cadastrados',
            value: '${c['totalClients'] ?? 0}',
            color: AdminTheme.green,
            bgColor: const Color(0xFFE8F5E9),
            onTap: () => ctrl.currentSection.value = 3,
          ),
          _KpiCard(
            icon: Icons.check_circle_rounded,
            label: 'Serviços Realizados',
            value: '${c['doneOrders'] ?? 0}',
            color: AdminTheme.purple,
            bgColor: const Color(0xFFF3E5F5),
            onTap: () => ctrl.currentSection.value = 4,
          ),
        ],
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final bool alert;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon, required this.label,
    required this.value, required this.color,
    required this.bgColor,
    this.alert = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: alert ? color.withOpacity(0.5) : AdminTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (alert)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: AdminTheme.redLight, shape: BoxShape.circle),
                ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AdminTheme.textGray, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Lista prestadores pendentes ──────────────────────────────────────────────
class _PendingWorkersList extends StatelessWidget {
  final AdminController ctrl;
  const _PendingWorkersList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = ctrl.pendingWorkers.take(5).toList();
      if (list.isEmpty) {
        return _EmptyCard(
          icon: Icons.check_circle_outline_rounded,
          message: 'Nenhum prestador aguardando aprovação',
          color: AdminTheme.green,
        );
      }
      return Column(
        children: list.map((w) => _PendingWorkerCard(worker: w, ctrl: ctrl)).toList(),
      );
    });
  }
}

class _PendingWorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final AdminController ctrl;
  const _PendingWorkerCard({required this.worker, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Foto / avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AdminTheme.primary.withOpacity(0.1),
            backgroundImage: worker.photoUrl != null
                ? NetworkImage(worker.photoUrl!) : null,
            child: worker.photoUrl == null
                ? Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.primary, fontSize: 18))
                : null,
          ),
          const SizedBox(width: 12),

          // Dados
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(worker.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                worker.categories.isNotEmpty ? worker.categories.first : '—',
                style: const TextStyle(
                    fontSize: 12, color: AdminTheme.textGray),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AdminTheme.textLight),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(worker.city,
                      style: const TextStyle(
                          fontSize: 11, color: AdminTheme.textLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // Badge pendente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.amber.withOpacity(0.4)),
              ),
              child: const Text('Pendente',
                  style: TextStyle(
                      fontSize: 10,
                      color: AdminTheme.amber,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            // Botão visualizar
            GestureDetector(
              onTap: () => _showWorkerDetail(context, worker),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Visualizar',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showWorkerDetail(BuildContext context, WorkerModel w) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _WorkerDetailScreen(worker: w, ctrl: ctrl),
    ));
  }
}

// ─── Tela de detalhes do prestador ───────────────────────────────────────────
class _WorkerDetailScreen extends StatelessWidget {
  final WorkerModel worker;
  final AdminController ctrl;
  const _WorkerDetailScreen({required this.worker, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Detalhes do Prestador',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Perfil ────────────────────────────────────────────────────
          _DetailCard(
            child: Row(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AdminTheme.primary.withOpacity(0.1),
                backgroundImage: worker.photoUrl != null
                    ? NetworkImage(worker.photoUrl!) : null,
                child: worker.photoUrl == null
                    ? Text(
                        worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: AdminTheme.primary))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(worker.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(worker.categories.join(', '),
                      style: const TextStyle(
                          color: AdminTheme.primary, fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AdminTheme.textGray),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(worker.city,
                          style: const TextStyle(
                              fontSize: 12, color: AdminTheme.textGray),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text('Cadastro: ${AppFormatters.date(worker.createdAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AdminTheme.textLight)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Documentos ────────────────────────────────────────────────
          const _CardTitle('Documentos Enviados'),
          const SizedBox(height: 8),
          _DetailCard(
            child: Column(children: [
              _DocRow(
                  icon: Icons.badge_outlined,
                  label: 'Documento (RG ou CNH)',
                  ok: worker.documentUrl != null),
              const Divider(height: 12),
              _DocRow(icon: Icons.numbers_rounded, label: 'CPF', ok: true),
              const Divider(height: 12),
              _DocRow(
                  icon: Icons.home_outlined,
                  label: 'Comprovante de Residência',
                  ok: false),
              const Divider(height: 12),
              _DocRow(
                  icon: Icons.camera_alt_outlined,
                  label: 'Selfie para Validação',
                  ok: false),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Dados profissionais ───────────────────────────────────────
          const _CardTitle('Dados Profissionais'),
          const SizedBox(height: 8),
          _DetailCard(
            child: Column(children: [
              _DetailRow('Especialidade', worker.categories.join(', ')),
              const Divider(height: 16),
              _DetailRow('Descrição', worker.description),
              const Divider(height: 16),
              _DetailRow('Telefone', worker.phone),
              const Divider(height: 16),
              _DetailRow('E-mail', worker.email),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Botões de ação ────────────────────────────────────────────
          _ActionButton(
            label: '🟢  Aprovar Cadastro',
            color: AdminTheme.green,
            bgColor: const Color(0xFFE8F5E9),
            onTap: () {
              Navigator.of(context).pop();
              ctrl.approveWorker(worker);
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: '🟡  Solicitar Novos Documentos',
            color: AdminTheme.amber,
            bgColor: const Color(0xFFFFF8E1),
            onTap: () {
              Navigator.of(context).pop();
              ctrl.requestDocuments(worker);
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: '🔴  Rejeitar Cadastro',
            color: AdminTheme.red,
            bgColor: const Color(0xFFFFEBEE),
            onTap: () {
              Navigator.of(context).pop();
              ctrl.rejectWorker(worker);
            },
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;
  const _DocRow({required this.icon, required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AdminTheme.textGray),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: const TextStyle(fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      Icon(
        ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 18,
        color: ok ? AdminTheme.green : AdminTheme.textLight,
      ),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AdminTheme.textGray)),
      ),
      Expanded(
        child: Text(value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis, maxLines: 3),
      ),
    ]);
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  const _CardTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AdminTheme.textDark));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.color,
    required this.bgColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }
}

// ─── Resumo geral ─────────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final AdminController ctrl;
  const _SummaryCards({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all = ctrl.allWorkers;
      final approved = all.where((w) =>
          w.verificationStatus == VerificationStatus.approved).length;
      final pending = all.where((w) =>
          w.verificationStatus == VerificationStatus.pending).length;
      final suspended = all.where((w) => w.isSuspended).length;
      final rejected = all.where((w) =>
          w.verificationStatus == VerificationStatus.rejected).length;

      return Row(children: [
        _SmallCard(label: 'Ativos', value: '$approved', color: AdminTheme.green),
        const SizedBox(width: 8),
        _SmallCard(label: 'Pendentes', value: '$pending', color: AdminTheme.amber),
        const SizedBox(width: 8),
        _SmallCard(label: 'Suspensos', value: '$suspended', color: AdminTheme.red),
        const SizedBox(width: 8),
        _SmallCard(label: 'Rejeitados', value: '$rejected', color: AdminTheme.textGray),
      ]);
    });
  }
}

class _SmallCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SmallCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AdminTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 1,
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── Gráfico de barras ────────────────────────────────────────────────────────
class _BarChartCard extends StatelessWidget {
  final AdminController ctrl;
  const _BarChartCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'Serviços por Mês',
      child: SizedBox(
        height: 180,
        child: Obx(() {
          final orders = ctrl.allOrders;
          final now = DateTime.now();
          final months = List.generate(6, (i) {
            int m = now.month - (5 - i);
            int y = now.year;
            if (m <= 0) { m += 12; y--; }
            return orders.where((o) =>
                o.createdAt.month == m && o.createdAt.year == y).length;
          });
          final maxY = months.fold(0, (a, b) => a > b ? a : b).toDouble() + 2;

          return BarChart(BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).clamp(1, double.infinity),
              getDrawingHorizontalLine: (_) => const FlLine(
                  color: AdminTheme.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(
                          fontSize: 10, color: AdminTheme.textGray)),
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
                          fontSize: 10, color: AdminTheme.textGray),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: months.asMap().entries.map((e) =>
              BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  gradient: LinearGradient(
                    colors: [AdminTheme.primary, AdminTheme.primaryLight],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ])
            ).toList(),
          ));
        }),
      ),
    );
  }
}

// ─── Gráfico de pizza ─────────────────────────────────────────────────────────
class _PieChartCard extends StatelessWidget {
  final AdminController ctrl;
  const _PieChartCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'Distribuição de Prestadores',
      child: Obx(() {
        final all = ctrl.allWorkers;
        final approved = all.where((w) =>
            w.verificationStatus == VerificationStatus.approved).length.toDouble();
        final pending = all.where((w) =>
            w.verificationStatus == VerificationStatus.pending).length.toDouble();
        final suspended = all.where((w) => w.isSuspended).length.toDouble();
        final rejected = all.where((w) =>
            w.verificationStatus == VerificationStatus.rejected).length.toDouble();
        final total = approved + pending + suspended + rejected;

        if (total == 0) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Sem dados ainda',
                style: TextStyle(color: AdminTheme.textGray))),
          );
        }

        pct(double v) => total > 0 ? '${(v / total * 100).toInt()}%' : '';

        return Row(children: [
          // Pizza
          SizedBox(
            width: 140, height: 140,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                if (approved > 0) PieChartSectionData(
                  value: approved, color: AdminTheme.green,
                  title: pct(approved), radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (pending > 0) PieChartSectionData(
                  value: pending, color: AdminTheme.amberLight,
                  title: pct(pending), radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (suspended > 0) PieChartSectionData(
                  value: suspended, color: AdminTheme.red,
                  title: pct(suspended), radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (rejected > 0) PieChartSectionData(
                  value: rejected, color: AdminTheme.textLight,
                  title: pct(rejected), radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            )),
          ),
          const SizedBox(width: 16),
          // Legenda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PieLegend(color: AdminTheme.green,
                    label: 'Ativos', value: approved.toInt()),
                const SizedBox(height: 8),
                _PieLegend(color: AdminTheme.amberLight,
                    label: 'Pendentes', value: pending.toInt()),
                const SizedBox(height: 8),
                _PieLegend(color: AdminTheme.red,
                    label: 'Suspensos', value: suspended.toInt()),
                const SizedBox(height: 8),
                _PieLegend(color: AdminTheme.textLight,
                    label: 'Rejeitados', value: rejected.toInt()),
              ],
            ),
          ),
        ]);
      }),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _PieLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 12, color: AdminTheme.textGray),
          overflow: TextOverflow.ellipsis, maxLines: 1)),
      Text('$value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── Atividades recentes ──────────────────────────────────────────────────────
class _RecentActivities extends StatelessWidget {
  final AdminController ctrl;
  const _RecentActivities({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = ctrl.adminLogs.take(5).toList();
      if (logs.isEmpty) {
        return _EmptyCard(
          icon: Icons.history_rounded,
          message: 'Nenhuma atividade registrada',
          color: AdminTheme.textGray,
        );
      }
      return Column(
        children: logs.map((log) {
          IconData icon;
          Color color;
          final a = log.action.name;
          if (a.contains('approve')) {
            icon = Icons.check_circle_rounded; color = AdminTheme.green;
          } else if (a.contains('reject') || a.contains('ban')) {
            icon = Icons.cancel_rounded; color = AdminTheme.red;
          } else if (a.contains('suspend')) {
            icon = Icons.block_rounded; color = AdminTheme.amber;
          } else if (a.contains('report')) {
            icon = Icons.flag_rounded; color = AdminTheme.red;
          } else {
            icon = Icons.info_rounded; color = AdminTheme.primary;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.action.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${log.adminName} → ${log.targetName}',
                        style: const TextStyle(
                            fontSize: 11, color: AdminTheme.textGray),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(AppFormatters.relativeDate(log.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: AdminTheme.textLight)),
            ]),
          );
        }).toList(),
      );
    });
  }
}

// ─── Denúncias recentes ───────────────────────────────────────────────────────
class _RecentReports extends StatelessWidget {
  final AdminController ctrl;
  const _RecentReports({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reports = ctrl.openReports.take(4).toList();
      if (reports.isEmpty) {
        return _EmptyCard(
          icon: Icons.flag_outlined,
          message: 'Nenhuma denúncia aberta',
          color: AdminTheme.green,
        );
      }
      return Column(
        children: reports.map((r) {
          final isHigh = r.reason == 'Assédio' ||
              r.reason == 'Comportamento inadequado';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHigh
                    ? AdminTheme.red.withOpacity(0.3)
                    : AdminTheme.border,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.reason,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(AppFormatters.date(r.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AdminTheme.textGray)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHigh
                      ? AdminTheme.red.withOpacity(0.1)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHigh ? 'Alta' : 'Normal',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: isHigh ? AdminTheme.red : AdminTheme.amber),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ctrl.currentSection.value = 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Analisar',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          );
        }).toList(),
      );
    });
  }
}

// ─── Notificações ─────────────────────────────────────────────────────────────
class _NotificationsSection extends StatelessWidget {
  final AdminController ctrl;
  const _NotificationsSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = <_NotifData>[];
      if (ctrl.pendingWorkers.isNotEmpty) {
        items.add(_NotifData(
          icon: Icons.engineering_rounded,
          color: AdminTheme.amber,
          title: 'Novo prestador aguardando aprovação',
          sub: '${ctrl.pendingWorkers.length} pendente(s)',
          onTap: () => ctrl.currentSection.value = 1,
        ));
      }
      if (ctrl.openReports.isNotEmpty) {
        items.add(_NotifData(
          icon: Icons.flag_rounded,
          color: AdminTheme.red,
          title: 'Nova denúncia recebida',
          sub: '${ctrl.openReports.length} aberta(s)',
          onTap: () => ctrl.currentSection.value = 6,
        ));
      }
      final lowReviews = ctrl.allReviews.where((r) => r.rating <= 2).length;
      if (lowReviews > 0) {
        items.add(_NotifData(
          icon: Icons.star_outlined,
          color: AdminTheme.red,
          title: 'Avaliação negativa recebida',
          sub: '$lowReviews avaliação(ões) com nota baixa',
          onTap: () => ctrl.currentSection.value = 5,
        ));
      }
      items.add(const _NotifData(
        icon: Icons.support_agent_rounded,
        color: AdminTheme.primary,
        title: 'Solicitação de suporte',
        sub: 'Verifique os pedidos em aberto',
      ));

      if (items.isEmpty) {
        return _EmptyCard(
          icon: Icons.notifications_none_rounded,
          message: 'Nenhuma notificação no momento',
          color: AdminTheme.green,
        );
      }

      return Column(
        children: items.map((n) => GestureDetector(
          onTap: n.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: n.color.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: n.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(n.icon, color: n.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(n.sub,
                        style: const TextStyle(
                            fontSize: 11, color: AdminTheme.textGray),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (n.onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: n.color, size: 18),
            ]),
          ),
        )).toList(),
      );
    });
  }
}

class _NotifData {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  const _NotifData({
    required this.icon, required this.color,
    required this.title, required this.sub, this.onTap,
  });
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AdminTheme.textDark),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text('Ver tudo',
              style: TextStyle(
                  fontSize: 12, color: AdminTheme.primary,
                  fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

class _BaseCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _BaseCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AdminTheme.textDark)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message,
              style: const TextStyle(color: AdminTheme.textGray, fontSize: 13),
              overflow: TextOverflow.ellipsis, maxLines: 2),
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Operação em tempo real (fluxo estilo 99)
// ═══════════════════════════════════════════════════════════════════════════
class _LiveOperationsCard extends StatelessWidget {
  final AdminController ctrl;
  const _LiveOperationsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = ctrl.activeServices;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _LivePill(
                  label: 'Em deslocamento',
                  count: ctrl.servicesEnRoute,
                  color: AdminTheme.primary,
                  icon: Icons.directions_car_rounded),
              const SizedBox(width: 8),
              _LivePill(
                  label: 'No local',
                  count: ctrl.servicesOnSite,
                  color: const Color(0xFF2196F3),
                  icon: Icons.location_on_rounded),
              const SizedBox(width: 8),
              _LivePill(
                  label: 'Em execução',
                  count: ctrl.servicesRunning,
                  color: AdminTheme.purple,
                  icon: Icons.timer_rounded),
            ]),
            const SizedBox(height: 14),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('Nenhum serviço ativo no momento.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AdminTheme.textGray)),
                ),
              )
            else
              ...active.take(6).map((o) => _ActiveServiceTile(order: o)),
          ],
        ),
      );
    });
  }
}

class _LivePill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _LivePill({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.w900)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9.5, color: AdminTheme.textGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

/// Linha de serviço ativo com cronômetro ao vivo quando em execução.
class _ActiveServiceTile extends StatefulWidget {
  final OrderModel order;
  const _ActiveServiceTile({required this.order});

  @override
  State<_ActiveServiceTile> createState() => _ActiveServiceTileState();
}

class _ActiveServiceTileState extends State<_ActiveServiceTile> {
  late final Stream<int> _tick;

  @override
  void initState() {
    super.initState();
    _tick = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  String _elapsed() {
    final started = widget.order.startedAt;
    if (started == null) return '--:--:--';
    final d = DateTime.now().difference(started);
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    Color color;
    String label;
    IconData icon;
    switch (o.status) {
      case OrderStatus.accepted:
        color = AdminTheme.primary;
        label = 'Deslocamento';
        icon = Icons.directions_car_rounded;
        break;
      case OrderStatus.arrived:
        color = const Color(0xFF2196F3);
        label = 'No local';
        icon = Icons.location_on_rounded;
        break;
      default:
        color = AdminTheme.purple;
        label = 'Executando';
        icon = Icons.timer_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${o.serviceCategory} · '
                  '${o.workerName ?? 'Prestador'}',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(o.clientName ?? 'Cliente',
                  style: const TextStyle(
                      fontSize: 11, color: AdminTheme.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (o.status == OrderStatus.inProgress)
          StreamBuilder<int>(
            stream: _tick,
            builder: (_, __) => Text(_elapsed(),
                style: TextStyle(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ])),
          )
        else
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Financeiro da plataforma (KPIs derivados de financial_records)
// ═══════════════════════════════════════════════════════════════════════════
class _PlatformFinanceCard extends StatelessWidget {
  final AdminController ctrl;
  const _PlatformFinanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Obx(() {
      final avgCat = ctrl.avgByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final avgMin = ctrl.avgDurationMinutes;
      final avgLabel = avgMin >= 60
          ? '${avgMin ~/ 60}h ${avgMin % 60}min'
          : '${avgMin}min';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _FinanceStat(
                  label: 'Faturamento bruto',
                  value: money.format(ctrl.grossRevenue),
                  color: AdminTheme.primary),
              _FinanceStat(
                  label: 'Receita da plataforma',
                  value: money.format(ctrl.platformRevenue),
                  color: AdminTheme.green),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _FinanceStat(
                  label: 'Repasse aos prestadores',
                  value: money.format(ctrl.workersNetTotal),
                  color: AdminTheme.amber),
              _FinanceStat(
                  label: 'Serviços concluídos',
                  value: '${ctrl.completedServicesCount}',
                  color: AdminTheme.purple),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _FinanceStat(
                  label: 'Ticket médio',
                  value: money.format(ctrl.avgTicket),
                  color: const Color(0xFF00838F)),
              _FinanceStat(
                  label: 'Tempo médio',
                  value: avgLabel,
                  color: const Color(0xFF5D4037)),
            ]),
            if (avgCat.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Valor médio por categoria',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...avgCat.take(5).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AdminTheme.textGray),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Text(money.format(e.value),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ]),
                  )),
            ],
          ],
        ),
      );
    });
  }
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5, color: AdminTheme.textGray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
