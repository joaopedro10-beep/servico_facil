import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Tela Financeiro/Carteira do prestador.
/// Exibe saldo disponível, pendente, histórico de transações e botão de saque.
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
        child: const Text('Carteira',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),

      Expanded(
        child: Obx(() {
          final done     = ctrl.doneOrders;
          final total    = done.fold(0.0, (s, o) => s + (o.price ?? 0));
          final pending  = ctrl.acceptedOrders.fold(
              0.0, (s, o) => s + (o.price ?? 0));
          final fee      = total * 0.05; // 5% taxa plataforma
          final net      = total - fee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card saldo disponível
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
                      const Text('Saldo disponível',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(money.format(net),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      const SizedBox(height: 4),
                      Text('Saldo pendente: ${money.format(pending)}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Cards de resumo
                Row(children: [
                  Expanded(child: _InfoCard(
                      label: 'Recebido total',
                      value: money.format(total),
                      icon: Icons.account_balance_wallet_rounded,
                      color: WTheme.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoCard(
                      label: 'Taxa plataforma (5%)',
                      value: money.format(fee),
                      icon: Icons.receipt_outlined,
                      color: WTheme.amber)),
                ]),
                const SizedBox(height: 20),

                // Botão solicitar saque
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: net > 0 ? () => _showWithdraw(context, net, money) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.account_balance_rounded, size: 20),
                    label: const Text('Solicitar saque',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),

                // Histórico financeiro
                const Text('Histórico financeiro',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: WTheme.textDark)),
                const SizedBox(height: 10),

                if (done.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WTheme.border),
                    ),
                    child: const Row(children: [
                      Icon(Icons.receipt_long_outlined,
                          color: WTheme.textLight, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nenhuma transação ainda.',
                          style: TextStyle(
                              color: WTheme.textGray, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  )
                else
                  ...done.take(20).map((o) {
                    final fmt2 = DateFormat('dd/MM/yy', 'pt_BR');
                    final date = fmt2.format(
                        o.completedAt ?? o.updatedAt);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WTheme.border),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.check_circle_rounded,
                              color: WTheme.primary, size: 16),
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
                              color: WTheme.primary),
                        ),
                      ]),
                    );
                  }),
              ],
            ),
          );
        }),
      ),
    ]);
  }

  void _showWithdraw(BuildContext ctx, double amount,
      NumberFormat money) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: WTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Solicitar saque',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Disponível: ${money.format(amount)}',
              style: const TextStyle(
                  color: WTheme.textGray, fontSize: 14)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: WTheme.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'O saque será processado em até 2 dias úteis para a conta cadastrada.',
                  style: TextStyle(
                      fontSize: 12,
                      color: WTheme.primary,
                      height: 1.4),
                  overflow: TextOverflow.ellipsis, maxLines: 3,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          SafeArea(
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Saque solicitado!',
                    'Você receberá em até 2 dias úteis.',
                    backgroundColor: WTheme.primary,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Confirmar saque de ${money.format(amount)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: WTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 2),
      ]),
    );
  }
}
