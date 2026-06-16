// EXCEPTIONS (camada data)
class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});
  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException()
      : super('Verifique seu e-mail antes de continuar.', code: 'email-not-verified');
}

class AccountSuspendedException extends AuthException {
  const AccountSuspendedException()
      : super('Sua conta foi suspensa. Entre em contato com o suporte.', code: 'account-suspended');
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sem conexão com a internet.']) : super(code: 'network-error');
}

class ServerException extends AppException {
  const ServerException([super.message = 'Erro no servidor. Tente novamente.']) : super(code: 'server-error');
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Recurso não encontrado.']) : super(code: 'not-found');
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Você não tem permissão para esta ação.']) : super(code: 'permission-denied');
}

class ValidationException extends AppException {
  const ValidationException(super.message) : super(code: 'validation-error');
}

class StorageException extends AppException {
  const StorageException(super.message) : super(code: 'storage-error');
}

// FAILURES (camada domain)
abstract class Failure {
  final String message;
  const Failure(this.message);
}
class AuthFailure extends Failure { const AuthFailure(super.message); }
class NetworkFailure extends Failure { const NetworkFailure([super.message = 'Sem conexão com a internet.']); }
class ServerFailure extends Failure { const ServerFailure([super.message = 'Erro no servidor. Tente novamente.']); }
class NotFoundFailure extends Failure { const NotFoundFailure([super.message = 'Recurso não encontrado.']); }
class PermissionFailure extends Failure { const PermissionFailure([super.message = 'Você não tem permissão para esta ação.']); }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class StorageFailure extends Failure { const StorageFailure(super.message); }

// MAPPERS
class FirebaseAuthExceptionMapper {
  FirebaseAuthExceptionMapper._();
  static AuthException map(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('E-mail ou senha incorretos.');
      case 'email-already-in-use':
        return const AuthException('Este e-mail já está cadastrado.');
      case 'weak-password':
        return const AuthException('A senha deve ter pelo menos 6 caracteres.');
      case 'invalid-email':
        return const AuthException('E-mail inválido.');
      case 'user-disabled':
        return const AccountSuspendedException();
      case 'too-many-requests':
        return const AuthException('Muitas tentativas. Aguarde alguns minutos.');
      case 'network-request-failed':
        return const AuthException('Sem conexão com a internet.');
      case 'requires-recent-login':
        return const AuthException('Faça login novamente para continuar.');
      case 'account-exists-with-different-credential':
        return const AuthException('Este e-mail já está associado a outro método de login.');
      default:
        return AuthException('Ocorreu um erro ($code). Tente novamente.');
    }
  }
}

class FirestoreExceptionMapper {
  FirestoreExceptionMapper._();
  static Failure map(String code, [String? details]) {
    switch (code) {
      case 'permission-denied': return const PermissionFailure();
      case 'not-found': return const NotFoundFailure();
      case 'unavailable':
      case 'deadline-exceeded': return const NetworkFailure();
      case 'already-exists': return ValidationFailure(details ?? 'Este registro já existe.');
      case 'unauthenticated': return const AuthFailure('Sessão expirada. Faça login novamente.');
      default: return ServerFailure(details ?? 'Erro no servidor ($code).');
    }
  }
}

class StorageExceptionMapper {
  StorageExceptionMapper._();
  static Failure map(String code) {
    switch (code) {
      case 'object-not-found': return const NotFoundFailure('Arquivo não encontrado.');
      case 'unauthorized': return const PermissionFailure('Sem permissão para acessar o arquivo.');
      case 'quota-exceeded': return const StorageFailure('Armazenamento cheio. Tente mais tarde.');
      case 'canceled': return const StorageFailure('Upload cancelado.');
      default: return const StorageFailure('Erro ao fazer upload. Tente novamente.');
    }
  }
}
