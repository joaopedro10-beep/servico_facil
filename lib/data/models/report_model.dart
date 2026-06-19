import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReportStatus { open, reviewed, resolved }

class ReportModel extends Equatable {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final String? description;
  final String? orderId;
  final ReportStatus status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    this.description,
    this.orderId,
    this.status = ReportStatus.open,
    required this.createdAt,
  });

  static const List<String> reasons = [
    'Comportamento inadequado',
    'Não compareceu',
    'Cobrou fora do app',
    'Conteúdo falso no perfil',
    'Assédio',
    'Outro',
  ];

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      reporterId: map['reporterId'] ?? '',
      reportedId: map['reportedId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'],
      orderId: map['orderId'],
      status: ReportStatus.values.firstWhere(
            (e) => e.name == (map['status'] ?? 'open'),
        orElse: () => ReportStatus.open,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'reportedId': reportedId,
    'reason': reason,
    'description': description,
    'orderId': orderId,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props => [id, reporterId, reportedId, reason, createdAt];

}
