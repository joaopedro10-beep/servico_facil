import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class ClientProfileController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final AuthRepositoryImpl _repo = Get.find<AuthRepositoryImpl>();

  // ─── Estado ───────────────────────────────────────────────────────────────
  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final isEditing = false.obs;

  // ─── Form ─────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cpfCtrl = TextEditingController();

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

  // ─── Carregar dados ───────────────────────────────────────────────────────
  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      final user = await _ds.getUser(_fb.uid);
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

  // ─── Getters ──────────────────────────────────────────────────────────────
  String get displayName => currentUser.value?.name ?? '';
  String get displayEmail => currentUser.value?.email ?? '';
  String get displayPhone => currentUser.value?.phone.isNotEmpty == true
      ? currentUser.value!.phone
      : 'Não informado';

  String get displayCpf {
    final cpf = currentUser.value?.cpf ?? '';
    if (cpf.length != 11) return cpf.isEmpty ? 'Não informado' : cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String get displayAddress {
    final addr = currentUser.value?.address;
    if (addr == null || addr.city.isEmpty) return 'Endereço não informado';
    return addr.fullAddress;
  }

  String get nameInitial {
    final name = currentUser.value?.name ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// true = ainda tem dados obrigatórios faltando
  bool get hasIncompleteData {
    final u = currentUser.value;
    if (u == null) return false;
    return (u.cpf == null || u.cpf!.isEmpty) ||
        u.phone.isEmpty ||
        u.address.city.isEmpty;
  }

  // ─── Edição ───────────────────────────────────────────────────────────────
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

  // ─── Validação de CPF único ───────────────────────────────────────────────
  Future<bool> _isCpfInUse(String cpf) async {
    final query = await _fb.usersRef
        .where('cpf', isEqualTo: cpf)
        .limit(2)
        .get();
    return query.docs.any((d) => d.id != _fb.uid);
  }

  // ─── Salvar ───────────────────────────────────────────────────────────────
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    isSaving.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final cpfDigits = cpfCtrl.text.replaceAll(RegExp(r'\D'), '');

      if (cpfDigits.isNotEmpty) {
        final inUse = await _isCpfInUse(cpfDigits);
        if (inUse) {
          errorMessage.value =
              'Este CPF já está cadastrado em outra conta. '
              'Cada CPF permite apenas um cadastro.';
          return;
        }
      }

      final updates = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        if (cpfDigits.isNotEmpty) 'cpf': cpfDigits,
      };

      await _ds.updateUser(_fb.uid, updates);

      currentUser.value = currentUser.value?.copyWith(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        cpf: cpfDigits.isNotEmpty ? cpfDigits : currentUser.value?.cpf,
      );

      isEditing.value = false;
      successMessage.value = 'Perfil atualizado com sucesso!';
      Future.delayed(const Duration(seconds: 3),
          () => successMessage.value = '');
    } on FirebaseException catch (e) {
      errorMessage.value = 'Erro ao salvar: ${e.message}';
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
            'Tem certeza que deseja sair? Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sair',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
