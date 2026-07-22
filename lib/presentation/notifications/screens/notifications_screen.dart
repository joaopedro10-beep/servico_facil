import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotificationsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: ctrl.markAllRead,
            child: const Text('Marcar todas lidas',
                style:
                    TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator.adaptive());
        }

        if (ctrl.hasError.value) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 12),
              const Text('Não foi possível carregar as notificações.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ctrl.retry,
                child: const Text('Tentar novamente'),
              ),
            ]),
          );
        }

        if (ctrl.notifications.isEmpty) {
          return const _EmptyNotifications();
        }

        return ListView.separated(
          itemCount: ctrl.notifications.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 64),
          itemBuilder: (_, i) {
            final n = ctrl.notifications[i];
            return _NotificationTile(
              item: n,
              onTap: () {
                ctrl.markRead(n.id);
                _navigate(n);
              },
            );
          },
        );
      }),
    );
  }

  void _navigate(NotificationItem n) {
    switch (n.type) {
      case 'new_order':
      case 'order_update':
      case 'order_accepted':
      case 'order_scheduled':
      case 'order_started':
        if (n.targetId != null) {
          Get.toNamed(AppRoutes.orderDetail,
              arguments: {'orderId': n.targetId});
        }
        break;
      case 'new_message':
        if (n.targetId != null) {
          Get.toNamed(AppRoutes.chat,
              arguments: {'chatId': n.targetId});
        }
        break;
      case 'rating_warning':
      case 'cancellation_warning':
        // Já estamos na tela de notificações
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM · HH:mm', 'pt_BR');
    final icon = _iconFor(item.type);
    final color = _colorFor(item.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? null : AppColors.primary.withOpacity(0.04),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(item.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'new_order':
      return Icons.assignment_outlined;
    case 'order_update':
      return Icons.update_outlined;
    case 'new_message':
      return Icons.chat_bubble_outline;
    case 'rating_warning':
      return Icons.star_half_outlined;
    case 'cancellation_warning':
      return Icons.warning_amber_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _colorFor(String type) {
  switch (type) {
    case 'new_order':
      return AppColors.info;
    case 'order_update':
      return AppColors.primary;
    case 'new_message':
      return AppColors.statusInProgress;
    case 'rating_warning':
    case 'cancellation_warning':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Nenhuma notificação',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Suas atualizações de pedidos e mensagens aparecerão aqui.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
