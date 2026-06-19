import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String orderId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String targetId;
  final double rating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.targetId,
    required this.rating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      orderId: map['orderId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'],
      targetId: map['targetId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'],
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'targetId': targetId,
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props => [id, orderId, authorId, targetId, rating];

}
