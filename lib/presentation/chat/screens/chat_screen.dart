import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/message_model.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO GetX: controller vem do binding da rota (main.dart).
    // Get.put dentro do build recriava o controller a cada rebuild,
    // reiniciando streams e causando erros de lifecycle.
    final ctrl = Get.find<ChatController>();

    return Scaffold(
      appBar: _buildAppBar(ctrl),
      body: Column(
        children: [
          // ── Aviso de segurança fixo ──────────────────────────────────
          _buildSecurityBanner(),

          // ── Mensagens ────────────────────────────────────────────────
          Expanded(child: _buildMessageList(ctrl)),

          // ── Input ────────────────────────────────────────────────────
          _buildInput(ctrl),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ChatController ctrl) {
    return AppBar(
      leadingWidth: 32,
      titleSpacing: 0,
      title: Obx(() => Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.border,
                    child: ctrl.otherPhotoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: ctrl.otherPhotoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.person,
                            color: AppColors.textHint),
                  ),
                  if (ctrl.isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctrl.otherName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (ctrl.otherIsTyping.value)
                    const Text('digitando…',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.normal,
                        ))
                  else if (ctrl.onlineStatus.isNotEmpty)
                    Text(ctrl.onlineStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: ctrl.isOnline
                              ? AppColors.success
                              : AppColors.textHint,
                          fontWeight: FontWeight.normal,
                        )),
                ],
              ),
            ],
          )),
    );
  }

  // ── Aviso de segurança ────────────────────────────────────────────────────

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nunca faça pagamentos fora do app. Em caso de problema, use o botão Denunciar.',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
    }
  }

  // ── Lista de mensagens ────────────────────────────────────────────────────

  Widget _buildMessageList(ChatController ctrl) {
    return Obx(() {
      if (ctrl.isLoadingMessages.value) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      if (ctrl.messages.isEmpty) {
        return const Center(
          child: Text('Nenhuma mensagem ainda.\nDiga olá! 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 14)),
        );
      }

      return ListView.builder(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: ctrl.messages.length,
        reverse: false,
        itemBuilder: (context, i) {
          final msg = ctrl.messages[i];
          final isMe = msg.senderId == ctrl.currentUid;
          final dateLabel = ctrl.dateLabelFor(i);

          return Column(
            children: [
              if (dateLabel != null) _DateSeparator(label: dateLabel),
              _MessageBubble(msg: msg, isMe: isMe),
            ],
          );
        },
      );
    });
  }

  // ── Input ─────────────────────────────────────────────────────────────────

  Widget _buildInput(ChatController ctrl) {
    return Obx(() {
      // Conversa encerrada automaticamente quando o serviço finaliza
      if (ctrl.isConversationClosed.value) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Serviço finalizado — esta conversa foi encerrada.',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botão de imagem
            Obx(() => IconButton(
                  icon: ctrl.isSendingImage.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2))
                      : const Icon(Icons.image_outlined,
                          color: AppColors.primary),
                  onPressed: ctrl.isSendingImage.value
                      ? null
                      : ctrl.sendImage,
                )),

            // Campo de texto
            Expanded(
              child: TextField(
                controller: ctrl.messageCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Mensagem...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => ctrl.sendText(),
              ),
            ),

            // Botão enviar
            IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: AppColors.primary),
              onPressed: ctrl.sendText,
            ),
          ],
        ),
      ),
    );
  });
}

// ─── Bolha de mensagem ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});
  final MessageModel msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(msg.createdAt);
    final bubbleColor = isMe
        ? AppColors.primary.withOpacity(0.15)
        : Colors.white;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft:
          isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight:
          isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: isMe
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1))
          ],
        ),
        child: Padding(
          padding: msg.isImageMessage
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Conteúdo
              if (msg.isImageMessage)
                ClipRRect(
                  borderRadius: borderRadius,
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 150,
                      color: AppColors.border,
                      child: const Center(
                          child: CircularProgressIndicator.adaptive()),
                    ),
                  ),
                )
              else
                Text(msg.content ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),

              // Timestamp + ticks (só minhas)
              Padding(
                padding: msg.isImageMessage
                    ? const EdgeInsets.fromLTRB(8, 4, 8, 6)
                    : const EdgeInsets.only(top: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint)),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      _DoubleCheck(isRead: msg.isRead),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tick duplo ────────────────────────────────────────────────────────────────

class _DoubleCheck extends StatelessWidget {
  const _DoubleCheck({required this.isRead});
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead ? AppColors.info : AppColors.textHint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 13, color: color),
        Transform.translate(
          offset: const Offset(-6, 0),
          child: Icon(Icons.check, size: 13, color: color),
        ),
      ],
    );
  }
}

// ─── Separador de data ────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary)),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
