import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../controllers/review_controller.dart';

class RateServiceScreen extends StatelessWidget {
  const RateServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final order = args['order'] as OrderModel;
    final asWorker = args['asWorker'] as bool? ?? false;

    final ctrl = Get.find<ReviewController>()
      ..initForRating(order, asWorker);

    return Scaffold(
      appBar: AppBar(
        title: Text(asWorker ? 'Avaliar cliente' : 'Avaliar profissional'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Subtítulo ──────────────────────────────────────────────
            Text(
              asWorker
                  ? 'Como foi a experiência com o cliente?'
                  : 'Como foi o serviço de ${order.workerName ?? "profissional"}?',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── Estrelas interativas ───────────────────────────────────
            Obx(() => _StarRatingWidget(
                  current: ctrl.selectedRating.value,
                  onTap: ctrl.setRating,
                )),
            const SizedBox(height: 10),
            Obx(() => Text(
                  _ratingLabel(ctrl.selectedRating.value),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ratingColor(ctrl.selectedRating.value),
                  ),
                )),
            const SizedBox(height: 24),

            // ── Tags rápidas ───────────────────────────────────────────
            Obx(() {
              if (ctrl.selectedRating.value == 0) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('O que você achou?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ctrl.currentTags.map((tag) {
                      final sel = ctrl.selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => ctrl.toggleTag(tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),

            // ── Comentário ─────────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Comentário (opcional)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl.commentCtrl,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Compartilhe sua experiência...',
              ),
            ),
            const SizedBox(height: 28),

            // ── Botão enviar ───────────────────────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.isSaving.value
                        ? null
                        : ctrl.submitReview,
                    icon: ctrl.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.star_rounded),
                    label: Text(ctrl.isSaving.value
                        ? 'Enviando...'
                        : 'Enviar avaliação'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Widget de estrelas animadas ──────────────────────────────────────────────

class _StarRatingWidget extends StatelessWidget {
  const _StarRatingWidget({
    required this.current,
    required this.onTap,
  });
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < current;
        return GestureDetector(
          onTap: () => onTap(i + 1),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey('$i-$filled'),
              size: 48,
              color: filled ? Colors.amber : AppColors.textHint,
            ),
          ),
        );
      }),
    );
  }
}

String _ratingLabel(int r) {
  switch (r) {
    case 1: return 'Muito ruim';
    case 2: return 'Ruim';
    case 3: return 'Regular';
    case 4: return 'Bom';
    case 5: return 'Excelente!';
    default: return 'Toque para avaliar';
  }
}

Color _ratingColor(int r) {
  if (r == 0) return AppColors.textHint;
  if (r <= 2) return AppColors.error;
  if (r == 3) return AppColors.warning;
  return AppColors.success;
}
