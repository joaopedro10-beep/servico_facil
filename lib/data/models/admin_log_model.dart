import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Tipos de ação que um administrador pode realizar.
/// Cada ação fica registrada no histórico para auditoria.
enum AdminActionType {
  approveWorker,
  rejectWorker,
  requestDocuments,
  suspendUser,
  unsuspendUser,
  banUser,
  warnUser,
  resolveReport,
  dismissReport,
  removeReview,
  approveCategory,
  createCategory,
  editCategory,
  deactivateCategory,
  sendNotification,
}

extension AdminActionTypeX on AdminActionType {
  String get label {
    switch (this) {
      case AdminActionType.approveWorker:       return 'Aprovação de prestador';
      case AdminActionType.rejectWorker:        return 'Rejeição de prestador';
      case AdminActionType.requestDocuments:    return 'Solicitação de documentos';
      case AdminActionType.suspendUser:         return 'Suspensão de usuário';
      case AdminActionType.unsuspendUser:       return 'Remoção de suspensão';
      case AdminActionType.banUser:             return 'Banimento de usuário';
      case AdminActionType.warnUser:            return 'Advertência de usuário';
      case AdminActionType.resolveReport:       return 'Denúncia resolvida';
      case AdminActionType.dismissReport:       return 'Denúncia descartada';
      case AdminActionType.removeReview:        return 'Avaliação removida';
      case AdminActionType.approveCategory:     return 'Categoria aprovada';
      case AdminActionType.createCategory:      return 'Categoria criada';
      case AdminActionType.editCategory:        return 'Categoria editada';
      case AdminActionType.deactivateCategory:  return 'Categoria desativada';
      case AdminActionType.sendNotification:    return 'Notificação enviada';
    }
  }
}

/// Registro de ação administrativa para auditoria.
class AdminLogModel extends Equatable {
  final String id;
  final String adminId;
  final String adminName;
  final AdminActionType action;
  final String targetId;    // uid do usuário/worker afetado
  final String targetName;  // nome para exibição
  final String? reason;     // motivo da ação (opcional)
  final DateTime createdAt;

  const AdminLogModel({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetId,
    required this.targetName,
    this.reason,
    required this.createdAt,
  });

  factory AdminLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return AdminLogModel(
      id: docId,
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      action: AdminActionType.values.firstWhere(
        (e) => e.name == (map['action'] ?? ''),
        orElse: () => AdminActionType.warnUser,
      ),
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      reason: map['reason'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'adminId': adminId,
        'adminName': adminName,
        'action': action.name,
        'targetId': targetId,
        'targetName': targetName,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [id, adminId, action, targetId, createdAt];
}
