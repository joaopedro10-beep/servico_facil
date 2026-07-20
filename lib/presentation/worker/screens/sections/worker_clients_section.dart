import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Tela Clientes do prestador — duas abas:
///
/// [Clientes Agendados]
///   status == accepted AND scheduledAt != null AND scheduledAt > agora
///   Exibe: nome, endereço, data, horário + botão "Iniciar serviço"
///
/// [Pedidos em Aberto]
///   status == accepted AND scheduledAt == null
///   Pedidos que o prestador aceitou mas ainda não agendou.
///   O prestador clica em "Agendar" → datepicker → Firestore atualiza
///   → cliente recebe notificação automática.
class WorkerClientsSection extends StatefulWidget {
  final WorkerController ctrl;
  const WorkerClientsSection({super.key, required this.ctrl});

  @override
  State<WorkerClientsSection> createState() => _WorkerClientsSectionState();
}

class _WorkerClientsSectionState extends State<WorkerClientsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ────────────────────────────────────────────────────────────
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clientes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // Abas com badges reativos
            Obx(() {
              final sched = widget.ctrl.scheduledOrders.length;
              final open  = widget.ctrl.openOrders.length;
              return TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13),
                tabs: [
                  _TabBadge(label: 'Agendados', count: sched),
                  _TabBadge(
                      label: 'Pedidos em aberto',
                      count: open,
                      badgeColor: open > 0 ? WTheme.amber : null),
                ],
              );
            }),
          ],
        ),
      ),

      // ── Conteúdo ──────────────────────────────────────────────────────────
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _ScheduledClients(ctrl: widget.ctrl),
            _OpenOrders(ctrl: widget.ctrl),
          ],
        ),
      ),
    ]);
  }
}

// ─── Tab com badge ────────────────────────────────────────────────────────────
class _TabBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color? badgeColor;
  const _TabBadge({
    required this.label,
    required this.count,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, overflow: TextOverflow.ellipsis),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor ?? Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 1 — CLIENTES AGENDADOS
// status == accepted + scheduledAt != null + scheduledAt > now
// ═══════════════════════════════════════════════════════════════════════════
class _ScheduledClients extends StatelessWidget {
  final WorkerController ctrl;
  const _ScheduledClients({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.scheduledOrders;

      if (orders.isEmpty) {
        return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_outlined,
                size: 56, color: WTheme.textLight),
            SizedBox(height: 14),
            Text('Nenhum cliente agendado',
                style: TextStyle(
                    color: WTheme.textGray,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text(
              'Os clientes agendados aparecerão aqui\napós você definir data e horário.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WTheme.textLight, fontSize: 12),
            ),
          ]),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ScheduledCard(
            order: orders[i], ctrl: ctrl),
      );
    });
  }
}

