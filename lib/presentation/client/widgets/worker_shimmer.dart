import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';

class WorkerCardShimmer extends StatelessWidget {
  const WorkerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 140, height: 14),
                  const SizedBox(height: 6),
                  _box(width: 90, height: 11),
                  const SizedBox(height: 10),
                  _box(width: 100, height: 11),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _box(width: 60, height: 22, radius: 20),
                      const Spacer(),
                      _box(width: 50, height: 11),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 6,
  }) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Lista de shimmer — exibe N cards enquanto carrega
class WorkerListShimmer extends StatelessWidget {
  const WorkerListShimmer({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => const WorkerCardShimmer(),
    );
  }
}
