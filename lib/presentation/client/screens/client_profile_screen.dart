import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/dialogs/error_banner.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../data/models/user_model.dart';
import '../controllers/client_profile_controller.dart';

// ─── Tela de perfil ───────────────────────────────────────────────────────────
class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ClientProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          Obx(() => !ctrl.isEditing.value
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar perfil',
                  onPressed: ctrl.startEditing,
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: ctrl.loadUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(ctrl: ctrl),
                const SizedBox(height: 20),
                if (ctrl.hasIncompleteData) _PendingDataBanner(ctrl: ctrl),
                Obx(() => ctrl.isEditing.value
                    ? _EditForm(ctrl: ctrl)
                    : _ProfileData(ctrl: ctrl)),
                const SizedBox(height: 28),
                Obx(() => !ctrl.isEditing.value
                    ? _LogoutButton(onTap: ctrl.logout)
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final ClientProfileController ctrl;
  const _ProfileHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(children: [
          _AvatarWidget(initial: ctrl.nameInitial, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ctrl.displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(ctrl.displayEmail,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                if (ctrl.currentUser.value?.authProvider ==
                    UserAuthProvider.google) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Conta Google',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ]));
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String initial;
  final double size;
  const _AvatarWidget({required this.initial, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Banner dados pendentes ───────────────────────────────────────────────────
class _PendingDataBanner extends StatelessWidget {
  final ClientProfileController ctrl;
  const _PendingDataBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.warning, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cadastro pendente',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
              'Complete seu CPF, telefone e endereço para poder '
              'solicitar serviços. Enquanto pendente, você pode '
              'navegar e ver os prestadores.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.completeProfile),
              child: const Text('Completar agora →',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Visualização dos dados ───────────────────────────────────────────────────
class _ProfileData extends StatelessWidget {
  final ClientProfileController ctrl;
  const _ProfileData({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ctrl.successMessage.value.isNotEmpty)
              _SuccessBanner(ctrl.successMessage.value),
            _InfoCard(children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'CPF',
                value: ctrl.displayCpf,
                missing: ctrl.currentUser.value?.cpf == null ||
                    ctrl.currentUser.value!.cpf!.isEmpty,
              ),
              const _RowDivider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone / WhatsApp',
                value: ctrl.displayPhone,
                missing: ctrl.currentUser.value?.phone.isEmpty ?? true,
              ),
              const _RowDivider(),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Endereço',
                value: ctrl.displayAddress,
                missing:
                    ctrl.currentUser.value?.address.city.isEmpty ?? true,
              ),
            ]),
          ],
        ));
  }
}

// ─── Formulário de edição ─────────────────────────────────────────────────────
class _EditForm extends StatelessWidget {
  final ClientProfileController ctrl;
  const _EditForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: ctrl.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Editar dados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        AppTextField(
          controller: ctrl.nameCtrl,
          label: 'Nome completo',
          prefixIcon: const Icon(Icons.person_outline),
          validator: Validators.name,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: ctrl.phoneCtrl,
          label: 'Telefone / WhatsApp',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: Validators.phone,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: ctrl.cpfCtrl,
          label: 'CPF',
          hint: '00000000000',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            return Validators.cpf(v);
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada CPF permite apenas um cadastro no ServiçoFácil.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _InfoNote(
          icon: Icons.info_outline,
          text:
              'Para alterar o endereço, use a opção "Completar cadastro" '
              'que aparece quando os dados estão pendentes.',
        ),
        const SizedBox(height: 20),
        Obx(() => ctrl.errorMessage.value.isNotEmpty
            ? ErrorBanner(ctrl.errorMessage.value)
            : const SizedBox.shrink()),
        Obx(() => PrimaryButton(
              label: 'Salvar alterações',
              isLoading: ctrl.isSaving.value,
              onPressed: ctrl.saveProfile,
            )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: ctrl.cancelEditing,
            child: const Text('Cancelar'),
          ),
        ),
      ]),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Sair da conta',
            style: TextStyle(
                color: AppColors.error, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_outline,
            color: AppColors.success, size: 18),
        const SizedBox(width: 8),
        Text(message,
            style: const TextStyle(color: AppColors.success, fontSize: 13)),
      ]),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.info, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: AppColors.info)),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool missing;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 20,
            color: missing ? AppColors.textHint : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    color: missing
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontStyle: missing ? FontStyle.italic : FontStyle.normal)),
          ]),
        ),
        if (missing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Pendente',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5, indent: 48, endIndent: 16);
  }
}

// ─── Drawer lateral ───────────────────────────────────────────────────────────
class ClientDrawer extends StatelessWidget {
  const ClientDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClientProfileController>();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  border: Border(
                      bottom: BorderSide(
                          color: AppColors.border, width: 0.5)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AvatarWidget(initial: ctrl.nameInitial, size: 60),
                      const SizedBox(height: 12),
                      Text(ctrl.displayName,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(ctrl.displayEmail,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (ctrl.hasIncompleteData) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 12, color: AppColors.warning),
                                SizedBox(width: 4),
                                Text('Cadastro pendente',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ),
                      ],
                    ]),
              )),

          // ── Itens de menu ───────────────────────────────────────────────
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _DrawerItem(
                icon: Icons.person_outline,
                label: 'Meu Perfil',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.clientProfile);
                },
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'Meus Pedidos',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.myOrders);
                },
              ),
              _DrawerItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Mensagens',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.chatsList);
                },
              ),
              _DrawerItem(
                icon: Icons.notifications_outlined,
                label: 'Notificações',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.notifications);
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.settings);
                },
              ),
              _DrawerItem(
                icon: Icons.security_outlined,
                label: 'Dicas de segurança',
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.safetyTips);
                },
              ),
              const Divider(height: 1, thickness: 0.5),
            ]),
          ),

          // ── Logout ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: ctrl.logout,
                icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                label: const Text('Sair da conta',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      horizontalTitleGap: 8,
    );
  }
}
