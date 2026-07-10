import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/worker_model.dart';
import '../../controllers/client_controller.dart';
import '../client_home_screen.dart' show CTheme;

class ClientHomeSection extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onMenuTap;
  const ClientHomeSection({
    super.key,
    required this.ctrl,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CTheme.blue,
      onRefresh: ctrl.reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(ctrl: ctrl, onMenuTap: onMenuTap)),
          SliverToBoxAdapter(child: _Greeting(ctrl: ctrl)),
          SliverToBoxAdapter(child: _SearchBar(ctrl: ctrl, onSearch: () {
            // navigate to search tab is handled by parent
          })),
          SliverToBoxAdapter(child: _Categories(ctrl: ctrl)),
          SliverToBoxAdapter(child: _PromoBanner()),
          SliverToBoxAdapter(child: _NearbyWorkers(ctrl: ctrl)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onMenuTap;
  const _TopBar({required this.ctrl, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CTheme.blue,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: onMenuTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        // Shield logo
        const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Serviço Fácil',
              style: TextStyle(
                  color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        // Notificações
        Obx(() {
          final count = ctrl.notificationCount.value;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: () => Get.toNamed(AppRoutes.notifications),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (count > 0)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: CTheme.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(width: 4),
        // Avatar
        Obx(() {
          final initial = ctrl.nameInitial;
          final photo   = ctrl.currentUser.value?.photoUrl;
          return CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w800))
                : null,
          );
        }),
      ]),
    );
  }
}

// ─── Saudação ─────────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final ClientController ctrl;
  const _Greeting({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Obx(() {
        final name = ctrl.currentUser.value?.name ?? '';
        final first = name.isNotEmpty ? name.split(' ').first : 'Cliente';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $first! 👋',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: CTheme.textDark),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 4),
            const Text('Encontre profissionais qualificados\npróprios de você.',
                style: TextStyle(fontSize: 13, color: CTheme.textGray, height: 1.4),
                overflow: TextOverflow.ellipsis, maxLines: 2),
          ],
        );
      }),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onSearch;
  const _SearchBar({required this.ctrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: onSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CTheme.border),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: CTheme.textLight, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Qual serviço você precisa hoje?',
                  style: TextStyle(fontSize: 14, color: CTheme.textLight),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            const Icon(Icons.search_rounded, color: CTheme.blue, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── Categorias ───────────────────────────────────────────────────────────────
class _Categories extends StatelessWidget {
  final ClientController ctrl;
  const _Categories({required this.ctrl});

  static const _icons = [
    Icons.electrical_services_rounded,
    Icons.plumbing_rounded,
    Icons.format_paint_rounded,
    Icons.construction_rounded,
    Icons.park_rounded,
    Icons.cleaning_services_rounded,
    Icons.chair_rounded,
    Icons.ac_unit_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final cats = ClientController.categories;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Categorias',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: CTheme.textDark),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text('Ver todas',
                style: TextStyle(fontSize: 12, color: CTheme.blue,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: cats.asMap().entries.map((e) {
            final cat = e.value;
            final icon = _icons[e.key % _icons.length];
            return Obx(() {
              final sel = ctrl.selectedCategory.value
                  .toLowerCase()
                  .contains(cat.$1.toLowerCase().split(' ').first);
              return GestureDetector(
                onTap: () => ctrl.selectCategory(cat.$1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: sel ? CTheme.blue : CTheme.blueLight,
                        borderRadius: BorderRadius.circular(14),
                        border: sel
                            ? null
                            : Border.all(color: CTheme.border),
                      ),
                      child: Center(
                        child: Icon(icon,
                            color: sel ? Colors.white : CTheme.blue,
                            size: 24),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(cat.$1,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? CTheme.blue : CTheme.textGray),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, maxLines: 2),
                  ],
                ),
              );
            });
          }).toList(),
        ),
      ]),
    );
  }
}

// ─── Banner promocional ───────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CTheme.blue, CTheme.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('10% OFF',
                  style: TextStyle(
                      color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
              const Text('na sua primeira\nsolicitação!',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.3),
                  overflow: TextOverflow.ellipsis, maxLines: 2),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Usar cupom: BEMVINDO',
                    style: TextStyle(
                        color: CTheme.blue, fontSize: 12,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.handyman_rounded, color: Colors.white54, size: 64),
      ]),
    );
  }
}

// ─── Prestadores próximos ─────────────────────────────────────────────────────
class _NearbyWorkers extends StatelessWidget {
  final ClientController ctrl;
  const _NearbyWorkers({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final workers = ctrl.filteredWorkers.take(10).toList();
      final loading = ctrl.isLoadingWorkers.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Prestadores próximos',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: CTheme.textDark),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 10),
          if (loading)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (workers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CTheme.border),
              ),
              child: const Row(children: [
                Icon(Icons.search_off_rounded, color: CTheme.textLight, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Nenhum profissional encontrado.',
                      style: TextStyle(color: CTheme.textGray, fontSize: 13),
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                ),
              ]),
            )
          else
            ...workers.map((w) => _WorkerCard(worker: w, ctrl: ctrl)),
        ]),
      );
    });
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final ClientController ctrl;
  const _WorkerCard({required this.worker, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final dist = ctrl.distanceToWorker(worker);
    final distLabel = ctrl.locationGranted.value && dist > 0
        ? '${dist.toStringAsFixed(1)} km de você'
        : '';

    return GestureDetector(
      onTap: () => ctrl.goToWorkerProfile(worker),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: CTheme.blueLight,
                backgroundImage: worker.photoUrl != null
                    ? NetworkImage(worker.photoUrl!)
                    : null,
                child: worker.photoUrl == null
                    ? Text(
                        worker.name.isNotEmpty
                            ? worker.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: CTheme.blue))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(worker.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (distLabel.isNotEmpty)
                        Text(distLabel,
                            style: const TextStyle(
                                fontSize: 11, color: CTheme.blue,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      worker.categories.isNotEmpty
                          ? worker.categories.first
                          : '—',
                      style: const TextStyle(
                          fontSize: 13, color: CTheme.textGray),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(worker.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(' (${worker.totalReviews} avaliações)',
                          style: const TextStyle(
                              fontSize: 11, color: CTheme.textGray),
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(
                        'A partir de R\$ ${worker.pricePerHour.toStringAsFixed(0).replaceAll('.', ',')},00',
                        style: const TextStyle(
                            fontSize: 11, color: CTheme.textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    side: const BorderSide(color: CTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => ctrl.goToWorkerProfile(worker),
                  child: const Text('Ver perfil',
                      style: TextStyle(
                          fontSize: 13, color: CTheme.textGray),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CTheme.blue,
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Get.toNamed(
                      AppRoutes.workerProfile, arguments: worker),
                  child: const Text('Solicitar serviço',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
