import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/order_model.dart';

class ChatController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final _picker = ImagePicker();

  // ── Estado ────────────────────────────────────────────────────────────────
  final messages = <MessageModel>[].obs;
  final isLoadingMessages = true.obs;
  final isSendingImage = false.obs;
  final otherUserLastSeen = Rxn<DateTime>();
  final initError = ''.obs; // erro ao resolver os dados do chat

  // Chat IDs
  late String chatId;
  String otherUserId = '';
  bool otherIsWorker = false;
  String otherName = 'Usuário';
  String? otherPhotoUrl;

  final messageCtrl = TextEditingController();
  StreamSubscription? _msgSub;
  StreamSubscription? _lastSeenSub;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // CORREÇÃO: a tela de chat era aberta com formatos diferentes de
    // argumento (String com o id do pedido, Map completo, Map só com
    // 'chatId' vindo de notificações) e quebrava com cast inválido.
    // Agora qualquer formato é aceito; dados faltantes são resolvidos
    // a partir do pedido/chat no Firestore (chatId == orderId).
    final args = Get.arguments;

    if (args is String) {
      chatId = args;
    } else if (args is OrderModel) {
      // Algumas telas passam o pedido inteiro
      chatId = args.id;
      final uid = _fb.currentUser?.uid ?? '';
      final amClient = args.userId == uid;
      otherIsWorker = amClient;
      otherUserId = amClient ? (args.workerId ?? '') : args.userId;
      otherName = (amClient ? args.workerName : args.clientName) ??
          (amClient ? 'Profissional' : 'Cliente');
    } else if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      chatId = (map['chatId'] ?? map['orderId'] ?? '') as String;
      otherUserId = map['otherUserId'] as String? ?? '';
      otherIsWorker = map['otherIsWorker'] as bool? ?? false;
      otherName = map['otherName'] as String? ?? 'Usuário';
      otherPhotoUrl = map['otherPhotoUrl'] as String?;
    } else {
      chatId = '';
    }

    if (chatId.isEmpty) {
      initError.value = 'Conversa não encontrada.';
      isLoadingMessages.value = false;
      return;
    }

    _startMessageStream();

    if (otherUserId.isEmpty) {
      _resolveOtherParticipant();
    } else {
      _watchLastSeen();
    }
  }

  /// Descobre quem é o outro participante a partir do pedido
  /// (chatId == orderId) e inicializa o doc do chat se necessário.
  Future<void> _resolveOtherParticipant() async {
    try {
      final uid = _fb.uid;
      final order = await _ds.getOrder(chatId);
      if (order != null) {
        final amClient = order.userId == uid;
        otherIsWorker = amClient;
        otherUserId = amClient ? (order.workerId ?? '') : order.userId;
        otherName = (amClient
                ? order.workerName
                : order.clientName) ??
            (amClient ? 'Profissional' : 'Cliente');

        // Garante o doc do chat (participants) para a lista de conversas
        if (order.workerId != null && order.workerId!.isNotEmpty) {
          await _ds.initChat(
            orderId: order.id,
            userId: order.userId,
            workerId: order.workerId!,
          );
        }
      } else {
        // Sem pedido: tenta pelo doc do chat
        final chat = await _ds.getChat(chatId);
        final participants =
            List<String>.from(chat?['participants'] ?? const []);
        otherUserId = participants
            .firstWhere((p) => p != uid, orElse: () => '');
      }
      // Força o rebuild do cabeçalho (o Obx da AppBar escuta este Rx)
      otherUserLastSeen.refresh();
      if (otherUserId.isNotEmpty) _watchLastSeen();
    } catch (_) {
      // Chat continua funcional mesmo sem os dados do outro usuário.
    }
  }

  @override
  void onClose() {
    _msgSub?.cancel();
    _lastSeenSub?.cancel();
    messageCtrl.dispose();
    super.onClose();
  }

  // ── Mensagens ─────────────────────────────────────────────────────────────

  void _startMessageStream() {
    isLoadingMessages.value = true;
    _msgSub = _ds.watchMessages(chatId).listen((list) {
      messages.assignAll(list);
      isLoadingMessages.value = false;
      // Marca como lidas ao abrir/receber
      _markAsRead();
    });
  }

  Future<void> _markAsRead() async {
    await _ds.markMessagesAsRead(
        chatId: chatId, currentUserId: _fb.uid);
  }

  // ── Enviar texto ──────────────────────────────────────────────────────────

  Future<void> sendText() async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;
    messageCtrl.clear();

    final msg = MessageModel(
      id: '',
      chatId: chatId,
      senderId: _fb.uid,
      content: text,
      createdAt: DateTime.now(),
    );
    await _ds.sendMessage(msg);
  }

  // ── Enviar imagem ─────────────────────────────────────────────────────────

  Future<void> sendImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (xFile == null) return;

    isSendingImage.value = true;
    try {
      final url = await CloudinaryService.upload(
        File(xFile.path),
        folder: 'chats/$chatId',
      );

      if (url.isEmpty) {
        Get.snackbar('Upload desabilitado',
            'Configure o Cloudinary para enviar fotos.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final msg = MessageModel(
        id: '',
        chatId: chatId,
        senderId: _fb.uid,
        imageUrl: url,
        createdAt: DateTime.now(),
      );
      await _ds.sendMessage(msg);
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível enviar a imagem.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSendingImage.value = false;
    }
  }

  // ── currentUid ───────────────────────────────────────────────────────────
  String get currentUid => _fb.uid;

  // ── lastSeen ──────────────────────────────────────────────────────────────

  void _watchLastSeen() {
    _lastSeenSub = _ds
        .watchLastSeen(otherUserId, isWorker: otherIsWorker)
        .listen((dt) => otherUserLastSeen.value = dt);
  }

  String get onlineStatus {
    final last = otherUserLastSeen.value;
    if (last == null) return '';
    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 3) return 'online';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays} dias';
  }

  bool get isOnline {
    final last = otherUserLastSeen.value;
    if (last == null) return false;
    return DateTime.now().difference(last).inMinutes < 3;
  }

  // ── Agrupar mensagens por data ────────────────────────────────────────────

  /// Retorna a label do separador de data ou null se mesmo dia da anterior.
  String? dateLabelFor(int index) {
    final msg = messages[index];
    if (index == 0) return _dateLabel(msg.createdAt);
    final prev = messages[index - 1];
    final isSameDay = msg.createdAt.year == prev.createdAt.year &&
        msg.createdAt.month == prev.createdAt.month &&
        msg.createdAt.day == prev.createdAt.day;
    return isSameDay ? null : _dateLabel(msg.createdAt);
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}
