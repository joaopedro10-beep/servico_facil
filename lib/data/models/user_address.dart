import 'package:equatable/equatable.dart';

class UserAddress extends Equatable {
  final String cep;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String complement;
  final double lat;
  final double lng;

  const UserAddress({
    required this.cep,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.complement = '',
    this.lat = 0.0,
    this.lng = 0.0,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      cep: map['cep'] ?? '',
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      complement: map['complement'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'complement': complement,
      'lat': lat,
      'lng': lng,
    };
  }

  UserAddress copyWith({
    String? cep,
    String? street,
    String? number,
    String? neighborhood,
    String? city,
    String? state,
    String? complement,
    double? lat,
    double? lng,
  }) {
    return UserAddress(
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      complement: complement ?? this.complement,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  String get fullAddress {
    return '$street, $number - $neighborhood, $city/$state';
  }

  @override
  List<Object?> get props => [
    cep,
    street,
    number,
    neighborhood,
    city,
    state,
    complement,
    lat,
    lng,
  ];
}