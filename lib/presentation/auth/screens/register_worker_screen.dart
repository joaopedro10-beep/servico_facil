import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../../../widgets/dialogs/error_banner.dart';

// Ícones por categoria
const _categoryIcons = {
  'Encanador': Icons.water_drop_outlined,
  'Eletricista': Icons.electrical_services_outlined,
  'Diarista': Icons.cleaning_services_outlined,
  'Pintor': Icons.format_paint_outlined,
  'Jardineiro': Icons.yard_outlined,
  'Montador': Icons.handyman_outlined,
  'Pedreiro': Icons.construction_outlined,
  'TI / Suporte': Icons.computer_outlined,
};

class RegisterWorkerScreen extends StatelessWidget {
  const RegisterWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta — Prestador')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: ctrl.registerWorkerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dados profissionais',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Preencha seus dados e mostre o que você faz de melhor.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 28),

                // ── Dados pessoais ──────────────────────────────────────────
                _SectionTitle('Dados pessoais'),
                const SizedBox(height: 12),

                AppTextField(
                  controller: ctrl.nameCtrl,
                  label: 'Nome completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.name,
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
                const SizedBox(height: 14),
                AppTextField(
                  controller: ctrl.cityCtrl,
                  label: 'Cidade',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  validator: (v) => Validators.required(v, field: 'Cidade'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: ctrl.neighborhoodCtrl,
                  label: 'Bairro de atuação',
                  prefixIcon: const Icon(Icons.map_outlined),
                  validator: (v) => Validators.required(v, field: 'Bairro'),
                ),
                const SizedBox(height: 28),

                // ── Dados profissionais ─────────────────────────────────────
                _SectionTitle('Serviços que você oferece'),
                const SizedBox(height: 6),
                const Text('Selecione pelo menos uma categoria:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),

                Obx(() => Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppStrings.serviceCategories.map((cat) {
                    final selected = ctrl.selectedCategories.contains(cat);
                    return FilterChip(
                      label: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_categoryIcons[cat] ?? Icons.work_outline,
                            size: 16,
                            color: selected ? AppColors.primary : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(cat),
                      ]),
                      selected: selected,
                      onSelected: (_) => ctrl.toggleCategory(cat),
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 20),

                AppTextField(
                  controller: ctrl.descriptionCtrl,
                  label: 'Descrição profissional',
                  hint: 'Conte um pouco sobre sua experiência...',
                  maxLines: 3,
                  maxLength: 300,
                  validator: (v) =>
                      Validators.minLength(v, 20, field: 'Descrição'),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  controller: ctrl.priceCtrl,
                  label: 'Preço por hora (R\$)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: Validators.price,
                ),
                const SizedBox(height: 28),

                // ── Senha ───────────────────────────────────────────────────
                _SectionTitle('Senha de acesso'),
                const SizedBox(height: 12),

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
                const SizedBox(height: 24),

                Obx(() => ctrl.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    :ErrorBanner(ctrl.errorMessage.value)),

                Obx(() => PrimaryButton(
                  label: 'Próximo: Enviar documento',
                  isLoading: ctrl.isLoading.value,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    ctrl.clearError();
                    ctrl.goToDocumentUpload();
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ));
  }
}
