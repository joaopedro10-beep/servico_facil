import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/worker_model.dart';

class AuthRepositoryImpl {
  final AuthDatasource _authDs = Get.find<AuthDatasource>();
  final FirestoreDatasource _firestoreDs = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyUserType = 'user_type'; // 'client' | 'worker'
  static const _keyUserId = 'user_id';

  // ─── Registro cliente ─────────────────────────────────────────────────────
  Future<void> registerClient({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    final cred = await _authDs.registerWithEmail(email: email, password: password);
    final uid = cred.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      address: UserAddress(street: '', city: city, state: '', lat: 0, lng: 0),
      createdAt: DateTime.now(),
    );
    await _firestoreDs.createUser(user);

    // FCM token
    await _fb.updateFcmToken(uid, isWorker: false);

    // Persiste tipo localmente
    await _storage.write(key: _keyUserType, value: 'client');
    await _storage.write(key: _keyUserId, value: uid);
  }

  // ─── Registro trabalhador ─────────────────────────────────────────────────
  Future<void> registerWorker({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> categories,
    required String description,
    required double pricePerHour,
    required String city,
    required String neighborhood,
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
      city: city,
      neighborhood: neighborhood,
      pricePerHour: pricePerHour,
      // documentUrl fica vazio — sem Storage; o admin verificará presencialmente
      documentUrl: null,
      verificationStatus: VerificationStatus.pending,
      isVerified: false,
      createdAt: DateTime.now(),
    );
    await _firestoreDs.createWorker(worker);
    await _fb.updateFcmToken(uid, isWorker: true);

    await _storage.write(key: _keyUserType, value: 'worker');
    await _storage.write(key: _keyUserId, value: uid);
  }

  // ─── Login ────────────────────────────────────────────────────────────────
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

  Future<String> loginWithGoogle() async {
    final cred = await _authDs.loginWithGoogle();
    final uid = cred.user!.uid;

    // Verifica se já existe no Firestore; se não, cria como cliente
    final existingUser = await _firestoreDs.getUser(uid);
    if (existingUser == null) {
      final user = UserModel(
        id: uid,
        name: cred.user!.displayName ?? 'Usuário',
        email: cred.user!.email ?? '',
        phone: '',
        address: const UserAddress(street: '', city: '', state: '', lat: 0, lng: 0),
        createdAt: DateTime.now(),
      );
      await _firestoreDs.createUser(user);
    }

    final type = await _resolveAndCacheUserType(uid);
    await _fb.updateFcmToken(uid, isWorker: type == 'worker');
    return type;
  }

  // ─── Utilitários ──────────────────────────────────────────────────────────
  Future<String> _resolveAndCacheUserType(String uid) async {
    // Tenta ler do cache local primeiro
    final cached = await _storage.read(key: _keyUserType);
    if (cached != null) return cached;

    // Consulta Firestore para determinar o tipo
    final worker = await _firestoreDs.getWorker(uid);
    final type = worker != null ? 'worker' : 'client';
    await _storage.write(key: _keyUserType, value: type);
    await _storage.write(key: _keyUserId, value: uid);
    return type;
  }

  Future<String?> getCachedUserType() => _storage.read(key: _keyUserType);

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
