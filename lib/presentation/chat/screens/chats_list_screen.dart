import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = Get.find<FirestoreDatasource>();
    final fb = Get.find<FirebaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ds.watchChatList(fb.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator.adaptive());
          }

          final chats = snap.data ?? [];
          if (chats.isEmpty) {
            return const _EmptyChats();
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) => _ChatTile(chat: chats[i]),
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});
  final Map<String, dynamic> chat;

  @override
  Widget build(BuildContext context) {
    final fb = Get.find<FirebaseService>();
    final chatId = chat['id'] as String? ?? '';
    final lastMsg = chat['lastMessage'] as String? ?? '';
    final lastMsgAt = chat['lastMessageAt'];
    final participants =
        List<String>.from(chat['participants'] ?? []);

    // Determina o outro participante
    final otherId =
        participants.firstWhere((p) => p != fb.uid, orElse: () => '');
    final otherName = chat['otherName'] as String? ?? 'Usuário';
    final otherPhoto = chat['otherPhotoUrl'] as String?;
    final unreadCount = chat['unreadCount_${fb.uid}'] as int? ?? 0;

    String timeLabel = '';
    if (lastMsgAt != null) {
      try {
        final dt = (lastMsgAt as dynamic).toDate() as DateTime;
        final now = DateTime.now();
        if (dt.day == now.day &&
            dt.month == now.month &&
            dt.year == now.year) {
          timeLabel = DateFormat('HH:mm').format(dt);
        } else {
          timeLabel = DateFormat('dd/MM').format(dt);
        }
      } catch (_) {}
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.border,
        child: otherPhoto != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: otherPhoto,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, color: AppColors.textHint),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(otherName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text(timeLabel,
              style: TextStyle(
                fontSize: 11,
                color: unreadCount > 0
                    ? AppColors.primary
                    : AppColors.textHint,
                fontWeight: unreadCount > 0
                    ? FontWeight.w700
                    : FontWeight.normal,
              )),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMsg.isEmpty ? 'Toque para conversar' : lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: unreadCount > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      onTap: () => Get.toNamed(AppRoutes.chat, arguments: {
        'chatId': chatId,
        'otherUserId': otherId,
        'otherName': otherName,
        'otherPhotoUrl': otherPhoto,
        'otherIsWorker': chat['otherIsWorker'] as bool? ?? false,
      }),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Nenhuma conversa ainda',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Suas conversas com profissionais aparecem aqui após solicitar um serviço.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
