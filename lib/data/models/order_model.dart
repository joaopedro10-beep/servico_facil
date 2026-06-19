import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum OrderStatus { pending, accepted, inProgress, done, cancelled }

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String workerId;
  final String serviceCategory;
  final String description;
  final List<String> photoUrls;
  final DateTime scheduledAt;
  final OrderStatus status;
  final UserAddress address;
  final double? price;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Timestamps de cada etapa para a timeline
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Nomes para exibição rápida (evita joins extras)
  final String? clientName;
  final String? workerName;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.workerId,
    required this.serviceCategory,
    required this.description,
    this.photoUrls = const [],
    required this.scheduledAt,
    this.status = OrderStatus.pending,
    required this.address,
    this.price,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.clientName,
    this.workerName,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      scheduledAt:
          (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      address: UserAddress.fromMap(map['address'] ?? {}),
      price: (map['price'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      clientName: map['clientName'],
      workerName: map['workerName'],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'workerId': workerId,
        'serviceCategory': serviceCategory,
        'description': description,
        'photoUrls': photoUrls,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'status': status.name,
        'address': address.toMap(),
        'price': price,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (acceptedAt != null)
          'acceptedAt': Timestamp.fromDate(acceptedAt!),
        if (startedAt != null)
          'startedAt': Timestamp.fromDate(startedAt!),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (cancelledAt != null)
          'cancelledAt': Timestamp.fromDate(cancelledAt!),
        if (clientName != null) 'clientName': clientName,
        if (workerName != null) 'workerName': workerName,
      };

  OrderModel copyWith({
    OrderStatus? status,
    double? price,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    List<String>? photoUrls,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      workerId: workerId,
      serviceCategory: serviceCategory,
      description: description,
      photoUrls: photoUrls ?? this.photoUrls,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      address: address,
      price: price ?? this.price,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      clientName: clientName,
      workerName: workerName,
    );
  }

  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.accepted ||
      status == OrderStatus.inProgress;

  bool get canClientCancel => status == OrderStatus.pending;
  bool get canWorkerAccept => status == OrderStatus.pending;
  bool get canWorkerStart => status == OrderStatus.accepted;
  bool get canWorkerComplete => status == OrderStatus.inProgress;

  @override
  List<Object?> get props => [id, userId, workerId, status, createdAt];
}
