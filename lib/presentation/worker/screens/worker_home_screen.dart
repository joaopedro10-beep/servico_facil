import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../controllers/worker_controller.dart';
import 'sections/worker_dashboard_section.dart';
import 'sections/worker_requests_section.dart';
import 'sections/worker_agenda_section.dart';
import 'sections/worker_earnings_section.dart';
import 'sections/worker_profile_section.dart';

// ─── Cor azul do tema do prestador ───────────────────────────────────────────
// O app do cliente usa verde (#1D9E75); o prestador usa azul (#1565C0) conforme
// a imagem de referência.
class WTheme {
  // Verde da logo em todas as telas do prestador
  static const primary     = Color(0xFF1D9E75); // verde logo
  static const primaryDark = Color(0xFF0F6E56); // verde escuro
  static const primaryLight= Color(0xFFE8F5F0); // verde clarinho
  // Manter blue como alias para não quebrar referências existentes
  static const blue        = primary;
  static const blueDark    = primaryDark;
  static const blueLight   = primaryLight;
  static const green       = Color(0xFF2E7D32);
  static const greenLight  = Color(0xFF4CAF50);
  static const red         = Color(0xFFD32F2F);
  static const redLight    = Color(0xFFFFEBEE);
  static const amber       = Color(0xFFF9A825);
  static const amberBg     = Color(0xFFFFF8E1);
  static const card        = Color(0xFFFFFFFF);
  static const background  = Color(0xFFF5F7FA);
  static const border      = Color(0xFFE0E7EF);
  static const textDark    = Color(0xFF0D3D2E);
  static const textGray    = Color(0xFF546E7A);
  static const textLight   = Color(0xFF90A4AE);
  static const purple      = Color(0xFF6A1B9A);
}

// ─── Itens bottom nav ─────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// 4 abas — Perfil fica no Drawer lateral (sem aba Perfil no BottomNav)
const _navItems = [
  _NavItem(Icons.home_outlined,          Icons.home_rounded,          'Início'),
  _NavItem(Icons.receipt_long_outlined,  Icons.receipt_long_rounded,  'Solicitações'),
  _NavItem(Icons.calendar_today_outlined,Icons.calendar_today_rounded,'Agenda'),
  _NavItem(Icons.account_balance_wallet_outlined,Icons.account_balance_wallet_rounded,'Ganhos'),
];

// ─── Root ─────────────────────────────────────────────────────────────────────
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WorkerController ctrl;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(WorkerController());
  }

  void _onNavTap(int i) => setState(() => _navIndex = i);
  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: WTheme.background,
      drawer: _WorkerDrawer(ctrl: ctrl),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            WorkerDashboardSection(ctrl: ctrl, onMenuTap: _openDrawer),
            WorkerRequestsSection(ctrl: ctrl),
            WorkerAgendaSection(ctrl: ctrl),
            WorkerEarningsSection(ctrl: ctrl),
            // Perfil acessível pelo Drawer lateral
          ],
        ),
      ),
      bottomNavigationBar: _WorkerBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        ctrl: ctrl,
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _WorkerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final WorkerController ctrl;
  const _WorkerBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: WTheme.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final sel = currentIndex == i;

              Widget iconW;
              if (i == 1) {
                // Badge de novas solicitações
                iconW = Obx(() {
                  final count = ctrl.newOrders.length;
                  return Stack(clipBehavior: Clip.none, children: [
                    Icon(sel ? item.activeIcon : item.icon,
                        color:
                            sel ? WTheme.blue : WTheme.textLight,
                        size: 22),
                    if (count > 0)
                      Positioned(
                        right: -4, top: -4,
                        child: Container(
                          width: 15, height: 15,
                          decoration: const BoxDecoration(
                              color: WTheme.red,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                  ]);
                });
              } else {
                iconW = Icon(sel ? item.activeIcon : item.icon,
                    color: sel ? WTheme.blue : WTheme.textLight,
                    size: 22);
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconW,
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: TextStyle(
                              fontSize: 10,
                              color: sel ? WTheme.blue : WTheme.textLight,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Drawer lateral ───────────────────────────────────────────────────────────
class _WorkerDrawer extends StatelessWidget {
  final WorkerController ctrl;
  const _WorkerDrawer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      child: Column(children: [
        // Cabeçalho azul com perfil
        _DrawerHeader(ctrl: ctrl),

        // Itens
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _DrawerItem(Icons.dashboard_rounded,     'Dashboard',          () { Get.back(); }),
              _DrawerItem(Icons.receipt_long_rounded,  'Solicitações',       () { Get.back(); }),
              _DrawerItem(Icons.engineering_rounded,   'Serviços em andamento', () { Get.back(); }),
              _DrawerItem(Icons.calendar_today_rounded,'Agenda',             () { Get.back(); }),
              _DrawerItem(Icons.history_rounded,       'Histórico',          () { Get.back(); }),
              _DrawerItem(Icons.people_rounded,        'Clientes',           () { Get.back(); }),
              _DrawerItem(Icons.star_rounded,          'Avaliações',         () { Get.back(); }),
              _DrawerItem(Icons.account_balance_wallet_rounded, 'Ganhos',   () { Get.back(); }),
              _DrawerItem(Icons.credit_card_rounded,   'Carteira',           () { Get.back(); }),
              _DrawerItem(Icons.notifications_rounded, 'Notificações',       () { Get.back(); }),
              _DrawerItem(Icons.settings_rounded,      'Configurações',      () { Get.back(); }),
              _DrawerItem(Icons.help_rounded,          'Ajuda',              () { Get.back(); }),
              const Divider(indent: 16, endIndent: 16, height: 20),
              _DrawerItem(Icons.logout_rounded, 'Sair',
                  () async {
                    Get.back();
                    await ctrl.signOut();
                  },
                  color: WTheme.red),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final WorkerController ctrl;
  const _DrawerHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final w = ctrl.worker.value;
      final name = w?.name ?? 'Prestador';
      final category =
          w?.categories.isNotEmpty == true ? w!.categories.first : '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
      final avg = ctrl.avgRating;

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [WTheme.blue, WTheme.blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar
            Stack(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withOpacity(0.25),
                backgroundImage: w?.photoUrl != null
                    ? NetworkImage(w!.photoUrl!)
                    : null,
                child: w?.photoUrl == null
                    ? Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800))
                    : null,
              ),
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(
                    color: ctrl.isAvailable.value
                        ? WTheme.greenLight
                        : WTheme.textLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
            const Spacer(),
            // Fechar drawer
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(category,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            if (avg > 0) ...[
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('(${w?.totalReviews ?? 0} avaliações)',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 10),
            ],
            // Badge online/offline
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: ctrl.isAvailable.value
                        ? WTheme.greenLight
                        : WTheme.textLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  ctrl.isAvailable.value ? 'Online' : 'Offline',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
        ]),
      );
    });
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem(this.icon, this.label, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? WTheme.textGray;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, color: c),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ]),
      ),
    );
  }
}
