import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../admin_theme.dart';
import '../controllers/admin_controller.dart';
import 'sections/admin_dashboard_section.dart';
import 'sections/admin_logs_section.dart';
import 'sections/admin_orders_section.dart';
import 'sections/admin_reports_section.dart';
import 'sections/admin_reviews_section.dart';
import 'sections/admin_users_section.dart';
import 'sections/admin_workers_section.dart';

// ─── Itens do bottom nav ──────────────────────────────────────────────────────
class _BottomItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int sectionIndex; // mapeia para ctrl.currentSection
  const _BottomItem(this.icon, this.activeIcon, this.label, this.sectionIndex);
}

// 4 abas — Perfil fica no Drawer lateral (sem aba Perfil no BottomNav)
const _bottomItems = [
  _BottomItem(Icons.dashboard_outlined,      Icons.dashboard_rounded,      'Dashboard',  0),
  _BottomItem(Icons.hourglass_empty_rounded, Icons.hourglass_top_rounded,  'Aprovações', 1),
  _BottomItem(Icons.receipt_long_outlined,   Icons.receipt_long_rounded,   'Serviços',   4),
  _BottomItem(Icons.bar_chart_outlined,      Icons.bar_chart_rounded,      'Relatórios', 7),
];

// ─── Itens do drawer ──────────────────────────────────────────────────────────
class _DrawerItem {
  final IconData icon;
  final String label;
  final int section;
  const _DrawerItem(this.icon, this.label, this.section);
}

const _drawerItems = [
  _DrawerItem(Icons.dashboard_rounded,       'Dashboard',            0),
  _DrawerItem(Icons.hourglass_top_rounded,   'Prestadores Pendentes',1),
  _DrawerItem(Icons.engineering_rounded,     'Prestadores Aprovados',2),
  _DrawerItem(Icons.people_rounded,          'Clientes',             3),
  _DrawerItem(Icons.receipt_long_rounded,    'Serviços',             4),
  _DrawerItem(Icons.category_rounded,        'Categorias',           0),
  _DrawerItem(Icons.star_rounded,            'Avaliações',           5),
  _DrawerItem(Icons.flag_rounded,            'Denúncias',            6),
  _DrawerItem(Icons.notifications_rounded,   'Notificações',         0),
  _DrawerItem(Icons.analytics_rounded,       'Relatórios',           7),
  _DrawerItem(Icons.settings_rounded,        'Configurações',        0),
];

// ─── Tela raiz ────────────────────────────────────────────────────────────────
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AdminController ctrl;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(AdminController());
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onBottomTap(int i) {
    setState(() => _bottomIndex = i);
    ctrl.currentSection.value = _bottomItems[i].sectionIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.background,
      drawer: _AdminDrawer(ctrl: ctrl),
      body: SafeArea(
        child: Column(children: [
          _TopBar(ctrl: ctrl, onMenuTap: _openDrawer),
          Expanded(
            child: Obx(() {
              switch (ctrl.currentSection.value) {
                case 1:
                  ctrl.workerTab.value = 0;
                  return AdminWorkersSection(ctrl: ctrl);
                case 2:
                  ctrl.workerTab.value = 1;
                  return AdminWorkersSection(ctrl: ctrl);
                case 3:
                  return AdminUsersSection(ctrl: ctrl);
                case 4:
                  return AdminOrdersSection(ctrl: ctrl);
                case 5:
                  return AdminReviewsSection(ctrl: ctrl);
                case 6:
                  return AdminReportsSection(ctrl: ctrl);
                case 7:
                  return AdminLogsSection(ctrl: ctrl);
                default:
                  return AdminDashboardSection(ctrl: ctrl);
              }
            }),
          ),
        ]),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _bottomIndex,
        onTap: _onBottomTap,
        ctrl: ctrl,
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AdminController ctrl;
  final VoidCallback onMenuTap;
  const _TopBar({required this.ctrl, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AdminTheme.primary,
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // ── Ícone menu (☰) ───────────────────────────────────────────────
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: onMenuTap,
          tooltip: 'Menu',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 6),

        // ── Logo / Nome ──────────────────────────────────────────────────
        const Expanded(
          child: Text(
            'ServiçoFácil Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

        // ── Notificações ─────────────────────────────────────────────────
        Obx(() {
          final total = ctrl.pendingWorkers.length + ctrl.openReports.length;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: () => ctrl.currentSection.value = 6,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (total > 0)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AdminTheme.redLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$total',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(width: 4),

        // ── Avatar admin (toca para abrir o drawer) ──────────────────────
        Obx(() {
          final name = ctrl.adminName.value;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
          return GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AdminController ctrl;
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminTheme.border)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: _bottomItems.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge para aprovações
                      if (i == 1)
                        Obx(() {
                          final badge = ctrl.pendingWorkers.length;
                          return Stack(clipBehavior: Clip.none, children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected
                                  ? AdminTheme.primary
                                  : AdminTheme.textLight,
                              size: 22,
                            ),
                            if (badge > 0)
                              Positioned(
                                right: -4, top: -4,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: const BoxDecoration(
                                      color: AdminTheme.redLight,
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('$badge',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 8,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                          ]);
                        })
                      else
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected
                              ? AdminTheme.primary
                              : AdminTheme.textLight,
                          size: 22,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? AdminTheme.primary
                              : AdminTheme.textLight,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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

// ─── Drawer ───────────────────────────────────────────────────────────────────
class _AdminDrawer extends StatelessWidget {
  final AdminController ctrl;
  const _AdminDrawer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        color: Colors.white,
        child: Column(children: [
          // ── Cabeçalho do drawer ──────────────────────────────────────
          _DrawerHeader(ctrl: ctrl),

          // ── Itens do menu ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ..._drawerItems.map((item) => Obx(() {
                  int badge = 0;
                  if (item.section == 1) badge = ctrl.pendingWorkers.length;
                  if (item.section == 6) badge = ctrl.openReports.length;
                  return _DrawerMenuItem(
                    icon: item.icon,
                    label: item.label,
                    selected: ctrl.currentSection.value == item.section &&
                        item.section != 0,
                    badge: badge,
                    onTap: () {
                      ctrl.currentSection.value = item.section;
                      Navigator.of(context).pop();
                    },
                  );
                })),
                const Divider(indent: 16, endIndent: 16),
                SafeArea(
                  top: false,
                  child: _DrawerMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  selected: false,
                  isLogout: true,
                  onTap: () async {
                    Navigator.of(context).pop();
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Sair do painel'),
                        content: const Text(
                            'Deseja encerrar a sessão de administrador?'),
                        actions: [
                          TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancelar')),
                          TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Sair',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final repo = Get.find<AuthRepositoryImpl>();
                      await repo.signOut();
                      Get.offAllNamed(AppRoutes.welcome);
                    }
                  },
                ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final AdminController ctrl;
  const _DrawerHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name = ctrl.adminName.value;
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AdminTheme.primary, AdminTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar circular
            Stack(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              // Indicador online
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AdminTheme.greenLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
            const Spacer(),
            // Botão fechar
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          const Text('Administrador',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          // Badge Online
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AdminTheme.greenLight, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('Online',
                style: TextStyle(
                    color: AdminTheme.greenLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            // Botão editar perfil
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text('Editar Perfil',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      );
    });
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final bool isLogout;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? AdminTheme.red
        : selected
            ? AdminTheme.primary
            : AdminTheme.textGray;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.primary.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: selected || isLogout
                        ? FontWeight.w600
                        : FontWeight.w400),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: AdminTheme.redLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}
