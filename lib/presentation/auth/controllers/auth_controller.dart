import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/cep_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class AuthController extends GetxController {
  final AuthRepositoryImpl _repo = Get.find<AuthRepositoryImpl>();

  // ─── Estado observável ────────────────────────────────────────────────────
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedUserType = ''.obs; // 'client' | 'worker'

  // Força da senha
  final passwordStrength = 0.obs; // 0-4
  final passwordVisible = false.obs;
  final confirmPasswordVisible = false.obs;

  // Categorias selecionadas (registro de trabalhador)
  final selectedCategories = <String>[].obs;

  // Documento local (sem Storage)
  final documentFile = Rxn<File>();
  final documentPicked = false.obs;

  // ─── Endereço (preenchido automaticamente via CEP) ────────────────────────
  final addressLat = 0.0.obs;
  final addressLng = 0.0.obs;
  final addressFound = false.obs;
  /// Observável real do último resultado de CEP — use este (não os
  /// TextEditingControllers) dentro de qualquer Obx() que precise reagir
  /// ao preenchimento automático do endereço.
  final lastAddress = Rxn<CepResult>();

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerClientFormKey = GlobalKey<FormState>();
  final registerWorkerFormKey = GlobalKey<FormState>();

  // Controllers de texto
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // Endereço
  final cepCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final numberCtrl = TextEditingController();

  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final resetEmailCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    passwordCtrl.addListener(_updatePasswordStrength);
    _checkInitialAuth();
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl, emailCtrl, passwordCtrl, confirmPasswordCtrl,
      phoneCtrl, cepCtrl, streetCtrl, cityCtrl, stateCtrl,
      neighborhoodCtrl, numberCtrl, descriptionCtrl,
      priceCtrl, resetEmailCtrl,
    ]) { c.dispose(); }
    super.onClose();
  }

  // ─── Auth inicial ─────────────────────────────────────────────────────────
  Future<void> _checkInitialAuth() async {
    final user = _repo.currentUser;
    if (user == null) return;

    if (!user.emailVerified) {
      Get.offAllNamed(AppRoutes.verifyEmail);
      return;
    }

    final type = await _repo.getCachedUserType();
    await _navigateAfterLogin(type ?? 'client');
  }

  // ─── Seleção de tipo ──────────────────────────────────────────────────────
  void selectUserType(String type) {
    selectedUserType.value = type;
  }

  // ─── Endereço via CEP ─────────────────────────────────────────────────────
  /// Chamado pelo CepInputField quando o ViaCEP retorna um endereço válido.
  /// Preenche automaticamente rua, bairro, cidade e estado.
  void onAddressFound(CepResult result) {
    streetCtrl.text = result.street;
    neighborhoodCtrl.text = result.neighborhood;
    cityCtrl.text = result.city;
    stateCtrl.text = result.state;
    addressLat.value = result.lat;
    addressLng.value = result.lng;
    addressFound.value = true;
    lastAddress.value = result;
  }

  /// Limpa o endereço preenchido (caso o usuário troque o CEP).
  void clearAddress() {
    streetCtrl.clear();
    neighborhoodCtrl.clear();
    cityCtrl.clear();
    stateCtrl.clear();
    addressLat.value = 0;
    addressLng.value = 0;
    addressFound.value = false;
    lastAddress.value = null;
  }

  // ─── Login e-mail/senha ───────────────────────────────────────────────────
  Future<void> loginWithEmail() async {
    if (!loginFormKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      final type = await _repo.loginWithEmail(
        email: emailCtrl.text, password: passwordCtrl.text,
      );
      await _navigateAfterLogin(type);
    } on EmailNotVerifiedException {
      Get.offAllNamed(AppRoutes.verifyEmail);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login Google ─────────────────────────────────────────────────────────
  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      final type = await _repo.loginWithGoogle();
      await _navigateAfterLogin(type);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Registro cliente ─────────────────────────────────────────────────────
  Future<void> registerClient() async {
    if (!registerClientFormKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await _repo.registerClient(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        phone: phoneCtrl.text.trim(),
        cep: cepCtrl.text.trim(),
        street: streetCtrl.text.trim(),
        number: numberCtrl.text.trim(),
        neighborhood: neighborhoodCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        lat: addressLat.value,
        lng: addressLng.value,
      );
      Get.offAllNamed(AppRoutes.verifyEmail);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Registro trabalhador (passo 1: dados) ────────────────────────────────
  Future<void> goToDocumentUpload() async {
    if (!registerWorkerFormKey.currentState!.validate()) return;
    if (selectedCategories.isEmpty) {
      _showError('Selecione pelo menos uma categoria de serviço.');
      return;
    }
    if (!addressFound.value) {
      _showError('Informe um CEP válido para localizarmos seu endereço.');
      return;
    }
    Get.toNamed(AppRoutes.documentUpload);
  }

  // ─── Documento (passo 2: foto local) ─────────────────────────────────────
  Future<void> pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      documentFile.value = File(picked.path);
      documentPicked.value = true;
    }
  }

  Future<void> pickDocumentFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      documentFile.value = File(picked.path);
      documentPicked.value = true;
    }
  }

  Future<void> submitWorkerRegistration() async {
    if (!documentPicked.value) {
      _showError('Adicione uma foto do documento para continuar.');
      return;
    }
    _setLoading(true);
    try {
      final price = double.tryParse(
          priceCtrl.text.replaceAll(',', '.')) ?? 0;

      await _repo.registerWorker(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        phone: phoneCtrl.text.trim(),
        categories: selectedCategories.toList(),
        description: descriptionCtrl.text.trim(),
        pricePerHour: price,
        cep: cepCtrl.text.trim(),
        street: streetCtrl.text.trim(),
        number: numberCtrl.text.trim(),
        neighborhood: neighborhoodCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        lat: addressLat.value,
        lng: addressLng.value,
        documentLocalPath: documentFile.value?.path ?? '',
      );
      Get.offAllNamed(AppRoutes.verifyEmail);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Categorias ───────────────────────────────────────────────────────────
  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  // ─── Força da senha ───────────────────────────────────────────────────────
  void _updatePasswordStrength() {
    final pwd = passwordCtrl.text;
    int strength = 0;
    if (pwd.length >= 6) strength++;
    if (pwd.length >= 10) strength++;
    if (pwd.contains(RegExp(r'[A-Z]'))) strength++;
    if (pwd.contains(RegExp(r'[0-9]'))) strength++;
    if (pwd.contains(RegExp(r'[!@#\$%^&*]'))) strength++;
    passwordStrength.value = strength.clamp(0, 4);
  }

  // ─── Verificação de e-mail ────────────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    try {
      await _repo.resendVerificationEmail();
      Get.snackbar('E-mail enviado', 'Verifique sua caixa de entrada.',
          snackPosition: SnackPosition.BOTTOM);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkVerificationAndProceed() async {
    _setLoading(true);
    try {
      final verified = await _repo.checkEmailVerified();
      if (!verified) {
        _showError('E-mail ainda não verificado. Verifique sua caixa de entrada.');
        return;
      }
      final type = await _repo.getCachedUserType();
      if (type == 'worker') {
        Get.offAllNamed(AppRoutes.pendingVerification);
      } else {
        Get.offAllNamed(AppRoutes.clientHome);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Alias usado pela VerifyEmailScreen.
  Future<void> checkEmailAndProceed() => checkVerificationAndProceed();

  // ─── Redefinição de senha ─────────────────────────────────────────────────
  Future<void> sendPasswordReset() async {
    if (resetEmailCtrl.text.trim().isEmpty) {
      _showError('Informe seu e-mail.');
      return;
    }
    _setLoading(true);
    try {
      await _repo.sendPasswordReset(resetEmailCtrl.text.trim());
      Get.back();
      Get.snackbar('Enviado!',
          'Verifique seu e-mail para redefinir a senha.',
          snackPosition: SnackPosition.BOTTOM);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _repo.signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }

  // ─── Navegação pós-login ──────────────────────────────────────────────────
  /// Decide para onde mandar o usuário após login/cadastro. Para clientes,
  /// verifica antes se o perfil precisa ser completado (caso de quem entrou
  /// via Google sem CPF/endereço ainda) — sem isso, ele cairia direto na
  /// Home e só descobriria o bloqueio ao tentar solicitar um serviço.
  Future<void> _navigateAfterLogin(String type) async {
    if (type == 'worker') {
      Get.offAllNamed(AppRoutes.workerHome);
      return;
    }
    final needsCompletion = await _repo.currentUserNeedsProfileCompletion();
    if (needsCompletion) {
      Get.offAllNamed(AppRoutes.completeProfile);
    } else {
      Get.offAllNamed(AppRoutes.clientHome);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _setLoading(bool v) => isLoading.value = v;
  void _showError(String msg) => errorMessage.value = msg;
  void clearError() => errorMessage.value = '';
  void togglePasswordVisibility() =>
      passwordVisible.value = !passwordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      confirmPasswordVisible.value = !confirmPasswordVisible.value;
}
