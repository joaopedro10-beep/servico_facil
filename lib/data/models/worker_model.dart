import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user_address.dart';

enum VerificationStatus { pending, approved, rejected, documentsRequired }

class WorkerModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> categories;
  final List<String> activeCategories; // serviços habilitados para receber chamadas
  final String description;
  final UserAddress address;
  final double pricePerHour;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final VerificationStatus verificationStatus;
  final bool isAvailable;
  final bool isSuspended;
  final String? documentUrl;
  final List<String> portfolioUrls;
  final DateTime createdAt;
  final String? fcmToken;

  /// Sempre 'password'. Trabalhador nunca se cadastra via Google — as
  /// Firestore Rules rejeitam qualquer tentativa de criar um worker com
  /// authProvider diferente disso.
  final String authProvider;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.categories,
    this.activeCategories = const [],
    required this.description,
    required this.address,
    required this.pricePerHour,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.verificationStatus = VerificationStatus.pending,
    this.isAvailable = true,
    this.isSuspended = false,
    this.documentUrl,
    this.portfolioUrls = const [],
    required this.createdAt,
    this.fcmToken,
    this.authProvider = 'password',
  });

  String get city => address.city;
  String get neighborhood => address.neighborhood;
  String get cep => address.cep;
  String get street => address.street;
  String get number => address.number;
  String get complement => address.complement;
  String get state => address.state;
  String get lat => address.lat.toString();
  String get lng => address.lng.toString();

  factory WorkerModel.fromMap(Map<String, dynamic> map, String docId) {
    return WorkerModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      categories: List<String>.from(map['categories'] ?? []),
      activeCategories: List<String>.from(map['activeCategories'] ?? map['categories'] ?? []),
      description: map['description'] ?? '',
      address: UserAddress.fromMap(
        map['address'] ?? {},
      ),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
            (e) => e.name == (map['verificationStatus'] ?? 'pending'),
        orElse: () => VerificationStatus.pending,
      ),
      isAvailable: map['isAvailable'] ?? true,
      isSuspended: map['isSuspended'] ?? false,
      documentUrl: map['documentUrl'],
      portfolioUrls: List<String>.from(map['portfolioUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'],
      authProvider: map['authProvider'] ?? 'password',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'categories': categories,
    'description': description,
    'pricePerHour': pricePerHour,
    'rating': rating,
    'totalReviews': totalReviews,
    'isVerified': isVerified,
    'verificationStatus': verificationStatus.name,
    'isAvailable': isAvailable,
    'isSuspended': isSuspended,
    'documentUrl': documentUrl,
    'portfolioUrls': portfolioUrls,
    'createdAt': Timestamp.fromDate(createdAt),
    'fcmToken': fcmToken,
    'address': address.toMap(),
    'authProvider': authProvider,
  };

  WorkerModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    List<String>? categories,
    List<String>? activeCategories,
    String? description,
    UserAddress? address,
    double? pricePerHour,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    VerificationStatus? verificationStatus,
    bool? isAvailable,
    bool? isSuspended,
    String? documentUrl,
    List<String>? portfolioUrls,
    String? fcmToken,
  }) {
    return WorkerModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      categories: categories ?? this.categories,
      activeCategories: activeCategories ?? this.activeCategories,
      description: description ?? this.description,
      address: address ?? this.address,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isAvailable: isAvailable ?? this.isAvailable,
      isSuspended: isSuspended ?? this.isSuspended,
      documentUrl: documentUrl ?? this.documentUrl,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      authProvider: authProvider,
    );
  }

  /// Média real da avaliação (rating no Firestore é soma; dividir por totalReviews)
  double get avgRating => totalReviews > 0 ? rating / totalReviews : 0.0;

  @override
  List<Object?> get props =>
      [id, name, email, isVerified, isAvailable, rating, verificationStatus, address,];
}
