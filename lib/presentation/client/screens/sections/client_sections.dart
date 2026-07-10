// ═══════════════════════════════════════════════════════════════════════════
// BUSCAR
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/order_model.dart';
import '../../controllers/client_controller.dart';
import '../client_home_screen.dart' show CTheme;

class ClientSearchSection extends StatefulWidget {
  final ClientController ctrl;
  const ClientSearchSection({super.key, required this.ctrl});

  @override
  State<ClientSearchSection> createState() => _ClientSearchSectionState();
}

class _ClientSearchSectionState extends State<ClientSearchSection> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header + campo de busca
      Container(
        color: CTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: TextField(
          controller: _searchCtrl,
          onChanged: widget.ctrl.onSearch,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Qual serviço você precisa hoje?',
            hintStyle: const TextStyle(
                fontSize: 13, color: CTheme.textGray),
            prefixIcon: const Icon(Icons.search_rounded,
                color: CTheme.textGray, size: 20),
            suffixIcon: Obx(() => widget.ctrl.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      widget.ctrl.onSearch('');
                    })
                : const SizedBox.shrink()),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      ),

      // Resultados
      Expanded(
        child: Obx(() {
          final workers = widget.ctrl.filteredWorkers;
          if (widget.ctrl.isLoadingWorkers.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (workers.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_off_rounded,
                    size: 56, color: CTheme.textLight),
                const SizedBox(height: 12),
                Text(
                  widget.ctrl.searchQuery.value.isNotEmpty
                      ? 'Nenhum resultado para "${widget.ctrl.searchQuery.value}"'
                      : 'Comece a digitar para buscar',
                  style: const TextStyle(
                      color: CTheme.textGray, fontSize: 14),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis, maxLines: 2,
                ),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final w = workers[i];
              final dist = widget.ctrl.distanceToWorker(w);
              return GestureDetector(
                onTap: () => widget.ctrl.goToWorkerProfile(w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CTheme.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000),
                          blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: CTheme.blueLight,
                        backgroundImage: w.photoUrl != null
                            ? NetworkImage(w.photoUrl!)
                            : null,
                        child: w.photoUrl == null
                            ? Text(
                                w.name.isNotEmpty
                                    ? w.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: CTheme.blue))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              w.categories.isNotEmpty
                                  ? w.categories.join(', ')
                                  : '—',
                              style: const TextStyle(
                                  fontSize: 12, color: CTheme.textGray),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 13),
                              const SizedBox(width: 3),
                              Text(w.avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'R\$ ${w.pricePerHour.toStringAsFixed(0)}/h',
                                  style: const TextStyle(
                                      fontSize: 11, color: CTheme.textGray),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (widget.ctrl.locationGranted.value && dist > 0)
                              Text('${dist.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: CTheme.blue,
                                      fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: CTheme.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Ver',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                    ]),
                  ),
                ),
              );
            },
          );
        }),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AGENDAMENTOS
// ═══════════════════════════════════════════════════════════════════════════

class ClientAppointmentsSection extends StatefulWidget {
  final ClientController ctrl;
  const ClientAppointmentsSection({super.key, required this.ctrl});

  @override
  State<ClientAppointmentsSection> createState() =>
      _ClientAppointmentsSectionState();
}

