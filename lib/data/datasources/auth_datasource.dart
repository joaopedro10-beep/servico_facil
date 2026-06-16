import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/firebase_service.dart';

/// AuthDatasource — responsável por toda operação de autenticação com o Firebase.
/// Lança AppException (ou subclasses) em caso de erro.
class AuthDatasource {
  final FirebaseService _fb = Get.find<FirebaseService>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Cadastro ─────────────────────────────────────────────────────────────

  /// Cria conta com e-mail/senha e envia e-mail de verificação.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _fb.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Envia e-mail de verificação imediatamente após o cadastro
      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    } catch (e) {
      throw const ServerException();
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Login com e-mail e senha.
  /// Verifica se o e-mail está confirmado antes de prosseguir.
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _fb.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Bloqueia login se e-mail não foi verificado
      if (!(credential.user?.emailVerified ?? false)) {
        await _fb.auth.signOut();
        throw const EmailNotVerifiedException();
      }

      return credential;
    } on EmailNotVerifiedException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    } catch (e) {
      throw const ServerException();
    }
  }

  /// Login com conta Google.
  Future<UserCredential> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Login com Google cancelado.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _fb.auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    } catch (e) {
      throw const ServerException('Erro ao fazer login com Google.');
    }
  }

  // ─── E-mail verification ──────────────────────────────────────────────────

  /// Reenvia o e-mail de verificação para o usuário atual.
  Future<void> resendVerificationEmail() async {
    try {
      await _fb.auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    }
  }

  /// Verifica (reload) se o usuário já confirmou o e-mail.
  Future<bool> checkEmailVerified() async {
    await _fb.auth.currentUser?.reload();
    return _fb.auth.currentUser?.emailVerified ?? false;
  }

  // ─── Senha ────────────────────────────────────────────────────────────────

  /// Envia e-mail de redefinição de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _fb.auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    }
  }

  /// Atualiza a senha do usuário autenticado.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _fb.auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    }
  }

  // ─── Sessão ───────────────────────────────────────────────────────────────

  /// Faz logout (Firebase Auth + Google Sign-In).
  Future<void> signOut() async {
    await Future.wait([
      _fb.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Deleta a conta do usuário autenticado.
  /// Requer login recente (pode lançar 'requires-recent-login').
  Future<void> deleteAccount() async {
    try {
      await _fb.auth.currentUser?.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e.code);
    }
  }

  /// Retorna o usuário autenticado atual (ou null).
  User? get currentUser => _fb.auth.currentUser;

  /// Stream de estado de autenticação.
  Stream<User?> get authStateChanges => _fb.authStateChanges;

}
