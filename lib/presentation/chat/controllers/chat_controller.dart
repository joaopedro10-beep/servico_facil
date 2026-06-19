import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/message_model.dart';

class ChatController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final _picker = ImagePicker();

  // ── Estado ────────────────────────────────────────────────────────────────
  final messages = <MessageModel>[].obs;
  final isLoadingMessages = true.obs;
  final isSendingImage = false.obs;
  final otherUserLastSeen = Rxn<DateTime>();

  // Chat IDs
  late String chatId;
  late String otherUserId;
  late bool otherIsWorker;
  late String otherName;
  late String? otherPhotoUrl;

  final messageCtrl = TextEditingController();
  StreamSubscription? _msgSub;
  StreamSubscription? _lastSeenSub;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'] as String;
    otherUserId = args['otherUserId'] as String;
    otherIsWorker = args['otherIsWorker'] as bool? ?? false;
    otherName = args['otherName'] as String? ?? 'Usuário';
    otherPhotoUrl = args['otherPhotoUrl'] as String?;

    _startMessageStream();
    _watchLastSeen();
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
