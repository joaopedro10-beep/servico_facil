import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/admin_log_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/report_model.dart';
import '../../../../data/models/review_model.dart';
import '../../admin_theme.dart';
import '../../controllers/admin_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════════════════════════════════════════

class AdminOrdersSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminOrdersSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.allOrders;
      if (orders.isEmpty) {
        return const _EmptySection(
            icon: Icons.receipt_long_outlined,
            message: 'Nenhum serviço registrado');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      );
    });
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color get _color {
    switch (order.status) {
      case OrderStatus.pending:    return AdminTheme.amber;
      case OrderStatus.accepted:   return AdminTheme.primary;
      case OrderStatus.arrived:    return AdminTheme.primary;
      case OrderStatus.inProgress: return AdminTheme.purple;
      case OrderStatus.done:       return AdminTheme.green;
      case OrderStatus.cancelled:  return AdminTheme.red;
    }
  }

  String get _statusLabel =>
      AppFormatters.orderStatusLabel(order.status.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 4, height: 52,
              decoration: BoxDecoration(
                  color: _color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.serviceCategory,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('Cliente: ${order.clientName ?? order.userId}',
                  style: const TextStyle(fontSize: 12, color: AdminTheme.textGray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Prestador: ${order.workerName ?? order.workerId}',
                  style: const TextStyle(fontSize: 12, color: AdminTheme.textGray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(AppFormatters.dateTime(order.createdAt),
                  style: const TextStyle(fontSize: 11, color: AdminTheme.textLight)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _color.withOpacity(0.3)),
            ),
            child: Text(_statusLabel,
                style: TextStyle(fontSize: 11, color: _color,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEWS
// ═══════════════════════════════════════════════════════════════════════════════

class AdminReviewsSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminReviewsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reviews = ctrl.allReviews;
      if (reviews.isEmpty) {
        return const _EmptySection(
            icon: Icons.star_outline, message: 'Nenhuma avaliação');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ReviewCard(review: reviews[i], ctrl: ctrl),
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final AdminController ctrl;
  const _ReviewCard({required this.review, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(review.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Row(children: List.generate(5, (i) => Icon(
              i < review.rating.round()
                  ? Icons.star_rounded : Icons.star_border_rounded,
              size: 16, color: AdminTheme.amberLight,
            ))),
          ]),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!,
                style: const TextStyle(fontSize: 13, color: AdminTheme.textGray),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Text(AppFormatters.dateTime(review.createdAt),
                  style: const TextStyle(fontSize: 11, color: AdminTheme.textLight)),
            ),
            GestureDetector(
              onTap: () => ctrl.removeReview(review),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.red.withOpacity(0.3)),
                ),
                child: const Text('Remover',
                    style: TextStyle(fontSize: 12, color: AdminTheme.red,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTS
// ═══════════════════════════════════════════════════════════════════════════════

class AdminReportsSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminReportsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tabs abertas / todas
      Obx(() => Container(
        color: Colors.white,
        child: Row(children: [
          _ReportTab(
            label: 'Abertas',
            count: ctrl.openReports.length,
            selected: ctrl.reportTab.value == 0,
            onTap: () => ctrl.reportTab.value = 0,
          ),
          _ReportTab(
            label: 'Todas',
            count: ctrl.allReports.length,
            selected: ctrl.reportTab.value == 1,
            onTap: () => ctrl.reportTab.value = 1,
          ),
        ]),
      )),
      const Divider(height: 1),
      Expanded(
        child: Obx(() {
          final reports = ctrl.displayedReports;
          if (reports.isEmpty) {
            return const _EmptySection(
                icon: Icons.flag_outlined, message: 'Nenhuma denúncia');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ReportCard(report: reports[i], ctrl: ctrl),
          );
        }),
      ),
    ]);
  }
}

class _ReportTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _ReportTab({
    required this.label, required this.count,
    required this.selected, required this.onTap,
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
                color: selected
                    ? AdminTheme.primary.withOpacity(0.1)
                    : AdminTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: selected ? AdminTheme.primary : AdminTheme.textGray)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final AdminController ctrl;
  const _ReportCard({required this.report, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isOpen = report.status == ReportStatus.open;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AdminTheme.red.withOpacity(0.3)
              : AdminTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminTheme.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded,
                  color: AdminTheme.red, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(report.reason,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOpen
                    ? AdminTheme.red.withOpacity(0.1)
                    : AdminTheme.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOpen ? 'Aberta' : 'Resolvida',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: isOpen ? AdminTheme.red : AdminTheme.green),
              ),
            ),
          ]),
          if (report.description != null) ...[
            const SizedBox(height: 8),
            Text(report.description!,
                style: const TextStyle(fontSize: 13, color: AdminTheme.textGray),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Text(AppFormatters.dateTime(report.createdAt),
              style: const TextStyle(fontSize: 11, color: AdminTheme.textLight)),
          if (isOpen) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _RptBtn(
                label: 'Descartar',
                color: AdminTheme.textGray,
                onTap: () => ctrl.dismissReport(report),
              ),
              const SizedBox(width: 8),
              _RptBtn(
                label: 'Resolver',
                color: AdminTheme.green,
                filled: true,
                onTap: () => ctrl.resolveReport(report),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _RptBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _RptBtn({
    required this.label, required this.color,
    required this.onTap, this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: filled ? Colors.white : color)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGS
// ═══════════════════════════════════════════════════════════════════════════════

class AdminLogsSection extends StatelessWidget {
  final AdminController ctrl;
  const AdminLogsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = ctrl.adminLogs;
      if (logs.isEmpty) {
        return const _EmptySection(
            icon: Icons.history_outlined,
            message: 'Nenhuma ação registrada');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final log = logs[i];
          final showDate = i == 0 ||
              AppFormatters.date(log.createdAt) !=
                  AppFormatters.date(logs[i - 1].createdAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDate)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    AppFormatters.relativeDate(log.createdAt),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AdminTheme.textGray),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AdminTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        size: 18, color: AdminTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.action.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${log.adminName} → ${log.targetName}',
                            style: const TextStyle(
                                fontSize: 11, color: AdminTheme.textGray),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (log.reason != null)
                          Text('Motivo: ${log.reason}',
                              style: const TextStyle(
                                  fontSize: 11, color: AdminTheme.textLight),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(AppFormatters.time(log.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AdminTheme.textLight)),
                ]),
              ),
            ],
          );
        },
      );
    });
  }
}

// ─── Widget compartilhado ─────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

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
