import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/worker_model.dart';
import '../controllers/worker_profile_controller.dart';
import '../../orders/controllers/order_controller.dart';
import '../../orders/screens/request_service_sheet.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerProfileController());

    return Obx(() {
      final w = ctrl.worker.value;

      if (ctrl.isLoading.value || w == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, w, ctrl),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(w),
                  const Divider(height: 1),
                  _buildRatingSection(w),
                  const Divider(height: 1),
                  _buildCategoriesSection(w),
                  const Divider(height: 1),
                  _buildPriceSection(w),
                  if (w.portfolioUrls.isNotEmpty) ...[
                    const Divider(height: 1),
                    _buildGallerySection(context, w, ctrl),
                  ],
                  if (ctrl.reviews.isNotEmpty) ...[
                    const Divider(height: 1),
                    _buildReviewsSection(ctrl),
                  ],
                  // Espaço para o botão fixo não cobrir o último item
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildRequestButton(w),
      );
    });
  }

  // ─── App Bar com foto de capa ─────────────────────────────────────────────

  SliverAppBar _buildAppBar(
      BuildContext context, WorkerModel w, WorkerProfileController ctrl) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          tooltip: 'Denunciar',
          icon: const Icon(Icons.flag_outlined),
          onPressed: ctrl.goToReport,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Foto de perfil como fundo suave
            if (w.photoUrl != null)
              CachedNetworkImage(
                imageUrl: w.photoUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.45),
                colorBlendMode: BlendMode.darken,
                placeholder: (_, __) =>
                    Container(color: AppColors.primary.withOpacity(0.2)),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.primary.withOpacity(0.2)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            // Avatar centralizado
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(w, radius: 50),
                  const SizedBox(height: 10),
                  Text(
                    w.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (w.isVerified) _buildBadgeVerified(),
                      if (w.isVerified && w.rating >= 4.5)
                        const SizedBox(width: 6),
                      if (w.rating >= 4.5) _buildBadgeTopRated(),
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

  Widget _buildAvatar(WorkerModel w, {double radius = 40}) {
    if (w.photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.border,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: w.photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => const CircularProgressIndicator.adaptive(),
            errorWidget: (_, __, ___) =>
                Icon(Icons.person, size: radius, color: AppColors.textHint),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: Icon(Icons.person, size: radius, color: AppColors.primary),
    );
  }

  Widget _buildBadgeVerified() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.lightBlueAccent, size: 14),
          SizedBox(width: 4),
          Text('Verificado',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadgeTopRated() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 14),
          SizedBox(width: 4),
          Text('Top Avaliado',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Header (descrição + localização) ────────────────────────────────────

  Widget _buildHeader(WorkerModel w) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (w.description.isNotEmpty) ...[
            Text(
              w.description,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${w.neighborhood}, ${w.city}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: w.isAvailable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textHint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: w.isAvailable
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      w.isAvailable ? 'Disponível' : 'Indisponível',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: w.isAvailable
                            ? AppColors.success
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Avaliação ────────────────────────────────────────────────────────────

  Widget _buildRatingSection(WorkerModel w) {
    final avg = w.totalReviews > 0 ? w.rating / w.totalReviews : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 6),
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, height: 1),
          ),
          const SizedBox(width: 8),
          Text(
            '(${w.totalReviews} ${w.totalReviews == 1 ? 'avaliação' : 'avaliações'})',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          _buildStarsRow(avg),
        ],
      ),
    );
  }

  Widget _buildStarsRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 20);
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              color: Colors.amber, size: 20);
        }
        return const Icon(Icons.star_outline_rounded,
            color: Colors.amber, size: 20);
      }),
    );
  }

  // ─── Categorias ───────────────────────────────────────────────────────────

  Widget _buildCategoriesSection(WorkerModel w) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Serviços oferecidos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: w.categories
                .map((c) => Chip(
                      label: Text(c),
                      avatar: const Icon(Icons.handyman_outlined, size: 14),
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      side: BorderSide(
                          color: AppColors.primary.withOpacity(0.3)),
                      labelStyle: const TextStyle(
                          fontSize: 13, color: AppColors.primaryDark),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Preço ────────────────────────────────────────────────────────────────

  Widget _buildPriceSection(WorkerModel w) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: AppColors.primary, size: 22),
          const SizedBox(width: 6),
          const Text('Preço por hora',
              style:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            'R\$ ${w.pricePerHour.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ─── Galeria (grid 3 colunas + lightbox) ──────────────────────────────────

  Widget _buildGallerySection(
      BuildContext context, WorkerModel w, WorkerProfileController ctrl) {
    final photos = w.portfolioUrls.take(6).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Galeria de trabalhos (${photos.length})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => _openLightbox(context, photos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: photos[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: AppColors.border,
                        child: const Center(
                            child: CircularProgressIndicator.adaptive())),
                    errorWidget: (_, __, ___) => Container(
                        color: AppColors.border,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.textHint)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> photos, int initial) {
    final pageCtrl = PageController(initialPage: initial);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: pageCtrl,
                itemCount: photos.length,
                itemBuilder: (_, i) => InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: photos[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 60),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avaliações ───────────────────────────────────────────────────────────

  Widget _buildReviewsSection(WorkerProfileController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimas avaliações (${ctrl.reviews.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...ctrl.reviews.map((r) => _ReviewCard(review: r)),
        ],
      ),
    );
  }

  // ─── Botão rodapé ─────────────────────────────────────────────────────────

  Widget _buildRequestButton(WorkerModel w) {
    final ctrl = Get.find<WorkerProfileController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: w.isAvailable ? ctrl.requestService : null,
        icon: const Icon(Icons.handshake_outlined),
        label: Text(w.isAvailable ? 'Solicitar serviço' : 'Indisponível'),
      ),
    );
  }
}

// ─── Widget de card de avaliação ──────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: AppColors.textHint),
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
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
      ),
    );
  }
}
