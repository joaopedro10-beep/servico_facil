import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/cep_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Controller exclusivo da tela de complemento de cadastro — usado apenas
/// por clientes que entraram via Google e ainda não têm CPF/endereço
/// cadastrados (UserModel.isProfileComplete == false).
class CompleteProfileController extends GetxController {
  final AuthRepositoryImpl _repo = Get.find<AuthRepositoryImpl>();

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final addressLat = 0.0.obs;
  final addressLng = 0.0.obs;
  final lastAddress = Rxn<CepResult>();

  final formKey = GlobalKey<FormState>();

  final cpfCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cepCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();

  @override
  void onClose() {
    for (final c in [
      cpfCtrl, phoneCtrl, cepCtrl, streetCtrl,
      numberCtrl, neighborhoodCtrl, cityCtrl, stateCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  void onAddressFound(CepResult result) {
    streetCtrl.text = result.street;
    neighborhoodCtrl.text = result.neighborhood;
    cityCtrl.text = result.city;
    stateCtrl.text = result.state;
    addressLat.value = result.lat;
    addressLng.value = result.lng;
    lastAddress.value = result;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _repo.completeGoogleProfile(
        cpf: cpfCtrl.text.trim(),
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
      // Navega para tela de sucesso após completar cadastro
      Get.offAllNamed(AppRoutes.completeProfileSuccess);
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() => errorMessage.value = '';
}
