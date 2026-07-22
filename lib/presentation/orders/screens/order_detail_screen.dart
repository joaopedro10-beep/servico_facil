import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/order_model.dart';
import '../../worker/widgets/service_route_map.dart';
import '../controllers/order_controller.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // CORREÇÃO DEFINITIVA (GetX): parsing de argumentos e watchOrder saíram
  // do build. Antes, cada rebuild cancelava e recriava o stream do pedido;
  // como o Firestore reemite o snapshot imediatamente no listen, isso
  // realimentava o Obx e gerava o loop/erro de GetX ao abrir os Detalhes
  // pela notificação. Efeitos colaterais agora rodam UMA vez, no initState.
  OrderModel? initialOrder;
  String resolvedOrderId = '';
  bool? isWorkerArg;
  late final OrderController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<OrderController>();

    final args = Get.arguments;
    String? orderId;
    if (args is OrderModel) {
      initialOrder = args;
    } else if (args is String) {
      orderId = args;
    } else if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      initialOrder = map['order'] as OrderModel?;
      orderId = map['orderId'] as String? ?? initialOrder?.id;
      isWorkerArg = map['isWorker'] as bool?;
    }
    resolvedOrderId = orderId ?? initialOrder?.id ?? '';

    if (resolvedOrderId.isNotEmpty) {
      ctrl.watchOrder(resolvedOrderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Get.find<FirebaseService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do pedido'),
        actions: [
          Obx(() {
            final o = ctrl.currentOrder.value ?? initialOrder;
            if (o == null) return const SizedBox.shrink();
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

        if (order == null) {
          // Ainda carregando pelo id (ou id inválido)
          if (resolvedOrderId.isEmpty) {
            return const Center(
              child: Text('Pedido não encontrado.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return const Center(
              child: CircularProgressIndicator.adaptive());
        }

        // Se 'isWorker' não veio nos argumentos, infere pelo usuário logado
        final isWorker = isWorkerArg ??
            (order.workerId != null &&
                order.workerId!.isNotEmpty &&
                order.workerId == uid);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Rastreamento ao vivo (cliente acompanha o prestador) ────
            if (!isWorker && order.isOngoing) ...[
              _LiveTrackingCard(order: order),
              const SizedBox(height: 20),
            ],

            // ── Timeline ────────────────────────────────────────────────
            _buildTimeline(order),
            const SizedBox(height: 20),

            // ── Dados do serviço ─────────────────────────────────────────
            _buildServiceInfo(order),
            const SizedBox(height: 20),

            // ── Resumo financeiro (após a conclusão) ─────────────────────
            if (order.grossAmount != null) ...[
              _buildFinancialSummary(order),
              const SizedBox(height: 20),
            ],

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

    // Barra de progresso estilo apps de transporte:
    // Prestador aceitou → Em deslocamento → Chegou ao local →
    // Serviço em execução → Serviço finalizado
    final s = order.status;
    final afterAccept = s == OrderStatus.accepted ||
        s == OrderStatus.arrived ||
        s == OrderStatus.inProgress ||
        s == OrderStatus.done;
    final afterArrive = s == OrderStatus.arrived ||
        s == OrderStatus.inProgress ||
        s == OrderStatus.done;
    final afterStart =
        s == OrderStatus.inProgress || s == OrderStatus.done;

    return [
      _StepData(
        label: order.status == OrderStatus.pending
            ? 'Buscando profissional'
            : 'Prestador aceitou',
        icon: Icons.check_circle_outline,
        timestamp: order.acceptedAt ?? order.createdAt,
        isDone: afterAccept,
        isActive: s == OrderStatus.pending,
      ),
      _StepData(
        label: 'Em deslocamento',
        icon: Icons.directions_car_outlined,
        timestamp: order.acceptedAt,
        isDone: afterArrive,
        isActive: s == OrderStatus.accepted,
      ),
      _StepData(
        label: 'Chegou ao local',
        icon: Icons.location_on_outlined,
        timestamp: order.arrivedAt,
        isDone: afterStart,
        isActive: s == OrderStatus.arrived,
      ),
      _StepData(
        label: 'Serviço em execução',
        icon: Icons.engineering_outlined,
        timestamp: order.startedAt,
        isDone: s == OrderStatus.done,
        isActive: s == OrderStatus.inProgress,
      ),
      _StepData(
        label: 'Serviço finalizado',
        icon: Icons.celebration_outlined,
        timestamp: order.completedAt,
        isDone: s == OrderStatus.done,
        isActive: s == OrderStatus.done,
      ),
    ];
  }

  // ─── Resumo financeiro ────────────────────────────────────────────────────

  Widget _buildFinancialSummary(OrderModel order) {
    final money =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String duration() {
      final m = order.durationMinutes ?? 0;
      final h = m ~/ 60;
      final min = m % 60;
      if (h == 0) return '${min}min';
      if (min == 0) return '${h}h';
      return '${h}h ${min}min';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo financeiro',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Tempo trabalhado',
                value: duration()),
            if (order.hourlyRate != null)
              _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Valor da hora',
                  value: money.format(order.hourlyRate)),
            _InfoRow(
                icon: Icons.attach_money_rounded,
                label: 'Valor bruto',
                value: money.format(order.grossAmount)),
            if (order.platformFeeAmount != null)
              _InfoRow(
                  icon: Icons.percent_rounded,
                  label:
                      'Comissão (${order.platformFeePercent?.toStringAsFixed(0) ?? '-'}%)',
                  value: '- ${money.format(order.platformFeeAmount)}'),
            if (order.netAmount != null)
              _InfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Líquido do prestador',
                  value: money.format(order.netAmount)),
          ],
        ),
      ),
    );
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
                value: order.scheduledAt != null
                    ? fmt.format(order.scheduledAt!)
                    : 'Aguardando agendamento'),
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
            // Botão Agendar: aparece quando accepted e ainda sem scheduledAt
            if (order.status == OrderStatus.accepted &&
                order.scheduledAt == null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: ctrl.isSaving.value
                    ? null
                    : () => _pickSchedule(context, ctrl),
                icon: const Icon(Icons.calendar_today_rounded),
                label: const Text('Agendar serviço'),
              ),
              const SizedBox(height: 10),
            ],
            // No novo fluxo, as mudanças de status do atendimento
            // (chegada, início, finalização) acontecem SOMENTE pelo botão
            // deslizante na tela de navegação — aqui apenas redirecionamos.
            if (order.isOngoing)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Get.toNamed(
                    AppRoutes.workerNavigation,
                    arguments: {'orderId': order.id}),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Abrir atendimento (mapa)'),
              ),
          ],
        ));
  }

  Future<void> _pickSchedule(
      BuildContext context, OrderController ctrl) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Data do serviço',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: now.add(const Duration(hours: 2)).hour, minute: 0),
      helpText: 'Horário do serviço',
    );
    if (time == null || !context.mounted) return;

    final scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    await ctrl.scheduleOrder(scheduledAt);
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


