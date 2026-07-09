import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/user_model.dart';
import '../../admin_theme.dart';
import '../../controllers/admin_controller.dart';

class AdminUsersSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminUsersSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Busca
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: ctrl.searchUsers,
          decoration: InputDecoration(
            hintText: 'Buscar por nome, e-mail ou CPF...',
            hintStyle: const TextStyle(fontSize: 13, color: AdminTheme.textLight),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AdminTheme.textGray, size: 20),
            suffixIcon: Obx(() => ctrl.userSearchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => ctrl.searchUsers(''),
                  )
                : const SizedBox.shrink()),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AdminTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AdminTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AdminTheme.primary, width: 1.5)),
          ),
        ),
      ),

      // Lista
      Expanded(
        child: Obx(() {
          final users = ctrl.userSearchResults;
          if (users.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 56, color: AdminTheme.textLight),
                SizedBox(height: 12),
                Text('Nenhum cliente encontrado',
                    style: TextStyle(color: AdminTheme.textGray)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _UserCard(user: users[i], ctrl: ctrl),
          );
        }),
      ),
    ]);
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;
  const _UserCard({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isSuspended
              ? AdminTheme.red.withOpacity(0.3)
              : AdminTheme.border,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AdminTheme.primary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.primary, fontSize: 17),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 12, color: AdminTheme.textGray),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (user.isSuspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Suspenso',
                    style: TextStyle(fontSize: 10, color: AdminTheme.red,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 4, children: [
            if (user.cpf != null && user.cpf!.isNotEmpty)
              _Chip(Icons.badge_outlined, 'CPF cadastrado'),
            if (user.phone.isNotEmpty)
              _Chip(Icons.phone_outlined, user.phone),
            _Chip(Icons.calendar_today_outlined,
                'Desde ${AppFormatters.date(user.createdAt)}'),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _ActionBtn(
              label: user.isSuspended ? 'Remover Suspensão' : 'Suspender',
              color: user.isSuspended ? AdminTheme.green : AdminTheme.amber,
              onTap: user.isSuspended
                  ? () => ctrl.unsuspendUser(user)
                  : () => ctrl.suspendUser(user),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              label: 'Banir',
              color: AdminTheme.red,
              onTap: () => ctrl.banUser(user),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AdminTheme.textLight),
      const SizedBox(width: 3),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AdminTheme.textGray),
          overflow: TextOverflow.ellipsis),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }
}
