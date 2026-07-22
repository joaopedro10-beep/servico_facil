import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status do pagamento de um registro financeiro.
enum PaymentStatus { pending, paid, withdrawn }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:   return 'Pendente';
      case PaymentStatus.paid:      return 'Pago';
      case PaymentStatus.withdrawn: return 'Sacado';
    }
  }
}

/// Registro financeiro gerado automaticamente ao concluir um serviço.
///
/// Alimenta a tela Financeira do prestador, os relatórios administrativos,
/// o dashboard financeiro e os KPIs da plataforma.
/// Coleção: `financial_records`.
class FinancialRecordModel extends Equatable {
  final String id;
  final String orderId;
  final String clientId;
  final String clientName;
  final String workerId;
  final String workerName;
  final String category;
  final int durationMinutes;
  final double hourlyRate;
  final double grossAmount;        // valor bruto
  final double platformFeePercent; // % da comissão
  final double platformFeeAmount;  // comissão em R$
  final double netAmount;          // líquido do prestador
  final DateTime completedAt;
  final PaymentStatus paymentStatus;

  const FinancialRecordModel({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    required this.workerId,
    required this.workerName,
    required this.category,
    required this.durationMinutes,
    required this.hourlyRate,
    required this.grossAmount,
    required this.platformFeePercent,
    required this.platformFeeAmount,
    required this.netAmount,
    required this.completedAt,
    this.paymentStatus = PaymentStatus.pending,
  });

  factory FinancialRecordModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return FinancialRecordModel(
      id: docId,
      orderId: map['orderId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      category: map['category'] ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0,
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0,
      platformFeePercent:
          (map['platformFeePercent'] as num?)?.toDouble() ?? 0,
      platformFeeAmount:
          (map['platformFeeAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0,
      completedAt:
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['paymentStatus'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'clientId': clientId,
        'clientName': clientName,
        'workerId': workerId,
        'workerName': workerName,
        'category': category,
        'durationMinutes': durationMinutes,
        'hourlyRate': hourlyRate,
        'grossAmount': grossAmount,
        'platformFeePercent': platformFeePercent,
        'platformFeeAmount': platformFeeAmount,
        'netAmount': netAmount,
        'completedAt': Timestamp.fromDate(completedAt),
        'paymentStatus': paymentStatus.name,
      };

  /// Duração formatada, ex.: "2h 30min".
  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  List<Object?> get props => [id, orderId, workerId, grossAmount];
}
