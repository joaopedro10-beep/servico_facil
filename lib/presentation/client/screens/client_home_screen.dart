import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../core/constants/app_routes.dart';
import '../controllers/client_controller.dart';
import 'sections/client_home_section.dart';
import 'sections/client_request_section.dart';
import 'sections/client_appointments_section.dart';
import 'sections/client_messages_section.dart';

// ─── Cor verde da logo ────────────────────────────────────────────────────────
class CTheme {
  static const primary      = Color(0xFF1D9E75);
  static const primaryDark  = Color(0xFF0F6E56);
  static const primaryLight = Color(0xFFE8F5F0);
  static const blue         = primary;
  static const blueDark     = primaryDark;
  static const blueLight    = primaryLight;
  static const red          = Color(0xFFD32F2F);
  static const amber        = Color(0xFFF9A825);
  static const card         = Color(0xFFFFFFFF);
  static const background   = Color(0xFFF5F7FA);
  static const border       = Color(0xFFE0E7EF);
  static const textDark     = Color(0xFF0D3D2E);
  static const textGray     = Color(0xFF546E7A);
  static const textLight    = Color(0xFF90A4AE);
}

// ─── Bottom nav — 4 abas (sem Perfil, que fica no Drawer) ────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.home_outlined,           Icons.home_rounded,           'Início'),
  _NavItem(Icons.add_circle_outline,      Icons.add_circle_rounded,     'Solicitar'),
  _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Agendamentos'),
  _NavItem(Icons.chat_bubble_outline,     Icons.chat_bubble_rounded,    'Mensagens'),
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
            ClientHomeSection(
              ctrl: ctrl,
              onMenuTap: _openDrawer,
              onSolicitar: () => _onNavTap(1),
            ),
            ClientRequestSection(ctrl: ctrl),
            ClientAppointmentsSection(ctrl: ctrl),
            ClientMessagesSection(ctrl: ctrl),
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
              final i   = e.key;
              final item = e.value;
              final sel  = currentIndex == i;

              Widget iconW;
              if (i == 3) {
                // Badge de mensagens não lidas
                iconW = Obx(() {
                  final count = ctrl.notificationCount.value;
                  return Stack(clipBehavior: Clip.none, children: [
                    Icon(sel ? item.activeIcon : item.icon,
                        color: sel ? CTheme.primary : CTheme.textLight,
                        size: 22),
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
              } else if (i == 1) {
                // Botão Solicitar com destaque especial
                iconW = Container(
                  padding: EdgeInsets.all(sel ? 8.0 : 6.0),
                  decoration: BoxDecoration(
                    color: sel
                        ? CTheme.primary
                        : CTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(sel ? item.activeIcon : item.icon,
                      color: sel ? Colors.white : CTheme.primary,
                      size: sel ? 22 : 20),
                );
              } else {
                iconW = Icon(sel ? item.activeIcon : item.icon,
                    color: sel ? CTheme.primary : CTheme.textLight,
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
                              color: sel ? CTheme.primary : CTheme.textLight,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400),
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
              _DItem(Icons.home_rounded, 'Início', () => Navigator.of(context).pop()),
              _DItem(Icons.add_circle_rounded, 'Solicitar Serviço',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.calendar_today_rounded, 'Meus Agendamentos',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.history_rounded, 'Histórico',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.favorite_rounded, 'Favoritos',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.chat_bubble_rounded, 'Mensagens',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.payment_rounded, 'Pagamentos',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.discount_rounded, 'Cupons',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.star_rounded, 'Avaliações',
                  () => Navigator.of(context).pop()),
              _DItem(Icons.notifications_rounded, 'Notificações',
                  () { Navigator.of(context).pop(); Get.toNamed(AppRoutes.notifications); }),
              _DItem(Icons.settings_rounded, 'Configurações',
                  () { Navigator.of(context).pop(); Get.toNamed(AppRoutes.settings); }),
              _DItem(Icons.help_rounded, 'Ajuda',
                  () => Navigator.of(context).pop()),
              const Divider(indent: 16, endIndent: 16, height: 20),
              _DItem(Icons.logout_rounded, 'Sair', ctrl.signOut,
                  color: CTheme.red),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Cabeçalho do Drawer (perfil do cliente) ─────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final ClientController ctrl;
  const _DrawerHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final u       = ctrl.currentUser.value;
      final name    = u?.name ?? ctrl.firstName;
      final email   = u?.email ?? '';
      final initial = ctrl.nameInitial;

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CTheme.primary, CTheme.primaryDark],
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
                  ? NetworkImage(u!.photoUrl!) : null,
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
                  color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(email,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    style: TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// ─── Item do drawer ───────────────────────────────────────────────────────────
class _DItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DItem(this.icon, this.label, this.onTap, {this.color});

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
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 14, color: c),
              overflow: TextOverflow.ellipsis, maxLines: 1)),
        ]),
      ),
    );
  }
}
