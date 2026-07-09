import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/worker_model.dart';
import '../../admin_theme.dart';
import '../../controllers/admin_controller.dart';

class AdminWorkersSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminWorkersSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tabs
      Obx(() => Container(
        color: Colors.white,
        child: Row(children: [
          _Tab(
            label: 'Pendentes',
            count: ctrl.pendingWorkers.length,
            selected: ctrl.workerTab.value == 0,
            color: AdminTheme.amber,
            onTap: () => ctrl.workerTab.value = 0,
          ),
          _Tab(
            label: 'Todos',
            count: ctrl.allWorkers.length,
            selected: ctrl.workerTab.value == 1,
            color: AdminTheme.primary,
            onTap: () => ctrl.workerTab.value = 1,
          ),
        ]),
      )),
      const Divider(height: 1),

      // Lista
      Expanded(
        child: Obx(() {
          final list = ctrl.displayedWorkers;
          if (list.isEmpty) {
            return _EmptyState(
              icon: Icons.engineering_outlined,
              message: ctrl.workerTab.value == 0
                  ? 'Nenhum prestador pendente'
                  : 'Nenhum prestador cadastrado',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _WorkerCard(
              worker: list[i],
              ctrl: ctrl,
              showApproveActions: ctrl.workerTab.value == 0,
            ),
          );
        }),
      ),
    ]);
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Tab({
    required this.label, required this.count,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AdminTheme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? AdminTheme.primary : AdminTheme.textGray)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.12) : AdminTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: selected ? color : AdminTheme.textGray)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final AdminController ctrl;
  final bool showApproveActions;
  const _WorkerCard({
    required this.worker, required this.ctrl,
    required this.showApproveActions,
  });

  Color get _statusColor {
    switch (worker.verificationStatus) {
      case VerificationStatus.pending:  return AdminTheme.amber;
      case VerificationStatus.approved: return AdminTheme.green;
      case VerificationStatus.rejected: return AdminTheme.red;
    }
  }

  String get _statusLabel {
    switch (worker.verificationStatus) {
      case VerificationStatus.pending:  return 'Pendente';
      case VerificationStatus.approved: return 'Aprovado';
      case VerificationStatus.rejected: return 'Rejeitado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AdminTheme.primary.withOpacity(0.1),
              backgroundImage: worker.photoUrl != null
                  ? NetworkImage(worker.photoUrl!) : null,
              child: worker.photoUrl == null
                  ? Text(
                      worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AdminTheme.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worker.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(worker.categories.isNotEmpty
                    ? worker.categories.first : '—',
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textGray),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(worker.email,
                    style: const TextStyle(fontSize: 11, color: AdminTheme.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(fontSize: 11, color: _statusColor,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          // Infos
          Row(children: [
            _InfoChip(Icons.location_on_outlined, worker.city),
            const SizedBox(width: 12),
            _InfoChip(Icons.phone_outlined, worker.phone),
            const SizedBox(width: 12),
            _InfoChip(Icons.calendar_today_outlined,
                AppFormatters.date(worker.createdAt)),
          ]),
          if (showApproveActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _SmallBtn(
                  label: 'Rejeitar',
                  color: AdminTheme.red,
                  onTap: () => ctrl.rejectWorker(worker),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallBtn(
                  label: 'Documentos',
                  color: AdminTheme.amber,
                  onTap: () => ctrl.requestDocuments(worker),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallBtn(
                  label: 'Aprovar',
                  color: AdminTheme.green,
                  filled: true,
                  onTap: () => ctrl.approveWorker(worker),
                ),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: worker.isSuspended
                    ? () => ctrl.unsuspendWorker(worker)
                    : () => ctrl.suspendWorker(worker),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: worker.isSuspended
                        ? AdminTheme.green.withOpacity(0.1)
                        : AdminTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: worker.isSuspended
                            ? AdminTheme.green.withOpacity(0.3)
                            : AdminTheme.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    worker.isSuspended ? 'Remover Suspensão' : 'Suspender',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: worker.isSuspended
                            ? AdminTheme.green : AdminTheme.red),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AdminTheme.textLight),
      const SizedBox(width: 3),
      Flexible(
        child: Text(label,
            style: const TextStyle(fontSize: 11, color: AdminTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    ]);
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.label, required this.color,
    required this.onTap, this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: AdminTheme.textLight),
        const SizedBox(height: 12),
        Text(message,
            style: const TextStyle(color: AdminTheme.textGray, fontSize: 15),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
