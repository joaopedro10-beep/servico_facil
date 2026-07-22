import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/financial_record_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Tela Financeiro/Carteira do prestador.
///
/// Alimentada em tempo real pela coleção `financial_records` — cada serviço
/// finalizado no fluxo estilo 99 gera automaticamente um registro com
/// duração, valor bruto, comissão da plataforma e valor líquido.
/// Nenhum percentual é fixado no código: os valores vêm congelados de cada
/// registro (snapshot do momento do serviço).
class WorkerFinancialSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerFinancialSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(children: [
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: const Row(children: [
          Expanded(
            child: Text('Carteira',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final records = ctrl.financialRecords;
          final pending = ctrl.financialPendingTotal;
          final paid = ctrl.financialPaidTotal;
          final withdrawn = ctrl.financialWithdrawnTotal;
          final gross = ctrl.financialGrossTotal;
          final net = ctrl.financialNetTotal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Saldo (líquido a receber = pendente + pago) ──────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WTheme.primary, WTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ganhos líquidos (total)',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(money.format(net),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          'Bruto: ${money.format(gross)} · '
                          '${records.length} serviço(s)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Totais por status de pagamento ───────────────────────
                Row(children: [
                  _StatusCard(
                      label: 'Pendente',
                      value: money.format(pending),
                      color: WTheme.amber,
                      icon: Icons.schedule_rounded),
                  const SizedBox(width: 10),
                  _StatusCard(
                      label: 'Pago',
                      value: money.format(paid),
                      color: WTheme.green,
                      icon: Icons.check_circle_rounded),
                  const SizedBox(width: 10),
                  _StatusCard(
                      label: 'Sacado',
                      value: money.format(withdrawn),
                      color: WTheme.blue,
                      icon: Icons.account_balance_rounded),
                ]),
                const SizedBox(height: 22),

                // ── Histórico ────────────────────────────────────────────
                const Text('Histórico de serviços',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),

                if (records.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WTheme.border),
                    ),
                    child: const Column(children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: WTheme.textLight),
                      SizedBox(height: 10),
                      Text('Nenhum serviço finalizado ainda',
                          style: TextStyle(
                              color: WTheme.textGray, fontSize: 13)),
                      SizedBox(height: 4),
                      Text(
                          'Conclua atendimentos para ver seus ganhos aqui.',
                          style: TextStyle(
                              color: WTheme.textLight, fontSize: 12)),
                    ]),
                  )
                else
                  ...records.map((r) => _RecordTile(record: r)),

                const SizedBox(height: 80),
              ],
            ),
          );
        }),
      ),
    ]);
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatusCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: WTheme.textGray)),
        ]),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final FinancialRecordModel record;
  const _RecordTile({required this.record});

  Color get _payColor {
    switch (record.paymentStatus) {
      case PaymentStatus.pending:   return WTheme.amber;
      case PaymentStatus.paid:      return WTheme.green;
      case PaymentStatus.withdrawn: return WTheme.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: WTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: WTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.category,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    '${record.clientName.isEmpty ? 'Cliente' : record.clientName}'
                    ' · ${date.format(record.completedAt)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: WTheme.textGray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _payColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(record.paymentStatus.label,
                style: TextStyle(
                    fontSize: 11,
                    color: _payColor,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: WTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _MiniStat('Tempo', record.durationLabel),
            _MiniStat('Bruto', money.format(record.grossAmount)),
            _MiniStat(
                'Comissão '
                '(${record.platformFeePercent.toStringAsFixed(0)}%)',
                '- ${money.format(record.platformFeeAmount)}'),
            _MiniStat('Líquido', money.format(record.netAmount),
                highlight: true),
          ]),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _MiniStat(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: highlight
                      ? WTheme.primary
                      : WTheme.textDark)),
        ),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 9.5, color: WTheme.textGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
