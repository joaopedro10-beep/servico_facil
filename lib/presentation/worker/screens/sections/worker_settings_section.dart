import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_routes.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Tela de Configurações do prestador.
class WorkerSettingsSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerSettingsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: const Text('Configurações',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Section('Conta', [
              _Tile(
                icon: Icons.person_rounded,
                label: 'Editar perfil',
                subtitle: 'Nome, foto, categorias',
                onTap: () => Get.toNamed(AppRoutes.editWorkerProfile),
              ),
              _Tile(
                icon: Icons.lock_rounded,
                label: 'Alterar senha',
                subtitle: 'Segurança da conta',
                onTap: () => _showComingSoon('Alterar senha'),
              ),
              _Tile(
                icon: Icons.badge_rounded,
                label: 'Documentos',
                subtitle: 'Verificação de identidade',
                onTap: () => _showComingSoon('Documentos'),
              ),
            ]),
            _Section('Preferências', [
              _TileSwitch(
                icon: Icons.wifi_tethering_rounded,
                label: 'Disponível para chamados',
                subtitle: 'Receber novas solicitações',
                value: ctrl.isAvailable,
                onChanged: ctrl.toggleAvailability,
              ),
              _Tile(
                icon: Icons.category_rounded,
                label: 'Serviços que ofereço',
                subtitle: 'Gerenciar categorias ativas',
                onTap: () => _showComingSoon('Serviços'),
              ),
              _Tile(
                icon: Icons.notifications_rounded,
                label: 'Notificações',
                subtitle: 'Sons, alertas e badges',
                onTap: () => _showComingSoon('Notificações'),
              ),
            ]),
            _Section('Pagamentos', [
              _Tile(
                icon: Icons.account_balance_rounded,
                label: 'Conta bancária',
                subtitle: 'Para receber pagamentos',
                onTap: () => _showComingSoon('Conta bancária'),
              ),
              _Tile(
                icon: Icons.pix_rounded,
                label: 'Chave PIX',
                subtitle: 'Receba via PIX',
                onTap: () => _showComingSoon('Chave PIX'),
              ),
            ]),
            _Section('Suporte', [
              _Tile(
                icon: Icons.help_rounded,
                label: 'Central de ajuda',
                subtitle: 'Dúvidas e tutoriais',
                onTap: () => _showComingSoon('Ajuda'),
              ),
              _Tile(
                icon: Icons.shield_rounded,
                label: 'Dicas de segurança',
                subtitle: 'Boas práticas na plataforma',
                onTap: () => Get.toNamed(AppRoutes.safetyTips),
              ),
              _Tile(
                icon: Icons.description_rounded,
                label: 'Termos de uso',
                subtitle: 'Políticas da plataforma',
                onTap: () => _showComingSoon('Termos'),
              ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: ctrl.signOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: WTheme.red),
                    label: const Text('Sair da conta',
                        style: TextStyle(
                            color: WTheme.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: WTheme.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ]);
  }

  void _showComingSoon(String name) {
    Get.snackbar(
      name,
      'Em breve disponível.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: WTheme.primaryLight,
      colorText: WTheme.primary,
      duration: const Duration(seconds: 2),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WTheme.textGray,
                letterSpacing: 1.2),
            overflow: TextOverflow.ellipsis),
      ),
      Container(
        color: Colors.white,
        child: Column(children: children),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: WTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: WTheme.textGray),
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: WTheme.textLight, size: 20),
          ]),
        ),
      ),
      const Divider(height: 1, indent: 54),
    ]);
  }
}

class _TileSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final RxBool value;
  final void Function(bool) onChanged;
  const _TileSwitch({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: WTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: WTheme.textGray),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          Obx(() => Switch.adaptive(
                value: value.value,
                activeColor: WTheme.primary,
                onChanged: onChanged,
              )),
        ]),
      ),
      const Divider(height: 1, indent: 54),
    ]);
  }
}
