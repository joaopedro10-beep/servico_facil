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
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      userId: map['userId'] ?? '',
      workerId: map['workerId'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
            (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      address: UserAddress.fromMap(map['address'] ?? {}),
      price: (map['price'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
  };

  OrderModel copyWith({OrderStatus? status, double? price, DateTime? updatedAt}) {
    return OrderModel(
      id: id,
      userId: userId,
      workerId: workerId,
      serviceCategory: serviceCategory,
      description: description,
      photoUrls: photoUrls,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      address: address,
      price: price ?? this.price,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isActive => status == OrderStatus.pending ||
      status == OrderStatus.accepted ||
      status == OrderStatus.inProgress;

  @override
  List<Object?> get props => [id, userId, workerId, status, createdAt];
}
