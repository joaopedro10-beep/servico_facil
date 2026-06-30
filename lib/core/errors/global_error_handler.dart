import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_routes.dart';
import 'app_exceptions.dart';

/// Trata qualquer exceção e exibe SnackBar amigável.
/// Use em todos os catch blocks: GlobalErrorHandler.handle(e)
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static void handle(Object error, {String? context}) {
    debugPrint('[ErrorHandler] $error');

    String message;

    if (error is SocketException ||
        error is HttpException ||
        error is HandshakeException) {
      message =
          'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    } else if (error is TimeoutException) {
      message =
          'A operação demorou demais. Verifique sua conexão e tente novamente.';
    } else if (error is FirebaseAuthException) {
      message = _firebaseAuthMessage(error.code);
    } else if (error is EmailNotVerifiedException) {
      message = 'Confirme seu e-mail antes de entrar.';
      Get.toNamed(AppRoutes.verifyEmail);
      return;
    } else if (error is ValidationException) {
      message = error.message;
    } else if (error is ServerException) {
      message = error.message;
    } else if (error is AuthException) {
      message = error.message;
    } else {
      message = 'Algo deu errado. Tente novamente.';
    }

    if (context != null) {
      message = '$context: $message';
    }

    Get.snackbar(
      'Ops!',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-mail não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento.';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente para esta ação.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return 'Erro de autenticação ($code).';
    }
  }
}
