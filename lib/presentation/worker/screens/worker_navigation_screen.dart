import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import '../../../widgets/buttons/slide_to_confirm_button.dart';
import '../controllers/worker_navigation_controller.dart';
import '../widgets/service_route_map.dart';
import 'worker_home_screen.dart' show WTheme;

/// Tela de atendimento em andamento — experiência estilo 99 Motorista.
///
/// • Mapa ocupando praticamente toda a tela com a rota até o cliente
/// • Card inferior fixo: cliente, categoria, endereço, distância, ETA,
///   WhatsApp e ligação
/// • Painel de ganhos ao vivo durante o serviço (tempo, bruto, comissão,
///   líquido) — atualizado a cada segundo
/// • Único Sliding Button grande para avançar o status:
///   accepted → arrived → inProgress → completed
class WorkerNavigationScreen extends StatelessWidget {
  const WorkerNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO GetX: instância única via binding da rota (main.dart)
    final ctrl = Get.find<WorkerNavigationController>();
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: WTheme.background,
      body: Obx(() {
        final o = ctrl.order.value;
        if (o == null) {
          return const Center(
              child: CircularProgressIndicator.adaptive());
        }

        return Stack(children: [
          // ── Mapa em tela cheia ─────────────────────────────────────────
          Positioned.fill(
            child: ctrl.hasDestination
                ? ServiceRouteMap(
                    workerLat: ctrl.workerLat.value,
                    workerLng: ctrl.workerLng.value,
                    clientLat: ctrl.destLat.value,
                    clientLng: ctrl.destLng.value,
                    hasWorkerPosition: ctrl.hasWorkerPosition.value,
                    accentColor: WTheme.primary,
                  )
                : _NoCoordinatesFallback(address: o.address.fullAddress),
          ),

          // ── Topo: voltar + status / painel de ganhos ───────────────────
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(children: [
                  _RoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Get.back(),
                  ),
                  const Spacer(),
                  _StatusChip(status: o.status),
                  // Recusar/devolver o atendimento (só antes de iniciar)
                  if (o.status == OrderStatus.accepted) ...[
                    const SizedBox(width: 8),
                    _RoundButton(
                      icon: Icons.close_rounded,
                      color: WTheme.red,
                      onTap: () => ctrl.refuseAcceptedJob(),
                    ),
                  ],
                ]),
              ),

              // Painel de ganhos ao vivo (apenas durante a execução)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                child: o.status == OrderStatus.inProgress
                    ? _LiveEarningsPanel(
                        key: const ValueKey('earnings'),
                        ctrl: ctrl,
                        money: money,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('no-earnings')),
              ),
            ]),
          ),

          // ── Card inferior fixo ─────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomCard(ctrl: ctrl, order: o, money: money),
          ),
        ]);
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painel de ganhos ao vivo
// ═══════════════════════════════════════════════════════════════════════════
class _LiveEarningsPanel extends StatelessWidget {
  final WorkerNavigationController ctrl;
  final NumberFormat money;
  const _LiveEarningsPanel({super.key, required this.ctrl, required this.money});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xEE0D3D2E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Obx(() {
        // elapsed.value é tocado aqui → painel atualiza a cada segundo
        final _ = ctrl.elapsed.value;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.timer_rounded,
                color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(ctrl.elapsedLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _EarnCol('Bruto', money.format(ctrl.grossNow),
                Colors.white),
            _EarnCol(
                'Comissão (${ctrl.feePercent.value.toStringAsFixed(0)}%)',
                '- ${money.format(ctrl.feeNow)}',
                const Color(0xFFFFAB91)),
            _EarnCol('Você recebe', money.format(ctrl.netNow),
                const Color(0xFF7DE3BC)),
          ]),
        ]);
      }),
    );
  }
}

