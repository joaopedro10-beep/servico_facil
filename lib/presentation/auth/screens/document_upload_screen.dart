import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../../../widgets/dialogs/error_banner.dart';

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Enviar documento')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              const Text('Verificação de identidade',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Para garantir a segurança de todos, precisamos de uma foto do seu documento (RG ou CNH). '
                    'Sua conta ficará em análise até a aprovação.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 10),

              // Aviso de privacidade
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seu documento é armazenado com segurança e usado apenas para verificação.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // Área de upload / preview
              Expanded(
                child: Obx(() {
                  final file = ctrl.documentFile.value;
                  return GestureDetector(
                    onTap: () => _showPickOptions(context, ctrl),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: file != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: file != null ? 2 : 1,
                          style: file != null
                              ? BorderStyle.solid
                              : BorderStyle.solid,
                        ),
                      ),
                      child: file != null
                          ? _DocumentPreview(file: file, onRemove: () {
                        ctrl.documentFile.value = null;
                        ctrl.documentPicked.value = false;
                      })
                          : _UploadPlaceholder(),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Dicas
              _TipRow(
                  icon: Icons.check_circle_outline,
                  text: 'Foto nítida, sem cortes'),
              const SizedBox(height: 6),
              _TipRow(
                  icon: Icons.check_circle_outline,
                  text: 'Todos os dados legíveis'),
              const SizedBox(height: 6),
              _TipRow(
                  icon: Icons.check_circle_outline,
                  text: 'Frente do documento'),
              const SizedBox(height: 24),

              Obx(() => ctrl.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : ErrorBanner(ctrl.errorMessage.value)),

              Obx(() => PrimaryButton(
                label: 'Concluir cadastro',
                isLoading: ctrl.isLoading.value,
                onPressed: () {
                  ctrl.clearError();
                  ctrl.submitWorkerRegistration();
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickOptions(BuildContext context, AuthController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Escolher da galeria'),
              onTap: () { Get.back(); ctrl.pickDocument(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Tirar foto'),
              onTap: () { Get.back(); ctrl.pickDocumentFromCamera(); },
            ),
          ]),
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.upload_file_rounded,
              size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text('Toque para adicionar foto',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('RG ou CNH', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _DocumentPreview({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file,
              fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
        Positioned(
          top: 10, right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 10, left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Documento selecionado',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.success),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(
          fontSize: 13, color: AppColors.textSecondary)),
    ]);
  }

}
