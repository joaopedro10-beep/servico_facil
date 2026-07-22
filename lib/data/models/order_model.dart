import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user_address.dart';

enum OrderStatus { pending, accepted, arrived, inProgress, done, cancelled }

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String? workerId; // null até um prestador aceitar
  final String serviceCategory;
  final String description;
  final List<String> photoUrls;
  final DateTime? scheduledAt; // definido pelo prestador ao aceitar/agendar
  final OrderStatus status;
  final UserAddress address;
  final double? price;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Timestamps de cada etapa para a timeline
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;   // prestador chegou ao local
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // ── Financeiro (cobrança por hora) ─────────────────────────────────────────
  // Snapshot congelado no início do serviço — se o admin alterar as taxas
  // depois, este pedido continua com os valores acordados.
  final double? hourlyRate;         // R$/hora da categoria
  final double? platformFeePercent; // % de comissão da plataforma
  final double? grossAmount;        // valor bruto final
  final double? platformFeeAmount;  // comissão em R$
  final double? netAmount;          // líquido do prestador
  final int?    durationMinutes;    // duração total trabalhada

  // Nomes para exibição rápida (evita joins extras)
  final String? clientName;
  final String? workerName;

  const OrderModel({
    required this.id,
    required this.userId,
    this.workerId,
    required this.serviceCategory,
    required this.description,
    this.photoUrls = const [],
    this.scheduledAt, // null quando cliente cria o pedido
    this.status = OrderStatus.pending,
    required this.address,
    this.price,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.hourlyRate,
    this.platformFeePercent,
    this.grossAmount,
    this.platformFeeAmount,
    this.netAmount,
    this.durationMinutes,
    this.clientName,
    this.workerName,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      userId: map['userId'] ?? '',
      workerId: map['workerId'] as String?,
      serviceCategory: map['serviceCategory'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      address: UserAddress.fromMap(map['address'] ?? {}),
      price: (map['price'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      arrivedAt: (map['arrivedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: ((map['finishedAt'] ?? map['completedAt']) as Timestamp?)
          ?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      platformFeePercent:
          (map['platformFeePercent'] as num?)?.toDouble(),
      grossAmount: (map['grossAmount'] as num?)?.toDouble(),
      platformFeeAmount:
          (map['platformFeeAmount'] as num?)?.toDouble(),
      netAmount: (map['netAmount'] as num?)?.toDouble(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      clientName: map['clientName'],
      workerName: map['workerName'],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'workerId': workerId ?? '',
        'serviceCategory': serviceCategory,
        'description': description,
        'photoUrls': photoUrls,
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
        'status': status.name,
        'address': address.toMap(),
        'price': price,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (acceptedAt != null)
          'acceptedAt': Timestamp.fromDate(acceptedAt!),
        if (arrivedAt != null)
          'arrivedAt': Timestamp.fromDate(arrivedAt!),
        if (startedAt != null)
          'startedAt': Timestamp.fromDate(startedAt!),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (cancelledAt != null)
          'cancelledAt': Timestamp.fromDate(cancelledAt!),
        if (hourlyRate != null) 'hourlyRate': hourlyRate,
        if (platformFeePercent != null)
          'platformFeePercent': platformFeePercent,
        if (grossAmount != null) 'grossAmount': grossAmount,
        if (platformFeeAmount != null)
          'platformFeeAmount': platformFeeAmount,
        if (netAmount != null) 'netAmount': netAmount,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (clientName != null) 'clientName': clientName,
        if (workerName != null) 'workerName': workerName,
      };

  OrderModel copyWith({
    String? workerId,
    String? workerName,
    DateTime? scheduledAt,
    OrderStatus? status,
    double? price,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    List<String>? photoUrls,
    double? hourlyRate,
    double? platformFeePercent,
    double? grossAmount,
    double? platformFeeAmount,
    double? netAmount,
    int? durationMinutes,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      workerId: workerId ?? this.workerId,
      serviceCategory: serviceCategory,
      description: description,
      photoUrls: photoUrls ?? this.photoUrls,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      address: address,
      price: price ?? this.price,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      platformFeePercent: platformFeePercent ?? this.platformFeePercent,
      grossAmount: grossAmount ?? this.grossAmount,
      platformFeeAmount: platformFeeAmount ?? this.platformFeeAmount,
      netAmount: netAmount ?? this.netAmount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      clientName: clientName,
      workerName: workerName,
    );
  }

  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.accepted ||
      status == OrderStatus.arrived ||
      status == OrderStatus.inProgress;

  /// Serviço em atendimento pelo prestador (fluxo estilo 99)
  bool get isOngoing =>
      status == OrderStatus.accepted ||
      status == OrderStatus.arrived ||
      status == OrderStatus.inProgress;

  /// Etapa atual para a barra de progresso do cliente (0 a 4):
  /// 0 aceito · 1 em deslocamento · 2 chegou · 3 em execução · 4 finalizado
  int get progressStep {
    switch (status) {
      case OrderStatus.pending:    return -1;
      case OrderStatus.accepted:   return 1; // aceito + em deslocamento
      case OrderStatus.arrived:    return 2;
      case OrderStatus.inProgress: return 3;
      case OrderStatus.done:       return 4;
      case OrderStatus.cancelled:  return -1;
    }
  }

  bool get canClientCancel => status == OrderStatus.pending;
  bool get canWorkerAccept => status == OrderStatus.pending;
  bool get canWorkerStart =>
      status == OrderStatus.accepted || status == OrderStatus.arrived;
  bool get canWorkerComplete => status == OrderStatus.inProgress;
  bool get isScheduled => scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [id, userId, workerId, status, createdAt];
}
