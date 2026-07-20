import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/order_model.dart';
import '../../controllers/worker_controller.dart';
import '../worker_home_screen.dart' show WTheme;

class WorkerAgendaSection extends StatefulWidget {
  final WorkerController ctrl;
  const WorkerAgendaSection({super.key, required this.ctrl});

  @override
  State<WorkerAgendaSection> createState() => _WorkerAgendaSectionState();
}

class _WorkerAgendaSectionState extends State<WorkerAgendaSection> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(
            _focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(
            _focusedMonth.year, _focusedMonth.month + 1);
      });

  List<OrderModel> _ordersForDay(DateTime day, List<OrderModel> all) {
    return all.where((o) {
      final d = o.scheduledAt;
      if (d == null) return false;
      return d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }

  List<OrderModel> _ordersForSelectedDay(List<OrderModel> all) =>
      _ordersForDay(_selectedDay, all);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: WTheme.blue,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: const Text('Agenda',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),

      Expanded(
        child: Obx(() {
          final orders = widget.ctrl.allOrders
              .where((o) =>
                  o.status != OrderStatus.cancelled)
              .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Calendário
              _CalendarCard(
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                orders: orders,
                onDayTap: (d) => setState(() => _selectedDay = d),
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: 16),

              // Serviços do dia selecionado
              _DaySchedule(
                day: _selectedDay,
                orders: _ordersForSelectedDay(orders),
                ctrl: widget.ctrl,
              ),
            ]),
          );
        }),
      ),
    ]);
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<OrderModel> orders;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDay,
    required this.orders,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
  });

  bool _hasOrder(DateTime day) => orders.any((o) {
    final d = o.scheduledAt;
    if (d == null) return false;
    return d.year == day.year &&
        d.month == day.month &&
        d.day == day.day;
  });


  bool _isToday(DateTime day) {
    final n = DateTime.now();
    return day.year == n.year &&
        day.month == n.month &&
        day.day == n.day;
  }

  bool _isSelected(DateTime day) =>
      day.year == selectedDay.year &&
      day.month == selectedDay.month &&
      day.day == selectedDay.day;

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final daysInMonth = DateUtils.getDaysInMonth(
        focusedMonth.year, focusedMonth.month);
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(focusedMonth);
    const headers = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    final cells = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) cells.add(null);
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(focusedMonth.year, focusedMonth.month, d));
    }
    while (cells.length % 7 != 0) cells.add(null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Navegação mês
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: onPrev,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              monthLabel[0].toUpperCase() + monthLabel.substring(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: WTheme.textDark),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: onNext,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 10),

        // Cabeçalho dias
        Row(children: headers
            .map((h) => Expanded(
                  child: Center(
                    child: Text(h,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: WTheme.textGray)),
                  ),
                ))
            .toList()),
        const SizedBox(height: 8),

        // Grid de dias
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells.map((day) {
            if (day == null) return const SizedBox.shrink();
            final selected = _isSelected(day);
            final today = _isToday(day);
            final hasOrd = _hasOrder(day);

            return GestureDetector(
              onTap: () => onDayTap(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selected
                      ? WTheme.blue
                      : today
                          ? WTheme.blueLight
                          : null,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected || today
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? Colors.white
                                : today
                                    ? WTheme.blue
                                    : WTheme.textDark)),
                    if (hasOrd)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.8)
                              : WTheme.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final DateTime day;
  final List<OrderModel> orders;
  final WorkerController ctrl;
  const _DaySchedule({
    required this.day,
    required this.orders,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(day);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(dayLabel,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: WTheme.textDark)),
      const SizedBox(height: 10),
      if (orders.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WTheme.border),
          ),
          child: const Row(children: [
            Icon(Icons.event_available_rounded,
                color: WTheme.green, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text('Nenhum serviço neste dia.',
                  style: TextStyle(
                      color: WTheme.textGray, fontSize: 13),
                  overflow: TextOverflow.ellipsis, maxLines: 2),
            ),
          ]),
        )
      else
        ...orders.map((o) => _AgendaItem(order: o, ctrl: ctrl)),
      const SizedBox(height: 16),
      // FAB adicionar (visual only)
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
              color: WTheme.blue, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    ]);
  }
}

class _AgendaItem extends StatelessWidget {
  final OrderModel order;
  final WorkerController ctrl;
  const _AgendaItem({required this.order, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('HH:mm').format(order.scheduledAt ?? DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Hora
          SizedBox(
            width: 44,
            child: Text(time,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: WTheme.textDark)),
          ),
          Container(
            width: 3, height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: WTheme.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Foto + info
          CircleAvatar(
            radius: 18,
            backgroundColor: WTheme.blue.withOpacity(0.1),
            child: Text(
              order.clientName?.isNotEmpty == true
                  ? order.clientName![0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                  color: WTheme.blue,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.serviceCategory,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(order.clientName ?? 'Cliente',
                    style: const TextStyle(
                        fontSize: 12, color: WTheme.textGray),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: WTheme.amberBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Agendado',
                style: TextStyle(
                    fontSize: 10,
                    color: WTheme.amber,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
