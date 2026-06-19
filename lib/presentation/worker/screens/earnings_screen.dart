import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _ds = Get.find<FirestoreDatasource>();
  final _fb = Get.find<FirebaseService>();

  List<OrderModel> _orders = [];
  bool _loading = true;
  _Period _period = _Period.month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _ds.watchWorkerOrders(_fb.uid).first.then((list) {
      if (mounted) {
        setState(() {
          _orders = list
              .where((o) => o.status == OrderStatus.done)
              .toList();
          _loading = false;
        });
      }
    });
  }

  List<OrderModel> get _filtered {
    final now = DateTime.now();
    return _orders.where((o) {
      if (_period == _Period.week) {
        return now.difference(o.completedAt ?? o.updatedAt).inDays <= 7;
      }
      final m = o.completedAt ?? o.updatedAt;
      return m.year == now.year && m.month == now.month;
    }).toList();
  }

  double get _totalEstimate =>
      _filtered.fold(0, (sum, o) => sum + (o.price ?? 0));

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy', 'pt_BR');
    final moneyFmt =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Ganhos estimados')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Aviso ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Os valores são estimativas baseadas nos preços cadastrados. O app não processa pagamentos diretamente.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filtro período ────────────────────────────────────
                Row(
                  children: [
                    _PeriodChip(
                      label: 'Esta semana',
                      selected: _period == _Period.week,
                      onTap: () =>
                          setState(() => _period = _Period.week),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'Este mês',
                      selected: _period == _Period.month,
                      onTap: () =>
                          setState(() => _period = _Period.month),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Total ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _period == _Period.week
                            ? 'Estimativa — esta semana'
                            : 'Estimativa — este mês',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        moneyFmt.format(_totalEstimate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_filtered.length} serviço(s) concluído(s)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Lista ─────────────────────────────────────────────
                if (_filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Nenhum serviço no período.',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                    ),
                  )
                else ...[
                  const Text('Detalhamento',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._filtered.map((o) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.handyman_outlined,
                                  color: AppColors.primary,
                                  size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.serviceCategory,
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${o.clientName ?? "Cliente"} · ${fmt.format(o.completedAt ?? o.updatedAt)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              o.price != null
                                  ? moneyFmt.format(o.price)
                                  : '—',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}

enum _Period { week, month }

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}
