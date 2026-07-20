import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/worker_model.dart';

class ReviewController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ── RateServiceScreen ─────────────────────────────────────────────────────
  final isSaving = false.obs;
  final selectedRating = 0.obs;   // 1–5
  final selectedTags = <String>[].obs;
  final commentCtrl = TextEditingController();

  // Para exibir quem está avaliando quem
  late OrderModel ratingOrder;
  late bool ratingAsWorker; // true = worker avalia client; false = client avalia worker

  // ── ReviewsScreen ─────────────────────────────────────────────────────────
  final reviews = <ReviewModel>[].obs;
  final isLoadingReviews = false.obs;
  final hasMoreReviews = true.obs;
  final selectedStarFilter = Rxn<double>(); // null = todas
  dynamic _lastDoc;

  // ── Tags por situação ─────────────────────────────────────────────────────

  static const List<String> positiveTags = [
    'Pontual', 'Ótimo trabalho', 'Recomendo', 'Comunicativo',
  ];

  static const List<String> negativeTags = [
    'Atrasou', 'Trabalho ruim', 'Não comunicou',
  ];

  // Tags para worker avaliar cliente:
  static const List<String> clientPositiveTags = [
    'Bem comunicativo', 'Pagamento pontual', 'Ambiente organizado', 'Educado',
  ];
  static const List<String> clientNegativeTags = [
    'Não estava no local', 'Mau comunicativo', 'Endereço errado',
  ];

  List<String> get currentTags {
    final isPositive = selectedRating.value > 2;
    if (ratingAsWorker) {
      return isPositive ? clientPositiveTags : clientNegativeTags;
    }
    return isPositive ? positiveTags : negativeTags;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    commentCtrl.dispose();
    super.onClose();
  }

  // ── Init para tela de avaliação ───────────────────────────────────────────

  void initForRating(OrderModel order, bool asWorker) {
    ratingOrder = order;
    ratingAsWorker = asWorker;
    selectedRating.value = 0;
    selectedTags.clear();
    commentCtrl.clear();
  }

  void setRating(int stars) {
    selectedRating.value = stars;
    selectedTags.clear(); // limpa tags ao mudar nota
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  // ── Salvar avaliação ──────────────────────────────────────────────────────

  Future<void> submitReview() async {
    if (selectedRating.value == 0) {
      Get.snackbar('Atenção', 'Selecione uma nota de 1 a 5.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    try {
      final uid = _fb.uid;
      final order = ratingOrder;

      // Quem é o alvo
      final targetId =
          ratingAsWorker ? order.userId : order.workerId;

      // Nome do autor — tenta pegar do UserModel ou WorkerModel
      String authorName = 'Usuário';
      String? authorPhoto;
      if (ratingAsWorker) {
        final w = await _ds.getWorker(uid);
        authorName = w?.name ?? authorName;
        authorPhoto = w?.photoUrl;
      } else {
        final u = await _ds.getUser(uid);
        authorName = u?.name ?? authorName;
        authorPhoto = u?.photoUrl;
      }

      final review = ReviewModel(
        id: '',
        orderId: order.id,
        authorId: uid,
        authorName: authorName,
        authorPhotoUrl: authorPhoto,
        targetId: targetId ?? '',
        rating: selectedRating.value.toDouble(),
        comment: commentCtrl.text.trim().isEmpty
            ? null
            : commentCtrl.text.trim(),
        tags: selectedTags.toList(),
        createdAt: DateTime.now(),
      );

      await _ds.createReview(review);

      // Se novo rating ficou abaixo de 2.5, notifica o worker
      if (!ratingAsWorker && selectedRating.value <= 2) {
        final w = await _ds.getWorker(targetId ?? '');
        if (w != null && w.avgRating < 2.5) {
          await _ds.saveNotification(
            targetUserId: targetId ?? '',
            title: 'Sua disponibilidade foi pausada',
            body:
                'Sua avaliação média ficou abaixo de 2.5. Complete mais serviços para reativar.',
            type: 'rating_warning',
          );
        }
      }

      // Verifica cancelamentos do cliente (aviso no perfil)
      if (!ratingAsWorker) {
        final cancelCount =
            await _ds.countClientCancellationsThisMonth(uid);
        if (cancelCount >= 3) {
          await _ds.saveNotification(
            targetUserId: uid,
            title: 'Aviso: muitos cancelamentos',
            body:
                'Você cancelou $cancelCount pedidos este mês. Isso pode afetar sua reputação.',
            type: 'cancellation_warning',
          );
        }
      }

      Get.back();
      Get.snackbar('Avaliação enviada!', 'Obrigado pelo feedback.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      final msg = e.toString().contains('já avaliou')
          ? 'Você já avaliou este serviço.'
          : 'Não foi possível enviar a avaliação.';
      Get.snackbar('Erro', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  // ── ReviewsScreen — paginação ─────────────────────────────────────────────

  Future<void> loadReviews(String targetId, {bool reset = false}) async {
    if (isLoadingReviews.value) return;
    if (reset) {
      reviews.clear();
      _lastDoc = null;
      hasMoreReviews.value = true;
    }
    if (!hasMoreReviews.value) return;

    isLoadingReviews.value = true;
    try {
      final page = await _ds.getReviewsPaged(
        targetId,
        lastDoc: _lastDoc,
        starFilter: selectedStarFilter.value,
      );

      if (page.isEmpty || page.length < 10) {
        hasMoreReviews.value = false;
      }
      reviews.addAll(page);
      if (page.isNotEmpty) _lastDoc = page.last;
    } catch (_) {
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void setStarFilter(double? stars, String targetId) {
    selectedStarFilter.value = stars;
    loadReviews(targetId, reset: true);
  }
}
