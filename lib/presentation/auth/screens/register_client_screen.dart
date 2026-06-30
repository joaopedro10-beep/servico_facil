import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/dialogs/error_banner.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/inputs/cep_input_field.dart';
import '../controllers/auth_controller.dart';

class RegisterClientScreen extends StatelessWidget {
  const RegisterClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta — Cliente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: ctrl.registerClientFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seus dados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Preencha os campos abaixo para criar sua conta.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 28),

                AppTextField(
                  controller: ctrl.nameCtrl,
                  label: 'Nome completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                AppTextField(
                  controller: ctrl.emailCtrl,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
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

                // ── Endereço via CEP ─────────────────────────────────────────
                const Text('Endereço',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Informe seu CEP e localizamos o endereço automaticamente.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
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

                // ── Senha ────────────────────────────────────────────────────
                Obx(() => PasswordStrengthField(
                  controller: ctrl.passwordCtrl,
                  label: 'Senha',
                  visible: ctrl.passwordVisible.value,
                  onToggleVisibility: ctrl.togglePasswordVisibility,
                  strength: ctrl.passwordStrength.value,
                  validator: Validators.password,
                )),
                const SizedBox(height: 14),

                Obx(() => AppTextField(
                  controller: ctrl.confirmPasswordCtrl,
                  label: 'Confirmar senha',
                  obscureText: !ctrl.confirmPasswordVisible.value,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) =>
                      Validators.confirmPassword(v, ctrl.passwordCtrl.text),
                  suffixIcon: IconButton(
                    icon: Icon(ctrl.confirmPasswordVisible.value
                        ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary),
                    onPressed: ctrl.toggleConfirmPasswordVisibility,
                  ),
                )),
                const SizedBox(height: 8),

                // Termos
                const Text(
                  'Ao criar conta, você concorda com nossos Termos de Uso e Política de Privacidade.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),

                Obx(() => ctrl.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : ErrorBanner(ctrl.errorMessage.value)),

                Obx(() => PrimaryButton(
                  label: 'Criar minha conta',
                  isLoading: ctrl.isLoading.value,
                  onPressed: () {
                    ctrl.clearError();
                    ctrl.registerClient();
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
