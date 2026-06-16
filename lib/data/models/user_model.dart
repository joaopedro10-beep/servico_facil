import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserAddress address;
  final DateTime createdAt;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.address,
    required this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      address: UserAddress.fromMap(map['address'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'address': address.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
    'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    UserAddress? address,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, photoUrl, address, createdAt, fcmToken];
}

class UserAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final double lat;
  final double lng;

  const UserAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'street': street,
    'city': city,
    'state': state,
    'lat': lat,
    'lng': lng,
  };

  @override
  List<Object?> get props => [street, city, state, lat, lng];
}