// ═══════════════════════════════════════════════════════════════════════════
// Rastreamento ao vivo (estilo apps de transporte)
// O prestador publica workerLat/workerLng/workerSpeedKmh no pedido durante
// o deslocamento; este card acompanha via o MESMO stream do pedido —
// tudo em tempo real, sem refresh manual.
// ═══════════════════════════════════════════════════════════════════════════
class _LiveTrackingCard extends StatefulWidget {
  final OrderModel order;
  const _LiveTrackingCard({required this.order});

  @override
  State<_LiveTrackingCard> createState() => _LiveTrackingCardState();
}

class _LiveTrackingCardState extends State<_LiveTrackingCard> {
  OrderModel get order => widget.order;
  double? _destLat;
  double? _destLng;

  @override
  void initState() {
    super.initState();
    _resolveDest();
  }

  Future<void> _resolveDest() async {
    if (order.address.lat != 0 || order.address.lng != 0) {
      _destLat = order.address.lat;
      _destLng = order.address.lng;
      if (mounted) setState(() {});
      return;
    }
    // Endereço sem coordenadas → geocodifica (mesma correção do mapa
    // do prestador)
    final r = await GeocodingService.geocode(order.address.fullAddress);
    if (r != null && mounted) {
      setState(() {
        _destLat = r.$1;
        _destLng = r.$2;
      });
    }
  }

  double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.accepted:   return 'A caminho';
      case OrderStatus.arrived:    return 'Chegou ao local';
      case OrderStatus.inProgress: return 'Em atendimento';
      case OrderStatus.done:       return 'Finalizado';
      default:                     return 'Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWorkerPos =
        order.workerLat != null && order.workerLng != null;
    final hasDest = _destLat != null && _destLng != null;

    double? km;
    int? etaMin;
    if (hasWorkerPos && hasDest) {
      km = _haversineKm(
          order.workerLat!, order.workerLng!, _destLat!, _destLng!);
      etaMin = math.max(1, (km / 30.0 * 60).round());
    }
    final speed = order.workerSpeedKmh ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 220,
          child: !hasDest
              ? const Center(
                  child: CircularProgressIndicator.adaptive())
              : ServiceRouteMap(
                  workerLat: order.workerLat ?? 0,
                  workerLng: order.workerLng ?? 0,
                  clientLat: _destLat!,
                  clientLng: _destLng!,
                  hasWorkerPosition: hasWorkerPos,
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: _TrackStat(
                  icon: Icons.route_rounded,
                  label: 'Distância',
                  value: km != null
                      ? '${km.toStringAsFixed(1)} km'
                      : '—'),
            ),
            Expanded(
              child: _TrackStat(
                  icon: Icons.schedule_rounded,
                  label: 'Chegada',
                  value: etaMin != null ? '~$etaMin min' : '—'),
            ),
            Expanded(
              child: _TrackStat(
                  icon: Icons.speed_rounded,
                  label: 'Velocidade',
                  value: speed > 1
                      ? '${speed.toStringAsFixed(0)} km/h'
                      : '—'),
            ),
            Expanded(
              child: _TrackStat(
                  icon: Icons.local_shipping_rounded,
                  label: 'Status',
                  value: _statusLabel),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TrackStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _TrackStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      Text(label,
          style: const TextStyle(
              fontSize: 9.5, color: AppColors.textHint)),
    ]);
  }
}
