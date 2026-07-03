import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/worker_model.dart';
import '../controllers/client_home_controller.dart';
import '../controllers/client_profile_controller.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/worker_card.dart';
import '../widgets/worker_shimmer.dart';
import 'client_profile_screen.dart' show ClientDrawer;

// ─── Categorias ───────────────────────────────────────────────────────────────

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
    final profileCtrl = Get.put(ClientProfileController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ClientDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ctrl.refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(ctrl: ctrl, profileCtrl: profileCtrl)),
              SliverToBoxAdapter(child: _SearchBar(ctrl: ctrl)),
              SliverToBoxAdapter(child: _CategoryChips(ctrl: ctrl)),
              SliverToBoxAdapter(child: _ListHeader(ctrl: ctrl, context: context)),
              _WorkerList(ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ClientHomeController ctrl;
  final ClientProfileController profileCtrl;
  const _Header({required this.ctrl, required this.profileCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nome do usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final name = ctrl.currentUser.value?.name ?? '';
                  final first = name.isNotEmpty ? name.split(' ').first : '';
                  return Text(
                    first.isNotEmpty ? 'Olá, $first! 👋' : 'Olá! 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  );
                }),
                const SizedBox(height: 2),
                const Text(
                  'O que você precisa hoje?',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Badge de notificações
          Obx(() {
            final count = ctrl.notificationCount.value;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      size: 26, color: AppColors.textPrimary),
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                if (count > 0)
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
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(width: 4),

          // Avatar
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Obx(() {
                final name = profileCtrl.currentUser.value?.name ?? '';
                final initial = name.isNotEmpty
                    ? name.trim()[0].toUpperCase()
                    : '?';
                return _Avatar(initial: initial);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ClientHomeController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── Category Chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final ClientHomeController ctrl;
  const _CategoryChips({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return Obx(() {
            final selected = ctrl.selectedCategory.value == cat.label;
            return GestureDetector(
              onTap: () => ctrl.selectCategory(cat.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
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
                    Icon(cat.icon,
                        size: 16,
                        color:
                        selected ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// ─── List Header ─────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  final ClientHomeController ctrl;
  final BuildContext context;
  const _ListHeader({required this.ctrl, required this.context});

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Obx(() {
        final count = ctrl.filteredWorkers.length;
        final hasFilters = ctrl.hasActiveFilters.value;
        final category = ctrl.selectedCategory.value;
        return Row(
          children: [
            Text(
              '$count ${count == 1 ? 'profissional' : 'profissionais'}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('· $category',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => FilterBottomSheet(controller: ctrl),
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasFilters ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFilters ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 16,
                        color: hasFilters
                            ? Colors.white
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Filtros',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasFilters
                                ? Colors.white
                                : AppColors.textPrimary)),
                    if (hasFilters) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Worker List ──────────────────────────────────────────────────────────────

class _WorkerList extends StatelessWidget {
  final ClientHomeController ctrl;
  const _WorkerList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingWorkers.value) {
        return const SliverToBoxAdapter(
          child: WorkerListShimmer(count: 5),
        );
      }

      final workers = ctrl.filteredWorkers;

      if (workers.isEmpty) {
        return SliverFillRemaining(
          child: _EmptyState(ctrl: ctrl),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (_, i) {
            final w = workers[i];
            return WorkerCard(
              worker: w,
              distanceKm: ctrl.distanceToWorker(w),
              onTap: () => Get.toNamed(AppRoutes.workerProfile, arguments: w),
            );
          },
          childCount: workers.length,
        ),
      );
    });
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ClientHomeController ctrl;
  const _EmptyState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasSearch = ctrl.searchQuery.value.isNotEmpty;
      final hasCat = ctrl.selectedCategory.value.isNotEmpty;
      final hasFilters = ctrl.hasActiveFilters.value;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    size: 64, color: AppColors.primary),
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
                    ? 'Não há ${ctrl.selectedCategory.value.toLowerCase()} disponível agora.'
                    : 'Novos profissionais se cadastram todos os dias. Volte em breve!',
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (hasSearch || hasCat || hasFilters) ...[
                const SizedBox(height: 24),
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
            ],
          ),
        ),
      );
    });
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initial;
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
