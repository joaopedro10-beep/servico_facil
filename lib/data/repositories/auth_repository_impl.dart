import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/worker_model.dart';
import '../models/user_address.dart';

class AuthRepositoryImpl {
  final AuthDatasource _authDs = Get.find<AuthDatasource>();
  final FirestoreDatasource _firestoreDs = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyUserType = 'user_type'; // 'client' | 'worker'
  static const _keyUserId = 'user_id';

  // ─── Registro cliente (e-mail/senha) ───────────────────────────────────────
  Future<void> registerClient({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String cep,
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String state,
    required double lat,
    required double lng,
  }) async {
    final cred = await _authDs.registerWithEmail(email: email, password: password);
    final uid = cred.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      address: UserAddress(
        cep: cep,
        street: street,
        number: number,
        neighborhood: neighborhood,
        city: city,
        state: state,
        lat: lat,
        lng: lng,
      ),
      createdAt: DateTime.now(),
      // Cadastro tradicional: perfil já nasce completo, sem exigir CPF
      // extra (a confiança aqui vem do e-mail verificado pelo Firebase Auth).
      authProvider: UserAuthProvider.password,
      isProfileComplete: true,
    );
    await _firestoreDs.createUser(user);

    await _fb.updateFcmToken(uid, isWorker: false);

    await _storage.write(key: _keyUserType, value: 'client');
    await _storage.write(key: _keyUserId, value: uid);
  }

  // ─── Registro trabalhador (SEMPRE e-mail/senha) ────────────────────────────
  Future<void> registerWorker({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> categories,
    required String description,
    required double pricePerHour,
    required String cep,
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String state,
    required double lat,
    required double lng,
    // documentLocalPath: caminho local da foto (sem Storage)
    required String documentLocalPath,
  }) async {
    final cred = await _authDs.registerWithEmail(email: email, password: password);
    final uid = cred.user!.uid;

    final worker = WorkerModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      categories: categories,
      description: description,
      address: UserAddress(
        cep: cep,
        street: street,
        number: number,
        neighborhood: neighborhood,
        city: city,
        state: state,
        lat: lat,
        lng: lng,
      ),
      pricePerHour: pricePerHour,
      // documentUrl fica vazio — sem Storage; o admin verificará presencialmente
      documentUrl: null,
      verificationStatus: VerificationStatus.pending,
      isVerified: false,
      createdAt: DateTime.now(),
      // Trabalhador é sempre 'password' — nunca existe registerWorkerWithGoogle().
      authProvider: 'password',
    );
    await _firestoreDs.createWorker(worker);
    await _fb.updateFcmToken(uid, isWorker: true);

    await _storage.write(key: _keyUserType, value: 'worker');
    await _storage.write(key: _keyUserId, value: uid);
  }

  // ─── Login e-mail/senha (cliente OU trabalhador) ───────────────────────────
  Future<String> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _authDs.loginWithEmail(email: email, password: password);
    final uid = cred.user!.uid;
    final type = await _resolveAndCacheUserType(uid);
    await _fb.updateFcmToken(uid, isWorker: type == 'worker');
    return type;
  }

  // ─── Login Google — EXCLUSIVO para clientes ────────────────────────────────
  // Esta função NUNCA deve ser chamada pela tela de login do trabalhador.
  // A própria UI (LoginScreen é única, usada tanto por cliente quanto
  // prestador) não sabe, antes da autenticação, qual tipo de conta está
  // entrando — por isso a restrição é aplicada em duas camadas DEPOIS do
  // clique: 1) aqui, verificando se já existe um worker com esse uid e
  // bloqueando com mensagem clara; 2) nas Firestore Rules, que nunca aceitam
  // um documento em /workers com authProvider != 'password'.
  Future<String> loginWithGoogle() async {
    final cred = await _authDs.loginWithGoogle();
    final uid = cred.user!.uid;

    // Se já existe um worker com esse uid, login Google é negado —
    // não deveria acontecer (trabalhador nunca usa Google), mas é uma
    // segunda camada de proteção caso a UI falhe em algum fluxo.
    final existingWorker = await _firestoreDs.getWorker(uid);
    if (existingWorker != null) {
      await _authDs.signOut();
      throw const AuthException(
          'Contas de prestador não podem usar login com Google. Entre com e-mail e senha.');
    }

    final existingUser = await _firestoreDs.getUser(uid);
    if (existingUser == null) {
      final user = UserModel(
        id: uid,
        name: cred.user!.displayName ?? 'Usuário',
        email: cred.user!.email ?? '',
        phone: '',
        address: const UserAddress(
            street: '', city: '', state: '', lat: 0, lng: 0, cep: '', number: '', neighborhood: ''),
        createdAt: DateTime.now(),
        // Login social: marca a origem e força perfil incompleto até
        // o usuário preencher CPF + endereço na tela de complemento.
        authProvider: UserAuthProvider.google,
        isProfileComplete: false,
      );
      await _firestoreDs.createUser(user);
    }

    final type = await _resolveAndCacheUserType(uid);
    await _fb.updateFcmToken(uid, isWorker: type == 'worker');
    return type;
  }

  // ─── Completar cadastro (clientes vindos do Google) ────────────────────────
  /// Preenche CPF + endereço completo e libera o cliente para solicitar
  /// serviços. Sem isso, a Firestore Rule de 'orders' bloqueia a criação
  /// de pedidos (campo isProfileComplete checado direto no banco).
  Future<void> completeGoogleProfile({
    required String cpf,
    required String phone,
    required String cep,
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String state,
    required double lat,
    required double lng,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) throw const AuthException('Sessão expirada. Faça login novamente.');

    await _firestoreDs.updateUser(uid, {
      'cpf': cpf,
      'phone': phone,
      'address': UserAddress(
        cep: cep,
        street: street,
        number: number,
        neighborhood: neighborhood,
        city: city,
        state: state,
        lat: lat,
        lng: lng,
      ).toMap(),
      'isProfileComplete': true,
    });
  }

  // ─── Utilitários ──────────────────────────────────────────────────────────
  Future<String> _resolveAndCacheUserType(String uid) async {
    final cached = await _storage.read(key: _keyUserType);
    if (cached != null) return cached;

    final worker = await _firestoreDs.getWorker(uid);
    final type = worker != null ? 'worker' : 'client';
    await _storage.write(key: _keyUserType, value: type);
    await _storage.write(key: _keyUserId, value: uid);
    return type;
  }

  Future<String?> getCachedUserType() => _storage.read(key: _keyUserType);

  /// Indica se o cliente logado ainda precisa completar o cadastro
  /// (CPF + endereço). Usado pelo controller para redirecionar à tela
  /// de complemento de perfil antes de liberar a Home.
  Future<bool> currentUserNeedsProfileCompletion() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;
    final user = await _firestoreDs.getUser(uid);
    return user?.needsProfileCompletion ?? false;
  }

  Future<void> signOut() async {
    await _authDs.signOut();
    await _storage.deleteAll();
  }

  Future<void> sendPasswordReset(String email) =>
      _authDs.sendPasswordResetEmail(email);

  Future<void> resendVerificationEmail() =>
      _authDs.resendVerificationEmail();

  Future<bool> checkEmailVerified() => _authDs.checkEmailVerified();

  User? get currentUser => _authDs.currentUser;
  Stream<User?> get authStateChanges => _authDs.authStateChanges;
}
