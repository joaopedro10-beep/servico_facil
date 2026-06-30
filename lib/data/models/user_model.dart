import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'user_address.dart';

/// Origem da conta — controla regras de segurança no Firestore.
/// 'password' = cadastro tradicional (e-mail/senha)
/// 'google.com' = login social (só disponível para clientes)
enum UserAuthProvider {
  password,
  google;

  /// Converte a string salva no Firestore de volta para o enum.
  static UserAuthProvider fromString(String? raw) {
    return raw == 'google.com' ? UserAuthProvider.google : UserAuthProvider.password;
  }

  /// Valor salvo no Firestore ('password' ou 'google.com').
  String get firestoreValue =>
      this == UserAuthProvider.google ? 'google.com' : 'password';
}

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserAddress address;
  final DateTime createdAt;
  final String? fcmToken;

  /// Como a conta foi criada. Define se exige verificação extra de CPF.
  final UserAuthProvider authProvider;

  /// CPF do cliente — obrigatório apenas quando authProvider == google,
  /// pois nesse fluxo não há verificação de documento como acontece
  /// no cadastro tradicional. Opcional/nulo em contas 'password'.
  final String? cpf;

  /// true quando o cadastro está com todos os dados obrigatórios.
  /// - authProvider == password: sempre true desde a criação.
  /// - authProvider == google: nasce false; só vira true depois que o
  ///   usuário preenche CPF + endereço completo na tela de complemento
  ///   de cadastro. Enquanto false, as Firestore Rules bloqueiam a
  ///   criação de pedidos (orders), mas permitem navegar e ver workers.
  final bool isProfileComplete;

  /// Marcado manualmente pelo admin após conferência do CPF informado
  /// (clientes Google). Não interfere no uso do app, é só um selo de
  /// confiança interno — protegido nas Rules (só admin altera).
  final bool cpfVerifiedByAdmin;

  final bool isSuspended;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.address,
    required this.createdAt,
    this.fcmToken,
    this.authProvider = UserAuthProvider.password,
    this.cpf,
    this.isProfileComplete = true,
    this.cpfVerifiedByAdmin = false,
    this.isSuspended = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      address: UserAddress.fromMap(map['address'] ?? {}),
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'],
      authProvider: UserAuthProvider.fromString(map['authProvider']),
      cpf: map['cpf'],
      isProfileComplete: map['isProfileComplete'] ?? true,
      cpfVerifiedByAdmin: map['cpfVerifiedByAdmin'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
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
    'authProvider': authProvider.firestoreValue,
    'cpf': cpf,
    'isProfileComplete': isProfileComplete,
    'cpfVerifiedByAdmin': cpfVerifiedByAdmin,
    'isSuspended': isSuspended,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    UserAddress? address,
    String? fcmToken,
    String? cpf,
    bool? isProfileComplete,
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
      authProvider: authProvider,
      cpf: cpf ?? this.cpf,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      cpfVerifiedByAdmin: cpfVerifiedByAdmin,
      isSuspended: isSuspended,
    );
  }

  /// true quando esta conta precisa passar pela tela de "Complete seu
  /// cadastro" (CPF + endereço) antes de poder solicitar serviços.
  bool get needsProfileCompletion =>
      authProvider == UserAuthProvider.google && !isProfileComplete;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    photoUrl,
    address,
    createdAt,
    fcmToken,
    authProvider,
    cpf,
    isProfileComplete,
    cpfVerifiedByAdmin,
    isSuspended,
  ];
}
