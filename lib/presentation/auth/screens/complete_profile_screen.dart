import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/dialogs/error_banner.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/inputs/cep_input_field.dart';
import '../controllers/complete_profile_controller.dart';

/// Tela exibida apenas para clientes que entraram via Google e ainda não
/// têm CPF + endereço cadastrados. Bloqueia o acesso à Home até ser
/// preenchida — sem isso, a Firestore Rule de 'orders' impede qualquer
/// solicitação de serviço (UserModel.isProfileComplete fica false).
class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CompleteProfileController());

    return Scaffold(
      appBar: AppBar(title: const Text('Complete seu cadastro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: ctrl.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Só mais um passo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Como você entrou com o Google, precisamos confirmar seu CPF '
                  'e endereço para garantir mais segurança para os prestadores.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),

                // Aviso de privacidade — sem upload de documento aqui,
                // diferente do fluxo do trabalhador.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.25)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Não pedimos foto de documento aqui — apenas confirmação '
                        'de dados, diferente do cadastro de prestador.',
                        style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                AppTextField(
                  controller: ctrl.cpfCtrl,
                  label: 'CPF',
                  hint: '000.000.000-00',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: Validators.cpf,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                ),
                const SizedBox(height: 14),

                AppTextField(
                  controller: ctrl.phoneCtrl,
                  label: 'Telefone / WhatsApp',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 24),

                const Text('Endereço',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                CepInputField(
                  controller: ctrl.cepCtrl,
                  onAddressFound: ctrl.onAddressFound,
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 8) return 'Informe um CEP válido';
                    return null;
                  },
                ),

                Obx(() {
                  final addr = ctrl.lastAddress.value;
                  return AddressPreviewCard(
                    street: addr?.street ?? '',
                    neighborhood: addr?.neighborhood ?? '',
                    city: addr?.city ?? '',
                    state: addr?.state ?? '',
                  );
                }),
                const SizedBox(height: 14),

                AppTextField(
                  controller: ctrl.numberCtrl,
                  label: 'Número',
                  hint: 'Ex: 123',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  validator: (v) => Validators.required(v, field: 'Número'),
                ),
                const SizedBox(height: 24),

                Obx(() => ctrl.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : ErrorBanner(ctrl.errorMessage.value)),

                Obx(() => PrimaryButton(
                  label: 'Concluir cadastro',
                  isLoading: ctrl.isLoading.value,
                  onPressed: () {
                    ctrl.clearError();
                    ctrl.submit();
                  },
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
