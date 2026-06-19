import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../controllers/order_controller.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final initialOrder = args['order'] as OrderModel;
    final isWorker = args['isWorker'] as bool? ?? false;

    final ctrl = Get.find<OrderController>()
      ..watchOrder(initialOrder.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do pedido'),
        actions: [
          Obx(() {
            final o = ctrl.currentOrder.value ?? initialOrder;
            return IconButton(
              tooltip: 'Abrir chat',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => ctrl.openChat(o.id),
            );
          }),
        ],
      ),
      body: Obx(() {
        final order = ctrl.currentOrder.value ?? initialOrder;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Timeline ────────────────────────────────────────────────
            _buildTimeline(order),
            const SizedBox(height: 20),

            // ── Dados do serviço ─────────────────────────────────────────
            _buildServiceInfo(order),
            const SizedBox(height: 20),

            // ── Fotos ────────────────────────────────────────────────────
            if (order.photoUrls.isNotEmpty) ...[
              _buildPhotosSection(order),
              const SizedBox(height: 20),
            ],

            // ── Endereço ─────────────────────────────────────────────────
            _buildAddressSection(order),
            const SizedBox(height: 28),

            // ── Ações ────────────────────────────────────────────────────
            if (isWorker)
              _buildWorkerActions(context, ctrl, order)
            else
              _buildClientActions(context, ctrl, order),
          ],
        );
      }),
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline(OrderModel order) {
    final steps = _timelineSteps(order);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acompanhamento',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((e) {
              final isLast = e.key == steps.length - 1;
              return _TimelineStep(
                step: e.value,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_StepData> _timelineSteps(OrderModel order) {
    final isCancelled = order.status == OrderStatus.cancelled;

    if (isCancelled) {
      return [
        _StepData(
          label: 'Solicitado',
          icon: Icons.send_rounded,
          timestamp: order.createdAt,
          isDone: true,
          isActive: false,
        ),
        _StepData(
          label: 'Cancelado',
          icon: Icons.cancel_outlined,
          timestamp: order.cancelledAt,
          isDone: true,
          isActive: false,
          isCancelled: true,
        ),
      ];
    }

    return [
      _StepData(
        label: 'Solicitado',
        icon: Icons.send_rounded,
        timestamp: order.createdAt,
        isDone: true,
        isActive: order.status == OrderStatus.pending,
      ),
      _StepData(
        label: 'Aceito',
        icon: Icons.check_circle_outline,
        timestamp: order.acceptedAt,
        isDone: order.status != OrderStatus.pending,
        isActive: order.status == OrderStatus.accepted,
      ),
      _StepData(
        label: 'Em andamento',
        icon: Icons.engineering_outlined,
        timestamp: order.startedAt,
        isDone: order.status == OrderStatus.inProgress ||
            order.status == OrderStatus.done,
        isActive: order.status == OrderStatus.inProgress,
      ),
      _StepData(
        label: 'Concluído',
        icon: Icons.celebration_outlined,
        timestamp: order.completedAt,
        isDone: order.status == OrderStatus.done,
        isActive: order.status == OrderStatus.done,
      ),
    ];
  }

  // ─── Info do serviço ──────────────────────────────────────────────────────

  Widget _buildServiceInfo(OrderModel order) {
    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados do serviço',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.handyman_outlined,
                label: 'Categoria',
                value: order.serviceCategory),
            _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Data/hora',
                value: fmt.format(order.scheduledAt)),
            if (order.price != null)
              _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Valor',
                  value:
                      'R\$ ${order.price!.toStringAsFixed(2).replaceAll('.', ',')}'),
            const Divider(height: 20),
            const Text('Descrição',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(order.description,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ─── Fotos ────────────────────────────────────────────────────────────────

  Widget _buildPhotosSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fotos (${order.photoUrls.length})',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _showPhoto(context, order.photoUrls[i]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: order.photoUrls[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Endereço ─────────────────────────────────────────────────────────────

  Widget _buildAddressSection(OrderModel order) {
    final addr = order.address;
    final display = addr.street.isNotEmpty
        ? '${addr.street}${addr.city.isNotEmpty ? ", ${addr.city}" : ""}'
        : 'Endereço não informado';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Local do serviço',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(display,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ações do cliente ─────────────────────────────────────────────────────

  Widget _buildClientActions(
      BuildContext context, OrderController ctrl, OrderModel order) {
    if (!order.isActive) return const SizedBox.shrink();
    return Column(
      children: [
        if (order.canClientCancel)
          Obx(() => OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: ctrl.isSaving.value
                    ? null
                    : () => _confirmCancel(context, ctrl),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar pedido'),
              )),
      ],
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, OrderController ctrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text(
            'Tem certeza que deseja cancelar esta solicitação?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Não')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sim, cancelar',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) ctrl.cancelOrder();
  }

  // ─── Ações do trabalhador ─────────────────────────────────────────────────

  Widget _buildWorkerActions(
      BuildContext context, OrderController ctrl, OrderModel order) {
    return Obx(() => Column(
          children: [
            if (order.canWorkerAccept) ...[
              ElevatedButton.icon(
                onPressed:
                    ctrl.isSaving.value ? null : ctrl.acceptOrder,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aceitar pedido'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed:
                    ctrl.isSaving.value ? null : ctrl.refuseOrder,
                icon: const Icon(Icons.close),
                label: const Text('Recusar'),
              ),
            ],
            if (order.canWorkerStart)
              ElevatedButton.icon(
                onPressed:
                    ctrl.isSaving.value ? null : ctrl.startOrder,
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Iniciar serviço'),
              ),
            if (order.canWorkerComplete)
              ElevatedButton.icon(
                onPressed: ctrl.isSaving.value
                    ? null
                    : () => _confirmComplete(context, ctrl),
                icon: const Icon(Icons.celebration_outlined),
                label: const Text('Concluir serviço'),
              ),
          ],
        ));
  }

  Future<void> _confirmComplete(
      BuildContext context, OrderController ctrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Concluir serviço?'),
        content: const Text(
            'Confirme que o serviço foi finalizado. O cliente receberá uma notificação para avaliar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar conclusão')),
        ],
      ),
    );
    if (confirm == true) ctrl.completeOrder();
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _StepData {
  final String label;
  final IconData icon;
  final DateTime? timestamp;
  final bool isDone;
  final bool isActive;
  final bool isCancelled;

  const _StepData({
    required this.label,
    required this.icon,
    this.timestamp,
    required this.isDone,
    required this.isActive,
    this.isCancelled = false,
  });
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});
  final _StepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.isCancelled
        ? AppColors.error
        : step.isDone
            ? AppColors.primary
            : AppColors.textHint;

    final fmt = DateFormat('dd/MM HH:mm', 'pt_BR');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone + linha vertical
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(step.isDone ? 1 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon,
                  color: step.isDone ? Colors.white : color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: step.isDone
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Label + timestamp
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: step.isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: step.isDone
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                if (step.timestamp != null)
                  Text(
                    fmt.format(step.timestamp!),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                if (step.isActive && !step.isDone)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Atual',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
