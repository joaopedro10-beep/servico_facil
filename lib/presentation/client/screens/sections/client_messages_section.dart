// ═══════════════════════════════════════════════════════════════════════════
// BUSCAR
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/client_controller.dart';
import '../client_home_screen.dart' show CTheme;



// ═══════════════════════════════════════════════════════════════════════════
// MENSAGENS
// ═══════════════════════════════════════════════════════════════════════════


class ClientMessagesSection extends StatelessWidget {
  final ClientController ctrl;
  const ClientMessagesSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // Lista fictícia baseada nos pedidos com status ativo
    return Column(children: [
      Container(
        color: CTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: const Row(children: [
          Expanded(
            child: Text('Mensagens',
                style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          Icon(Icons.edit_outlined, color: Colors.white70, size: 22),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final orders = ctrl.myOrders
              .where((o) =>
                  o.status != OrderStatus.cancelled)
              .toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 54, color: CTheme.textLight),
                const SizedBox(height: 12),
                const Text('Nenhuma conversa ainda.',
                    style: TextStyle(color: CTheme.textGray, fontSize: 14)),
              ]),
            );
          }

          // Adiciona um item de suporte ao final
          final items = [...orders];
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length + 1,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 70),
            itemBuilder: (_, i) {
              if (i == items.length) {
                return _ChatTile(
                  avatar: '🛡️',
                  name: 'Suporte Serviço Fácil',
                  lastMessage: 'Como podemos ajudar?',
                  time: '3 dias',
                  unread: 0,
                  isSupport: true,
                );
              }
              final o = items[i];
              return _ChatTile(
                avatar: o.workerName?.isNotEmpty == true
                    ? o.workerName![0].toUpperCase()
                    : 'P',
                name: o.workerName ?? 'Prestador',
                lastMessage: _lastMessage(o),
                time: _formatTime(o.updatedAt),
                unread: o.status == OrderStatus.inProgress ? 1 : 0,
                onTap: () => Get.toNamed(AppRoutes.chat, arguments: o),
              );
            },
          );
        }),
      ),
    ]);
  }

  String _lastMessage(OrderModel o) {
    switch (o.status) {
      case OrderStatus.pending:    return 'Aguardando confirmação...';
      case OrderStatus.accepted:   return 'Serviço confirmado!';
      case OrderStatus.arrived:    return 'Cheguei ao local! 📍';
      case OrderStatus.inProgress: return 'Cheguei aqui e já vou iniciar o serviço...';
      case OrderStatus.done:       return 'Serviço concluído com sucesso 👍';
      case OrderStatus.cancelled:  return 'Solicitação cancelada';
    }
  }

  String _formatTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias';
  }
}

class _ChatTile extends StatelessWidget {
  final String avatar;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isSupport;
  final VoidCallback? onTap;

  const _ChatTile({
    required this.avatar,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isSupport = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Get.toNamed(AppRoutes.chatsList),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isSupport
                ? CTheme.blue.withOpacity(0.15)
                : CTheme.blueLight,
            child: Text(
              avatar,
              style: TextStyle(
                  fontSize: isSupport ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: CTheme.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(lastMessage,
                    style: TextStyle(
                        fontSize: 12,
                        color: unread > 0
                            ? CTheme.textDark
                            : CTheme.textGray,
                        fontWeight: unread > 0
                            ? FontWeight.w600
                            : FontWeight.w400),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time,
                  style: TextStyle(
                      fontSize: 11,
                      color: unread > 0 ? CTheme.blue : CTheme.textLight)),
              const SizedBox(height: 4),
              if (unread > 0)
                Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: CTheme.blue, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$unread',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERFIL
// ═══════════════════════════════════════════════════════════════════════════

