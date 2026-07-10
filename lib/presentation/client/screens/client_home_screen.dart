import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../controllers/client_controller.dart';
import 'sections/client_home_section.dart';
import 'sections/client_search_section.dart';
import 'sections/client_appointments_section.dart';
import 'sections/client_messages_section.dart';
import 'sections/client_profile_section.dart';

// ─── Cor azul do cliente (conforme imagem: #1565C0) ─────────────────────────
class CTheme {
  static const blue       = Color(0xFF1565C0);
  static const blueDark   = Color(0xFF003c8f);
  static const blueLight  = Color(0xFFE3F2FD);
  static const green      = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF4CAF50);
  static const red        = Color(0xFFD32F2F);
  static const amber      = Color(0xFFF9A825);
  static const card       = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F7FA);
  static const border     = Color(0xFFE0E7EF);
  static const textDark   = Color(0xFF1A237E);
  static const textGray   = Color(0xFF546E7A);
  static const textLight  = Color(0xFF90A4AE);
}

// ─── Bottom nav items ─────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.home_outlined,          Icons.home_rounded,          'Início'),
  _NavItem(Icons.search_outlined,        Icons.search_rounded,        'Buscar'),
  _NavItem(Icons.calendar_today_outlined,Icons.calendar_today_rounded,'Agendamentos'),
  _NavItem(Icons.chat_bubble_outline,    Icons.chat_bubble_rounded,   'Mensagens'),
  _NavItem(Icons.person_outline_rounded, Icons.person_rounded,        'Perfil'),
];

// ─── Root screen ─────────────────────────────────────────────────────────────
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ClientController ctrl;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(ClientController());
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
  void _onNavTap(int i) => setState(() => _navIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CTheme.background,
      drawer: _ClientDrawer(ctrl: ctrl),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            ClientHomeSection(ctrl: ctrl, onMenuTap: _openDrawer),
            ClientSearchSection(ctrl: ctrl),
            ClientAppointmentsSection(ctrl: ctrl),
            ClientMessagesSection(ctrl: ctrl),
            ClientProfileSection(ctrl: ctrl),
          ],
        ),
      ),
      bottomNavigationBar: _ClientBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        ctrl: ctrl,
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _ClientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ClientController ctrl;
  const _ClientBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CTheme.card,
        border: Border(top: BorderSide(color: CTheme.border)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
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
              if (i == 3) {
                // Badge mensagens
                iconW = Obx(() {
                  final count = ctrl.notificationCount.value;
                  return Stack(clipBehavior: Clip.none, children: [
                    Icon(sel ? item.activeIcon : item.icon,
                        color: sel ? CTheme.blue : CTheme.textLight, size: 22),
                    if (count > 0)
                      Positioned(
                        right: -4, top: -4,
                        child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(
                              color: CTheme.red, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$count',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 8,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                  ]);
                });
              } else {
                iconW = Icon(sel ? item.activeIcon : item.icon,
                    color: sel ? CTheme.blue : CTheme.textLight, size: 22);
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
                              color: sel ? CTheme.blue : CTheme.textLight,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
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
class _ClientDrawer extends StatelessWidget {
  final ClientController ctrl;
  const _ClientDrawer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      child: Column(children: [
        _DrawerHeader(ctrl: ctrl),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _DItem(Icons.home_rounded,            'Início',           () => _nav(context, 0)),
              _DItem(Icons.receipt_long_rounded,    'Solicitar Serviço',() => Get.back()),
              _DItem(Icons.calendar_today_rounded,  'Meus Agendamentos',() => _nav(context, 2)),
              _DItem(Icons.history_rounded,         'Histórico',        () => Get.back()),
              _DItem(Icons.favorite_rounded,        'Favoritos',        () => Get.back()),
              _DItem(Icons.chat_bubble_rounded,     'Mensagens',        () => _nav(context, 3),
                  badge: ctrl.notificationCount.value),
              _DItem(Icons.payment_rounded,         'Pagamentos',       () => Get.back()),
              _DItem(Icons.discount_rounded,        'Cupons',           () => Get.back()),
              _DItem(Icons.star_rounded,            'Avaliações',       () => Get.back()),
              _DItem(Icons.notifications_rounded,   'Notificações',     () => Get.back()),
              _DItem(Icons.settings_rounded,        'Configurações',    () => Get.back()),
              _DItem(Icons.help_rounded,            'Ajuda',            () => Get.back()),
              const Divider(indent: 16, endIndent: 16, height: 20),
              _DItem(Icons.logout_rounded,          'Sair',             ctrl.signOut,
                  color: CTheme.red),
            ],
          ),
        ),
      ]),
    );
  }

  void _nav(BuildContext ctx, int i) {
    Navigator.of(ctx).pop();
    // The parent StatefulWidget handles tab switching via setState
    // We use a simple approach: close drawer, the user sees current state
  }
}

class _DrawerHeader extends StatelessWidget {
  final ClientController ctrl;
  const _DrawerHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final u = ctrl.currentUser.value;
      final name = u?.name ?? ctrl.firstName;
      final email = u?.email ?? '';
      final phone = u?.phone ?? '';
      final initial = ctrl.nameInitial;

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CTheme.blue, CTheme.blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: u?.photoUrl != null
                  ? NetworkImage(u!.photoUrl!)
                  : null,
              child: u?.photoUrl == null
                  ? Text(initial,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w800))
                  : null,
            ),
            const Spacer(),
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
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(email,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(phone,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Get.toNamed(AppRoutes.clientProfile);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Editar perfil',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _DItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int badge;
  const _DItem(this.icon, this.label, this.onTap,
      {this.color, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final c = color ?? CTheme.textGray;
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
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: CTheme.red, borderRadius: BorderRadius.circular(10)),
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
