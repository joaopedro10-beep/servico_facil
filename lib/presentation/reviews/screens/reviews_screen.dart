import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/review_model.dart';
import '../controllers/review_controller.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late final ReviewController ctrl;
  late final String targetId;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<ReviewController>();
    final args = Get.arguments as Map<String, dynamic>?;
    targetId = args?['targetId'] as String? ?? '';
    ctrl.loadReviews(targetId, reset: true);

    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        ctrl.loadReviews(targetId);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações')),
      body: Column(
        children: [
          // ── Filtro por estrelas ──────────────────────────────────────
          _buildStarFilter(),

          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingReviews.value &&
                  ctrl.reviews.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }

              if (ctrl.reviews.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline,
                            size: 56, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Nenhuma avaliação ainda',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.reviews.length +
                    (ctrl.hasMoreReviews.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const Divider(height: 24),
                itemBuilder: (_, i) {
                  if (i == ctrl.reviews.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator.adaptive()),
                    );
                  }
                  return _ReviewCard(review: ctrl.reviews[i]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStarFilter() {
    return Obx(() => SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _FilterChip(
                label: 'Todas',
                selected: ctrl.selectedStarFilter.value == null,
                onTap: () => ctrl.setStarFilter(null, targetId),
              ),
              ...List.generate(5, (i) {
                final star = (5 - i).toDouble();
                return _FilterChip(
                  label: '${star.toInt()} ★',
                  selected: ctrl.selectedStarFilter.value == star,
                  onTap: () => ctrl.setStarFilter(star, targetId),
                );
              }),
            ],
          ),
        ));
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.border,
          child: review.authorPhotoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: review.authorPhotoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.person, color: AppColors.textHint),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(review.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  Text(fmt.format(review.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              // Estrelas
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
              // Tags
              if (review.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: review.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryDark)),
                          ))
                      .toList(),
                ),
              ],
              // Comentário
              if (review.comment != null &&
                  review.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  review.comment!,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}
