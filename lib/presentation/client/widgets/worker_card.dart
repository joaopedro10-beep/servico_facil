import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  const WorkerCard({
    super.key,
    required this.worker,
    required this.distanceKm,
    required this.onTap,
  });

  final WorkerModel worker;
  final double distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avg = worker.avgRating;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto ──────────────────────────────────────────────────
              _buildAvatar(),
              const SizedBox(width: 12),

              // ── Info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + badge verificado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: Colors.lightBlue, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Categoria principal
                    Text(
                      worker.categories.isNotEmpty
                          ? worker.categories.first
                          : '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),

                    // Estrelas + avaliação
                    Row(
                      children: [
                        _buildStars(avg),
                        const SizedBox(width: 4),
                        Text(
                          avg > 0
                              ? '${avg.toStringAsFixed(1)} (${worker.totalReviews})'
                              : 'Sem avaliações',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Preço + distância
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'R\$ ${worker.pricePerHour.toStringAsFixed(0)}/h',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (distanceKm > 0) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 2),
                          Text(
                            distanceKm < 1
                                ? '${(distanceKm * 1000).toStringAsFixed(0)} m'
                                : '${distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: worker.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: worker.photoUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.border,
                  ),
                  errorWidget: (_, __, ___) => _placeholderAvatar(),
                )
              : _placeholderAvatar(),
        ),
        // Badge disponível
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, size: 36, color: AppColors.primary),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 14);
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              color: Colors.amber, size: 14);
        }
        return const Icon(Icons.star_outline_rounded,
            color: Colors.amber, size: 14);
      }),
    );
  }
}
