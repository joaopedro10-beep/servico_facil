import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

/// Aba "Serviços" — o prestador ativa/desativa as categorias
/// que quer receber chamadas, como na 99 o motorista desativa entregas.
class WorkerServicesSection extends StatelessWidget {
  final WorkerController ctrl;
  const WorkerServicesSection({super.key, required this.ctrl});

  static const _allCategories = [
    ('Eletricista',         Icons.electrical_services_rounded),
    ('Encanador',           Icons.plumbing_rounded),
    ('Pintor',              Icons.format_paint_rounded),
    ('Pedreiro',            Icons.construction_rounded),
    ('Jardineiro',          Icons.park_rounded),
    ('Diarista',            Icons.cleaning_services_rounded),
    ('Montador de Móveis',  Icons.chair_rounded),
    ('Ar-condicionado',     Icons.ac_unit_rounded),
    ('Chaveiro',            Icons.vpn_key_rounded),
    ('Mudança',             Icons.local_shipping_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: WTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Meus Serviços',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Ative ou desative os serviços que deseja receber chamadas.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis, maxLines: 2,
          ),
        ]),
      ),

      Expanded(
        child: Obx(() {
          final w = ctrl.worker.value;
          if (w == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          // Categorias que o prestador cadastrou
          final myCats = w.categories;
          // Categorias atualmente ativas
          final activeCats = w.activeCategories.isNotEmpty
              ? w.activeCategories
              : List<String>.from(w.categories);

          if (myCats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.handyman_outlined,
                      size: 56, color: WTheme.textLight),
                  const SizedBox(height: 12),
                  const Text('Nenhum serviço cadastrado.',
                      style: TextStyle(color: WTheme.textGray, fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/edit-worker-profile'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: WTheme.primary),
                    child: const Text('Editar perfil',
                        style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ),
            );
          }

          // Status de chamadas bloqueado se tem serviço ativo
          final blocked = ctrl.hasActiveJob;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Aviso quando tem serviço ativo
              if (blocked) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: WTheme.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WTheme.amber.withOpacity(0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.lock_clock_rounded,
                        color: WTheme.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você tem um serviço em andamento. '
                        'Novas chamadas ficam pausadas até concluir.',
                        style: TextStyle(
                            fontSize: 12, color: WTheme.amber, height: 1.4),
                        overflow: TextOverflow.ellipsis, maxLines: 3,
                      ),
                    ),
                  ]),
                ),
              ],

              // Lista de categorias do prestador
              const Text('Categorias cadastradas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: WTheme.textGray)),
              const SizedBox(height: 10),

              ...myCats.map((cat) {
                final icon = _iconFor(cat);
                final isActive = activeCats.contains(cat);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive && !blocked
                          ? WTheme.primary.withOpacity(0.3)
                          : WTheme.border,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000),
                          blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive && !blocked
                              ? WTheme.primary.withOpacity(0.1)
                              : WTheme.border.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            color: isActive && !blocked
                                ? WTheme.primary : WTheme.textLight,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isActive && !blocked
                                        ? WTheme.textDark : WTheme.textGray),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                            Text(
                              isActive && !blocked
                                  ? 'Recebendo chamadas'
                                  : blocked ? 'Pausado (serviço ativo)' : 'Desativado',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isActive && !blocked
                                      ? WTheme.green : WTheme.textLight),
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Sliding switch
                      Switch.adaptive(
                        value: isActive && !blocked,
                        activeColor: WTheme.primary,
                        onChanged: blocked
                            ? null
                            : (val) {
                                final updated = List<String>.from(activeCats);
                                if (val) {
                                  if (!updated.contains(cat)) updated.add(cat);
                                } else {
                                  updated.remove(cat);
                                }
                                ctrl.updateActiveCategories(updated);
                              },
                      ),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Estatísticas rápidas
              const Text('Chamadas de hoje',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: WTheme.textGray)),
              const SizedBox(height: 10),
              Obx(() {
                final avail = ctrl.availableOrders;
                if (avail.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WTheme.border),
                    ),
                    child: const Row(children: [
                      Icon(Icons.inbox_outlined,
                          color: WTheme.textLight, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nenhuma chamada disponível no momento.',
                          style: TextStyle(
                              color: WTheme.textGray, fontSize: 13),
                          overflow: TextOverflow.ellipsis, maxLines: 2,
                        ),
                      ),
                    ]),
                  );
                }
                return Column(
                  children: avail.take(3).map((o) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: WTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.phone_in_talk_rounded,
                          color: WTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.serviceCategory,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                            Text(o.clientName ?? 'Cliente',
                                style: const TextStyle(
                                    fontSize: 11, color: WTheme.textGray),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Nova',
                            style: TextStyle(
                                color: WTheme.primary, fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  )).toList(),
                );
              }),
            ],
          );
        }),
      ),
    ]);
  }

  IconData _iconFor(String cat) {
    for (final c in _allCategories) {
      if (c.$1.toLowerCase() == cat.toLowerCase()) return c.$2;
    }
    return Icons.handyman_rounded;
  }
}
