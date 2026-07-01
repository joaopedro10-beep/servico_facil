import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/utils/validators.dart';

class ClientProfileController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final AuthRepositoryImpl _repo = Get.find<AuthRepositoryImpl>();

  // ─── Estado observável ────────────────────────────────────────────────────
  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  // Modo de edição
  final isEditing = false.obs;

  // ─── Form ──────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cpfCtrl = TextEditingController();

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    cpfCtrl.dispose();
    super.onClose();
  }

  // ─── Carregar dados do usuário ─────────────────────────────────────────────
  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      final uid = _fb.uid;
      final user = await _ds.getUser(uid);
      currentUser.value = user;
      _fillControllers(user);
    } catch (_) {
      errorMessage.value = 'Erro ao carregar perfil.';
    } finally {
      isLoading.value = false;
    }
  }

  void _fillControllers(UserModel? user) {
    if (user == null) return;
    nameCtrl.text = user.name;
    phoneCtrl.text = user.phone;
    cpfCtrl.text = user.cpf ?? '';
  }

  // ─── Getters de exibição ──────────────────────────────────────────────────
  String get displayName => currentUser.value?.name ?? '';
  String get displayEmail => currentUser.value?.email ?? '';
  String get displayPhone => currentUser.value?.phone ?? '';
  String get displayCpf => _formatCpf(currentUser.value?.cpf ?? '');
  String get displayAddress {
    final addr = currentUser.value?.address;
    if (addr == null || addr.city.isEmpty) return 'Endereço não informado';
    final parts = <String>[];
    if (addr.street.isNotEmpty) {
      parts.add(addr.number.isNotEmpty
          ? '${addr.street}, ${addr.number}'
          : addr.street);
    }
    if (addr.neighborhood.isNotEmpty) parts.add(addr.neighborhood);
    if (addr.city.isNotEmpty) {
      parts.add(addr.state.isNotEmpty ? '${addr.city}/${addr.state}' : addr.city);
    }
    return parts.join(' — ');
  }

  /// Inicial do nome para exibição no avatar quando não há foto.
  String get nameInitial {
    final name = currentUser.value?.name ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// true = precisa completar algum dado (CPF ou endereço).
  bool get hasIncompleteData {
    final u = currentUser.value;
    if (u == null) return false;
    return u.cpf == null ||
        u.cpf!.isEmpty ||
        u.address.city.isEmpty ||
        u.phone.isEmpty;
  }

  String _formatCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  // ─── Edição ────────────────────────────────────────────────────────────────
  void startEditing() {
    isEditing.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    _fillControllers(currentUser.value);
  }

  void cancelEditing() {
    isEditing.value = false;
    errorMessage.value = '';
    _fillControllers(currentUser.value);
  }

  // ─── Validação de CPF único no banco ──────────────────────────────────────
  /// Verifica no Firestore se o CPF já está cadastrado por OUTRO usuário.
  /// Essa é a trava que garante um login por CPF — o banco recusa
  /// qualquer tentativa de cadastrar o mesmo CPF em contas diferentes.
  Future<bool> _isCpfAlreadyInUse(String cpf) async {
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
    final myUid = _fb.uid;

    final query = await _fb.usersRef
        .where('cpf', isEqualTo: cleanCpf)
        .limit(2)
        .get();

    // Filtra fora o próprio usuário — CPF igual ao do próprio perfil é OK
    final othersWithSameCpf =
        query.docs.where((d) => d.id != myUid).toList();

    return othersWithSameCpf.isNotEmpty;
  }

  // ─── Salvar dados ──────────────────────────────────────────────────────────
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    isSaving.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final cpfDigits = cpfCtrl.text.replaceAll(RegExp(r'\D'), '');

      // Validação de CPF único — bloqueia se já existe em outra conta
      if (cpfDigits.isNotEmpty) {
        final inUse = await _isCpfAlreadyInUse(cpfDigits);
        if (inUse) {
          errorMessage.value =
              'Este CPF já está cadastrado em outra conta. '
              'Cada CPF permite apenas um cadastro.';
          return;
        }
      }

      await _ds.updateUser(_fb.uid, {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        if (cpfDigits.isNotEmpty) 'cpf': cpfDigits,
      });

      // Atualiza localmente sem precisar recarregar do Firestore
      currentUser.value = currentUser.value?.copyWith(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        cpf: cpfDigits.isNotEmpty ? cpfDigits : currentUser.value?.cpf,
      );

      isEditing.value = false;
      successMessage.value = 'Perfil atualizado com sucesso!';

      // Limpa a mensagem de sucesso após 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        successMessage.value = '';
      });
    } on FirebaseException catch (e) {
      errorMessage.value = 'Erro ao salvar: ${e.message}';
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  /// Faz logout e redireciona para a tela de boas-vindas.
  /// O usuário permanece logado entre sessões até chamar este método.
  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _repo.signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
