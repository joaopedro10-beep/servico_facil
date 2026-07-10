import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

class WorkerProfileSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerProfileSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final w = ctrl.worker.value;
      if (w == null) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      final name = w.name;
      final category =
          w.categories.isNotEmpty ? w.categories.first : '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
      final avg = ctrl.avgRating;

      return SingleChildScrollView(
        child: Column(children: [
          // Header azul com capa
          Container(
            color: WTheme.blue,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Row(children: [
              // Avatar com badge câmera
              Stack(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: w.photoUrl != null
                      ? NetworkImage(w.photoUrl!)
                      : null,
                  child: w.photoUrl == null
                      ? Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800))
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 13, color: WTheme.blue),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(category,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (avg > 0) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text('$avg (${w.totalReviews} avaliações)',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ],
                    const SizedBox(height: 4),
                    Text('${ctrl.totalCompleted} serviços concluídos',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações pessoais
                const _SectionTitle('Informações pessoais'),
                const SizedBox(height: 10),
                _InfoTile(label: 'Nome completo', value: w.name),
                const _Divider(),
                _InfoTile(label: 'Telefone', value: w.phone),
                const _Divider(),
                _InfoTile(label: 'E-mail', value: w.email),
                const _Divider(),
                _InfoTile(
                    label: 'Cidade',
                    value: '${w.city} – ${w.address.state}'),
                const SizedBox(height: 20),

                // Configurações
                const _SectionTitle('Configurações'),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  label: 'Editar perfil',
                  onTap: ctrl.goToEdit,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Alterar senha',
                  onTap: () {},
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificações',
                  onTap: () {},
                ),
                const SizedBox(height: 20),

                // Disponibilidade
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WTheme.border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ctrl.isAvailable.value
                            ? WTheme.green.withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ctrl.isAvailable.value
                            ? Icons.wifi_tethering_rounded
                            : Icons.wifi_tethering_off_rounded,
                        color: ctrl.isAvailable.value
                            ? WTheme.green
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctrl.isAvailable.value
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: ctrl.isAvailable.value
                                    ? WTheme.green
                                    : Colors.grey),
                          ),
                          Text(
                            ctrl.isAvailable.value
                                ? 'Disponível para novos serviços'
                                : 'Indisponível no momento',
                            style: const TextStyle(
                                fontSize: 12,
                                color: WTheme.textGray),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Obx(() => Switch.adaptive(
                          value: ctrl.isAvailable.value,
                          activeColor: WTheme.blue,
                          onChanged: ctrl.isTogglingAvailability.value
                              ? null
                              : ctrl.toggleAvailability,
                        )),
                  ]),
                ),
                const SizedBox(height: 20),

                // Botão Sair — com SafeArea para ficar acima dos botões do celular
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                          side: const BorderSide(color: WTheme.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: WTheme.textGray));
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: WTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded,
            size: 18, color: WTheme.textLight),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: WTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: WTheme.textLight),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 14, endIndent: 14,
        color: WTheme.border);
  }
}