class _EarnCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _EarnCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card inferior fixo
// ═══════════════════════════════════════════════════════════════════════════
class _BottomCard extends StatelessWidget {
  final WorkerNavigationController ctrl;
  final OrderModel order;
  final NumberFormat money;
  const _BottomCard({
    required this.ctrl,
    required this.order,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Alça
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: WTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Cliente + contato
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: WTheme.primaryLight,
              child: Text(
                (order.clientName?.isNotEmpty == true
                        ? order.clientName![0]
                        : 'C')
                    .toUpperCase(),
                style: const TextStyle(
                    color: WTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.clientName ?? 'Cliente',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Obx(() => Row(children: [
                        Text(order.serviceCategory,
                            style: const TextStyle(
                                fontSize: 12,
                                color: WTheme.textGray)),
                        if (ctrl.clientReviews.value > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          Text(
                              ctrl.clientRating.value
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ])),
                ],
              ),
            ),
            // Chat interno (estilo Uber — nunca abre WhatsApp)
            _RoundButton(
              icon: Icons.forum_rounded,
              color: WTheme.blue,
              onTap: ctrl.openChat,
            ),
            const SizedBox(width: 8),
            // Ligação
            _RoundButton(
              icon: Icons.phone_rounded,
              color: WTheme.primary,
              onTap: ctrl.callClient,
            ),
          ]),
          const SizedBox(height: 12),

          // Endereço + distância + ETA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.location_on_rounded,
                    color: WTheme.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.address.fullAddress,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              if (order.status == OrderStatus.accepted) ...[
                const SizedBox(height: 8),
                Obx(() {
                  // toca observáveis de posição p/ atualizar km/ETA
                  ctrl.workerLat.value;
                  ctrl.workerLng.value;
                  final km = ctrl.distanceKm;
                  final eta = ctrl.etaMinutes;
                  return Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _InfoPill(
                            Icons.route_rounded,
                            km > 0
                                ? '${km.toStringAsFixed(1)} km'
                                : '— km'),
                        _InfoPill(
                            Icons.schedule_rounded,
                            eta > 0 ? '~$eta min' : '— min'),
                        Obx(() => _InfoPill(
                            Icons.payments_rounded,
                            '${money.format(ctrl.hourlyRate.value)}/h')),
                      ]);
                }),
              ],
            ]),
          ),
          const SizedBox(height: 14),

          // ── Sliding Button único (troca de status) ───────────────────
          Obx(() {
            final status = ctrl.order.value?.status;
            if (status == null ||
                !(status == OrderStatus.accepted ||
                    status == OrderStatus.arrived ||
                    status == OrderStatus.inProgress)) {
              return const SizedBox.shrink();
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SlideToConfirmButton(
                key: ValueKey(status),
                label: ctrl.slideLabel,
                color: status == OrderStatus.inProgress
                    ? const Color(0xFFD32F2F)
                    : WTheme.primary,
                icon: status == OrderStatus.inProgress
                    ? Icons.flag_rounded
                    : Icons.chevron_right_rounded,
                loading: ctrl.isWorking.value,
                onConfirmed: ctrl.onSlideConfirmed,
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Auxiliares
// ═══════════════════════════════════════════════════════════════════════════
class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case OrderStatus.accepted:
        label = 'Em deslocamento';
        color = WTheme.primary;
        break;
      case OrderStatus.arrived:
        label = 'No local';
        color = const Color(0xFF2196F3);
        break;
      case OrderStatus.inProgress:
        label = 'Serviço em execução';
        color = const Color(0xFF8B5CF6);
        break;
      case OrderStatus.done:
        label = 'Finalizado';
        color = WTheme.green;
        break;
      default:
        label = 'Aguardando';
        color = WTheme.amber;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8, height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color = WTheme.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: WTheme.textGray),
      const SizedBox(width: 5),
      Text(text,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: WTheme.textDark)),
    ]);
  }
}

class _NoCoordinatesFallback extends StatelessWidget {
  final String address;
  const _NoCoordinatesFallback({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5F0), Color(0xFFF5F7FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 200),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.map_outlined,
                size: 72, color: WTheme.textLight),
            const SizedBox(height: 14),
            const Text('Endereço sem coordenadas',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(address,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: WTheme.textGray)),
          ]),
        ),
      ),
    );
  }
}
