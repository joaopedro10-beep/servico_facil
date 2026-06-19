import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SettingsController());
    const version = '1.0.0'; // Atualizar via package_info_plus se necessário

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          // ── Aparência ──────────────────────────────────────────────
          _SectionHeader('Aparência'),
          Obx(() => SwitchListTile.adaptive(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Modo escuro'),
                value: ctrl.isDarkMode.value,
                activeColor: AppColors.primary,
                onChanged: ctrl.toggleDarkMode,
              )),

          // ── Notificações ───────────────────────────────────────────
          _SectionHeader('Notificações'),
          Obx(() => SwitchListTile.adaptive(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Notificações push'),
                subtitle: const Text('Pedidos, mensagens e atualizações'),
                value: ctrl.notificationsEnabled.value,
                activeColor: AppColors.primary,
                onChanged: ctrl.toggleNotifications,
              )),

          // ── Segurança ──────────────────────────────────────────────
          _SectionHeader('Segurança'),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Dicas de segurança'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(AppRoutes.safetyTips),
          ),

          // ── Sobre ──────────────────────────────────────────────────
          _SectionHeader('Sobre'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão do app'),
            trailing: Text(version,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidade'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(
                'https://servicofacil.com.br/privacidade'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Termos de uso'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () =>
                _launchUrl('https://servicofacil.com.br/termos'),
          ),

          // ── Conta ──────────────────────────────────────────────────
          _SectionHeader('Conta'),
          Obx(() => ListTile(
                leading: const Icon(Icons.delete_forever_outlined,
                    color: AppColors.error),
                title: const Text('Excluir minha conta',
                    style: TextStyle(color: AppColors.error)),
                subtitle: const Text(
                    'Remove todos os seus dados permanentemente'),
                trailing: ctrl.isDeletingAccount.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2))
                    : null,
                onTap: ctrl.isDeletingAccount.value
                    ? null
                    : () => ctrl.deleteAccount(
                        Get.context!),
              )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
