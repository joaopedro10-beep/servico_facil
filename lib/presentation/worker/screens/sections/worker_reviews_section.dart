import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/review_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Tela de avaliações do prestador.
/// Exibe média, total de avaliações, distribuição por estrelas e lista completa.
class WorkerReviewsSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerReviewsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(children: [
          const Expanded(
            child: Text('Avaliações',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
          Obx(() {
            final avg = ctrl.avgRating;
            if (avg == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(avg.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ]),
            );
          }),
        ]),
      ),

      Expanded(
        child: Obx(() {
          final reviews = ctrl.reviews;
          final avg     = ctrl.avgRating;
          final total   = ctrl.worker.value?.totalReviews ?? 0;

          if (reviews.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_outline_rounded,
                    size: 56, color: WTheme.textLight),
                SizedBox(height: 12),
                Text('Nenhuma avaliação ainda.',
                    style: TextStyle(
                        color: WTheme.textGray, fontSize: 14)),
                SizedBox(height: 6),
                Text(
                  'As avaliações aparecerão após seus\nserviços serem concluídos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: WTheme.textLight, fontSize: 12),
                ),
              ]),
            );
          }

          // Distribuição por estrela
          final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (final r in reviews) {
            final s = r.rating.round().clamp(1, 5);
            dist[s] = (dist[s] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card resumo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: WTheme.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000),
                        blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(children: [
                  // Média grande
                  Column(children: [
                    Text(avg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: WTheme.textDark,
                            height: 1.0)),
                    Row(mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) => Icon(
                          i < avg.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber, size: 14,
                        ))),
                    const SizedBox(height: 4),
                    Text('$total avaliações',
                        style: const TextStyle(
                            fontSize: 11, color: WTheme.textGray)),
                  ]),
                  const SizedBox(width: 20),
                  // Barra de distribuição
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = dist[star] ?? 0;
                        final pct = total > 0 ? count / total : 0.0;
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Text('$star',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: WTheme.textGray)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 11),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: WTheme.border,
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          Colors.amber),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 22,
                              child: Text('$count',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: WTheme.textGray),
                                  textAlign: TextAlign.right),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              const Text('Comentários',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WTheme.textDark)),
              const SizedBox(height: 10),

              ...reviews.map((r) => _ReviewCard(review: r)),
            ],
          );
        }),
      ),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000),
              blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: WTheme.primaryLight,
            child: Text(
              review.authorName.isNotEmpty
                  ? review.authorName[0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                  color: WTheme.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(review.authorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(fmt.format(review.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: WTheme.textGray)),
            ]),
          ),
          Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Icon(
                i < review.rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber, size: 14,
              ))),
        ]),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!,
                  style: const TextStyle(
                      fontSize: 13,
                      color: WTheme.textGray,
                      height: 1.45),
                  maxLines: 5, overflow: TextOverflow.ellipsis),
            ],
      ]),
    );
  }
}