class _ClientAppointmentsSectionState extends State<ClientAppointmentsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: CTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Meus Agendamentos',
              style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Concluídos'),
              Tab(text: 'Cancelados'),
            ],
          ),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final all    = widget.ctrl.myOrders;
          final done   = widget.ctrl.doneOrders;
          final cancelled = all
              .where((o) => o.status == OrderStatus.cancelled)
              .toList();
          return TabBarView(
            controller: _tab,
            children: [
              _OrderList(orders: all,       emptyMsg: 'Nenhum agendamento'),
              _OrderList(orders: done,      emptyMsg: 'Nenhum serviço concluído'),
              _OrderList(orders: cancelled, emptyMsg: 'Nenhum cancelado'),
            ],
          );
        }),
      ),
    ]);
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMsg;
  const _OrderList({required this.orders, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined,
              size: 54, color: CTheme.textLight),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: const TextStyle(color: CTheme.textGray, fontSize: 14)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AppointmentCard(order: orders[i]),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final OrderModel order;
  const _AppointmentCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return CTheme.amber;
      case OrderStatus.accepted:   return CTheme.blue;
      case OrderStatus.inProgress: return const Color(0xFF8B5CF6);
      case OrderStatus.done:       return CTheme.green;
      case OrderStatus.cancelled:  return CTheme.red;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:    return 'Pendente';
      case OrderStatus.accepted:   return 'Aceito';
      case OrderStatus.inProgress: return 'Em andamento';
      case OrderStatus.done:       return 'Concluído';
      case OrderStatus.cancelled:  return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR');
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: CTheme.blueLight,
              child: Text(
                order.workerName?.isNotEmpty == true
                    ? order.workerName![0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: CTheme.blue,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.workerName ?? 'Prestador',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(order.serviceCategory,
                      style: const TextStyle(
                          fontSize: 13, color: CTheme.textGray),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(children: [
                    const Icon(Icons.attach_money_rounded,
                        size: 13, color: CTheme.textLight),
                    Text(
                      order.price != null
                          ? 'R\$ ${order.price!.toStringAsFixed(2).replaceAll('.', ',')}'
                          : '—',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: CTheme.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(fmt.format(order.scheduledAt),
                          style: const TextStyle(
                              fontSize: 11, color: CTheme.textGray),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(
                            fontSize: 10, color: _statusColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: CTheme.textLight, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MENSAGENS
// ═══════════════════════════════════════════════════════════════════════════

class ClientMessagesSection extends StatelessWidget {
  final ClientController ctrl;
  const ClientMessagesSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // Lista fictícia baseada nos pedidos com status ativo
    return Column(children: [
      Container(
        color: CTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: const Row(children: [
          Expanded(
            child: Text('Mensagens',
                style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          Icon(Icons.edit_outlined, color: Colors.white70, size: 22),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final orders = ctrl.myOrders
              .where((o) =>
                  o.status != OrderStatus.cancelled)
              .toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 54, color: CTheme.textLight),
                const SizedBox(height: 12),
                const Text('Nenhuma conversa ainda.',
                    style: TextStyle(color: CTheme.textGray, fontSize: 14)),
              ]),
            );
          }

          // Adiciona um item de suporte ao final
          final items = [...orders];
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length + 1,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 70),
            itemBuilder: (_, i) {
              if (i == items.length) {
                return _ChatTile(
                  avatar: '🛡️',
                  name: 'Suporte Serviço Fácil',
                  lastMessage: 'Como podemos ajudar?',
                  time: '3 dias',
                  unread: 0,
                  isSupport: true,
                );
              }
              final o = items[i];
              return _ChatTile(
                avatar: o.workerName?.isNotEmpty == true
                    ? o.workerName![0].toUpperCase()
                    : 'P',
                name: o.workerName ?? 'Prestador',
                lastMessage: _lastMessage(o),
                time: _formatTime(o.updatedAt),
                unread: o.status == OrderStatus.inProgress ? 1 : 0,
                onTap: () => Get.toNamed(AppRoutes.chat, arguments: o),
              );
            },
          );
        }),
      ),
    ]);
  }

  String _lastMessage(OrderModel o) {
    switch (o.status) {
      case OrderStatus.pending:    return 'Aguardando confirmação...';
      case OrderStatus.accepted:   return 'Serviço confirmado!';
      case OrderStatus.inProgress: return 'Cheguei aqui e já vou iniciar o serviço...';
      case OrderStatus.done:       return 'Serviço concluído com sucesso 👍';
      case OrderStatus.cancelled:  return 'Solicitação cancelada';
    }
  }

  String _formatTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias';
  }
}

class _ChatTile extends StatelessWidget {
  final String avatar;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isSupport;
  final VoidCallback? onTap;

  const _ChatTile({
    required this.avatar,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isSupport = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Get.toNamed(AppRoutes.chatsList),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isSupport
                ? CTheme.blue.withOpacity(0.15)
                : CTheme.blueLight,
            child: Text(
              avatar,
              style: TextStyle(
                  fontSize: isSupport ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: CTheme.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(lastMessage,
                    style: TextStyle(
                        fontSize: 12,
                        color: unread > 0
                            ? CTheme.textDark
                            : CTheme.textGray,
                        fontWeight: unread > 0
                            ? FontWeight.w600
                            : FontWeight.w400),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time,
                  style: TextStyle(
                      fontSize: 11,
                      color: unread > 0 ? CTheme.blue : CTheme.textLight)),
              const SizedBox(height: 4),
              if (unread > 0)
                Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: CTheme.blue, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$unread',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERFIL
// ═══════════════════════════════════════════════════════════════════════════

class ClientProfileSection extends StatelessWidget {
  final ClientController ctrl;
  const ClientProfileSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final u = ctrl.currentUser.value;
      if (u == null) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      final name    = u.name;
      final initial = ctrl.nameInitial;
      final avg     = 4.9; // placeholder

      return SingleChildScrollView(
        child: Column(children: [
          // Header azul
          Container(
            color: CTheme.blue,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Row(children: [
              // Avatar
              Stack(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: u.photoUrl != null
                      ? NetworkImage(u.photoUrl!)
                      : null,
                  child: u.photoUrl == null
                      ? Text(initial,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28,
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
                        size: 13, color: CTheme.blue),
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
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (u.address.city.isNotEmpty)
                      Text('${u.address.city} – ${u.address.state}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(u.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (u.phone.isNotEmpty)
                      Text(u.phone,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
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
                const SizedBox(height: 8),
                _InfoTile(label: 'Nome completo', value: name),
                const _Divider(),
                _InfoTile(label: 'Telefone',
                    value: u.phone.isNotEmpty ? u.phone : 'Não informado'),
                const _Divider(),
                _InfoTile(label: 'E-mail', value: u.email),
                const _Divider(),
                _InfoTile(
                    label: 'Cidade',
                    value: u.address.city.isNotEmpty
                        ? '${u.address.city} – ${u.address.state}'
                        : 'Não informado'),
                const SizedBox(height: 20),

                // Configurações
                const _SectionTitle('Configurações'),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  label: 'Editar perfil',
                  onTap: () => Get.toNamed(AppRoutes.clientProfile),
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
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
                const SizedBox(height: 20),

                // Sair
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: ctrl.signOut,
                    icon: const Icon(Icons.logout_rounded, color: CTheme.red),
                    label: const Text('Sair da conta',
                        style: TextStyle(
                            color: CTheme.red, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CTheme.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
          fontSize: 12, fontWeight: FontWeight.w700, color: CTheme.textGray));
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
              style: const TextStyle(fontSize: 13, color: CTheme.textGray),
              overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis, maxLines: 1,
              textAlign: TextAlign.end),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 18, color: CTheme.textLight),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: CTheme.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis, maxLines: 1)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: CTheme.textLight),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 14, endIndent: 14, color: CTheme.border);
}