class _ScheduledCard extends StatelessWidget {
  final OrderModel order;
  final WorkerController ctrl;
  const _ScheduledCard({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("EEE, dd/MM/yyyy", 'pt_BR');
    final timeFmt = DateFormat("HH:mm", 'pt_BR');
    final now = DateTime.now();

    // Quanto tempo falta
    String timeUntil = '';
    if (order.scheduledAt != null) {
      final diff = order.scheduledAt!.difference(now);
      if (diff.inDays > 0) {
        timeUntil = 'em ${diff.inDays} dia(s)';
      } else if (diff.inHours > 0) {
        timeUntil = 'em ${diff.inHours}h';
      } else if (diff.inMinutes > 0) {
        timeUntil = 'em ${diff.inMinutes} min';
      } else {
        timeUntil = 'agora';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WTheme.primary.withOpacity(0.25)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        // ── Cabeçalho do card ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            // Avatar inicial
            CircleAvatar(
              radius: 24,
              backgroundColor: WTheme.primaryLight,
              child: Text(
                order.clientName?.isNotEmpty == true
                    ? order.clientName![0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: WTheme.primary,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.clientName ?? 'Cliente',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    order.serviceCategory,
                    style: const TextStyle(
                        fontSize: 12, color: WTheme.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge "em X h"
            if (timeUntil.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timeUntil,
                    style: const TextStyle(
                        fontSize: 10,
                        color: WTheme.primary,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
        ),

        // ── Divider ───────────────────────────────────────────────────
        const Divider(height: 1, indent: 14, endIndent: 14),

        // ── Infos: data, horário, telefone, endereço ──────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(children: [
            // Data
            if (order.scheduledAt != null) ...[
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                color: WTheme.primary,
                text: dateFmt.format(order.scheduledAt!),
              ),
              const SizedBox(height: 6),
              // Horário
              _InfoRow(
                icon: Icons.access_time_rounded,
                color: WTheme.primary,
                text: timeFmt.format(order.scheduledAt!),
                bold: true,
              ),
              const SizedBox(height: 6),
            ],
            // Endereço
            _InfoRow(
              icon: Icons.location_on_outlined,
              color: WTheme.textLight,
              text: order.address.fullAddress,
            ),
          ]),
        ),

        // ── Ações ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            // Chat
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(AppRoutes.chat, arguments: order),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: WTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: WTheme.textGray),
                label: const Text('Chat',
                    style: TextStyle(
                        fontSize: 13, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            // Iniciar serviço
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _confirmStart(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded,
                    size: 18, color: Colors.white),
                label: const Text('Iniciar serviço',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _confirmStart(
      BuildContext ctx, OrderModel order) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Iniciar serviço'),
        content: Text(
          'Confirmar início do serviço de\n'
          '${order.serviceCategory} para ${order.clientName ?? "o cliente"}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: WTheme.primary),
            child: const Text('Iniciar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await ctrl.startOrder(order);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABA 2 — PEDIDOS EM ABERTO (aceitos sem agendamento)
// ═══════════════════════════════════════════════════════════════════════════
class _OpenOrders extends StatelessWidget {
  final WorkerController ctrl;
  const _OpenOrders({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.openOrders;

      if (orders.isEmpty) {
        return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: WTheme.textLight),
            SizedBox(height: 14),
            Text('Nenhum pedido em aberto',
                style: TextStyle(
                    color: WTheme.textGray,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text(
              'Pedidos aceitos ainda sem data agendada\naparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WTheme.textLight, fontSize: 12),
            ),
          ]),
        );
      }

      return Column(children: [
        // Banner informativo
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          color: WTheme.amber.withOpacity(0.09),
          child: Row(children: [
            const Icon(Icons.schedule_rounded,
                color: WTheme.amber, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${orders.length} pedido(s) aguardando agendamento',
                style: const TextStyle(
                    fontSize: 12,
                    color: WTheme.amber,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _OpenOrderCard(order: orders[i], ctrl: ctrl),
          ),
        ),
      ]);
    });
  }
}

class _OpenOrderCard extends StatelessWidget {
  final OrderModel order;
  final WorkerController ctrl;
  const _OpenOrderCard({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final createdFmt = DateFormat('dd/MM/yy · HH:mm', 'pt_BR');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        // ── Cabeçalho ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: WTheme.primaryLight,
              child: Text(
                order.clientName?.isNotEmpty == true
                    ? order.clientName![0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: WTheme.primary,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.clientName ?? 'Cliente',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    order.serviceCategory,
                    style: const TextStyle(
                        fontSize: 12, color: WTheme.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: WTheme.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: WTheme.amber.withOpacity(0.3)),
              ),
              child: const Text('Sem data',
                  style: TextStyle(
                      fontSize: 10,
                      color: WTheme.amber,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        const Divider(height: 1, indent: 14, endIndent: 14),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(children: [
            // Descrição
            if (order.description.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  order.description,
                  style: const TextStyle(
                      fontSize: 13, color: WTheme.textGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Endereço
            _InfoRow(
              icon: Icons.location_on_outlined,
              color: WTheme.textLight,
              text: order.address.fullAddress,
            ),
            const SizedBox(height: 6),
            // Data de abertura
            _InfoRow(
              icon: Icons.access_time_rounded,
              color: WTheme.textLight,
              text: 'Aberto em ${createdFmt.format(order.createdAt)}',
            ),
          ]),
        ),

        // ── Ações ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(AppRoutes.chat, arguments: order),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: WTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: WTheme.textGray),
                label: const Text('Chat',
                    style: TextStyle(
                        fontSize: 13, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showScheduleDialog(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Colors.white),
                label: const Text('Agendar',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  /// Agendar: datepicker → timepicker → scheduleOrder → notifica cliente
  /// → Firestore atualiza → Obx redesenha ambas as abas automaticamente
  Future<void> _showScheduleDialog(
      BuildContext ctx, OrderModel order) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: ctx,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Selecione a data do serviço',
    );
    if (date == null || !ctx.mounted) return;

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(
          hour: now.add(const Duration(hours: 2)).hour,
          minute: 0),
      helpText: 'Selecione o horário',
    );
    if (time == null || !ctx.mounted) return;

    final scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    // scheduleOrder atualiza Firestore + envia notificação ao cliente
    // O Obx reage automaticamente via stream watchWorkerOrders:
    //   - pedido sai de openOrders (scheduledAt deixa de ser null)
    //   - pedido entra em scheduledOrders (aba Agendados)
    await ctrl.scheduleOrder(order, scheduledAt);

    if (ctx.mounted) {
      Get.snackbar(
        'Agendamento confirmado!',
        'Cliente notificado. Serviço em '
        '${DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(scheduledAt)}.',
        backgroundColor: WTheme.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

// ─── Widget auxiliar — linha de informação ────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool bold;
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
              fontSize: 12,
              color: bold ? WTheme.textDark : WTheme.textGray,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w400),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    ]);
  }
}
