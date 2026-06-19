import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/worker_model.dart';
import '../controllers/client_home_controller.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/worker_card.dart';
import '../widgets/worker_shimmer.dart';

// ─── Dados das categorias ─────────────────────────────────────────────────────

class _Category {
  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

const _categories = [
  _Category('Encanador', Icons.water_damage_outlined),
  _Category('Eletricista', Icons.electrical_services_outlined),
  _Category('Diarista', Icons.cleaning_services_outlined),
  _Category('Pintor', Icons.format_paint_outlined),
  _Category('Jardineiro', Icons.park_outlined),
  _Category('Montador', Icons.handyman_outlined),
  _Category('Pedreiro', Icons.construction_outlined),
  _Category('TI/Suporte', Icons.computer_outlined),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ClientHomeController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ctrl.refresh(),
          child: CustomScrollView(
            slivers: [
              // ── 1. Header ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(ctrl)),

              // ── 2. Busca ──────────────────────────────────────────────
              SliverToBoxAdapter(
                  child: _buildSearchBar(ctrl, context)),

              // ── 3. Chips de categorias ────────────────────────────────
              SliverToBoxAdapter(child: _buildCategoryChips(ctrl)),

              // ── 4. Título da lista + filtro ───────────────────────────
              SliverToBoxAdapter(
                  child: _buildListHeader(ctrl, context)),

              // ── 5. Lista / Shimmer / Estado vazio ─────────────────────
              _buildWorkerList(ctrl),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(ClientHomeController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Obx(() => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${ctrl.firstName}! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'O que você precisa hoje?',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Ícone de notificação com badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        size: 26, color: AppColors.textPrimary),
                    onPressed: () =>
                        Get.toNamed(AppRoutes.notifications),
                  ),
                  if (ctrl.notificationCount.value > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ctrl.notificationCount.value > 9
                              ? '9+'
                              : '${ctrl.notificationCount.value}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              // Avatar do usuário
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.clientProfile),
                child: _buildUserAvatar(ctrl),
              ),
            ],
          )),
    );
  }

  Widget _buildUserAvatar(ClientHomeController ctrl) {
    final photoUrl = ctrl.currentUser.value?.photoUrl;
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.border,
      child: photoUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: AppColors.textHint),
              ),
            )
          : const Icon(Icons.person, color: AppColors.textHint),
    );
  }

  // ── 2. Barra de busca ──────────────────────────────────────────────────────

  Widget _buildSearchBar(
      ClientHomeController ctrl, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: ctrl.onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou serviço...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textHint),
                  onPressed: () {
                    ctrl.onSearch('');
                    FocusScope.of(context).unfocus();
                  },
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── 3. Chips de categorias ─────────────────────────────────────────────────

  Widget _buildCategoryChips(ClientHomeController ctrl) {
    return SizedBox(
      height: 52,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final selected = ctrl.selectedCategory.value == cat.label;
            return GestureDetector(
              onTap: () => ctrl.selectCategory(cat.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 4. Título da lista + botão de filtro ───────────────────────────────────

  Widget _buildListHeader(
      ClientHomeController ctrl, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Obx(() {
        final count = ctrl.filteredWorkers.length;
        return Row(
          children: [
            Text(
              '$count ${count == 1 ? 'profissional' : 'profissionais'}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (ctrl.selectedCategory.value.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '· ${ctrl.selectedCategory.value}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
            const Spacer(),
            // Botão de filtro avançado
            GestureDetector(
              onTap: () => _openFilterSheet(context, ctrl),
              child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ctrl.hasActiveFilters
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ctrl.hasActiveFilters
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: ctrl.hasActiveFilters
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ctrl.hasActiveFilters
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (ctrl.hasActiveFilters) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                  )),
            ),
          ],
        );
      }),
    );
  }

  void _openFilterSheet(
      BuildContext context, ClientHomeController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(controller: ctrl),
    );
  }

  // ── 5. Lista de workers ────────────────────────────────────────────────────

  Widget _buildWorkerList(ClientHomeController ctrl) {
    return Obx(() {
      // Shimmer enquanto carrega
      if (ctrl.isLoadingWorkers.value) {
        return const SliverToBoxAdapter(
          child: WorkerListShimmer(count: 5),
        );
      }

      final workers = ctrl.filteredWorkers;

      // Estado vazio
      if (workers.isEmpty) {
        return SliverFillRemaining(
          child: _buildEmptyState(ctrl),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final w = workers[i];
            final dist = ctrl.distanceToWorker(w);
            return WorkerCard(
              worker: w,
              distanceKm: dist,
              onTap: () =>
                  Get.toNamed(AppRoutes.workerProfile, arguments: w),
            );
          },
          childCount: workers.length,
        ),
      );
    });
  }

  // ── Estado vazio ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(ClientHomeController ctrl) {
    final hasSearch = ctrl.searchQuery.value.isNotEmpty;
    final hasCat = ctrl.selectedCategory.value.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustração SVG-free usando ícone grande
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch || hasCat
                  ? 'Nenhum profissional encontrado'
                  : 'Nenhum profissional disponível',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Tente outro nome ou categoria.'
                  : hasCat
                      ? 'Não há ${ctrl.selectedCategory.value.toLowerCase()} disponível agora. Tente outra categoria.'
                      : 'Novos profissionais se cadastram todos os dias. Volte em breve!',
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasSearch || hasCat || ctrl.hasActiveFilters)
              OutlinedButton.icon(
                onPressed: () {
                  ctrl.onSearch('');
                  ctrl.selectCategory('');
                  ctrl.resetFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar filtros'),
              ),
          ],
        ),
      ),
    );
  }
}
