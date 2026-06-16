import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../core/constants/app_routes.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../controllers/auth_controller.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              // Ilustração
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 56, color: AppColors.warning),
              ),
              const SizedBox(height: 28),
              const Text('Cadastro em análise',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'Recebemos seus dados e o documento de verificação. '
                    'Nossa equipe irá analisar e aprovar seu cadastro em até 24 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, height: 1.6, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Passos do processo
              _StepRow(
                step: '1', label: 'Cadastro enviado',
                status: _StepStatus.done,
              ),
              const SizedBox(height: 12),
              _StepRow(
                step: '2', label: 'Verificação de documento',
                status: _StepStatus.inProgress,
              ),
              const SizedBox(height: 12),
              _StepRow(
                step: '3', label: 'Conta aprovada e ativa',
                status: _StepStatus.pending,
              ),

              const Spacer(),

              // Aviso
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.notifications_outlined,
                      color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Você receberá uma notificação quando seu cadastro for aprovado.',
                      style: TextStyle(fontSize: 13, color: AppColors.info,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Verificar se foi aprovado
              Obx(() => PrimaryButton(
                label: 'Verificar aprovação',
                isLoading: ctrl.isLoading.value,
                onPressed: () => _checkApproval(ctrl),
              )),
              const SizedBox(height: 12),

              TextButton(
                onPressed: ctrl.signOut,
                child: const Text('Sair da conta',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkApproval(AuthController ctrl) async {
    ctrl.isLoading.value = true;
    try {
      final fb = Get.find<FirebaseService>();
      final firestoreDs = Get.find<FirestoreDatasource>();
      final uid = fb.currentUser?.uid;
      if (uid == null) return;

      final worker = await firestoreDs.getWorker(uid);
      if (worker == null) return;

      if (worker.isVerified) {
        Get.offAllNamed(AppRoutes.workerHome);
      } else {
        Get.snackbar(
          'Ainda em análise',
          'Seu cadastro ainda está sendo verificado. Aguarde o e-mail de confirmação.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning.withOpacity(0.1),
          colorText: AppColors.textPrimary,
          icon: const Icon(Icons.info_outline, color: AppColors.warning),
        );
      }
    } finally {
      ctrl.isLoading.value = false;
    }
  }
}

enum _StepStatus { done, inProgress, pending }

class _StepRow extends StatelessWidget {
  final String step;
  final String label;
  final _StepStatus status;
  const _StepRow({required this.step, required this.label, required this.status});

  Color get _color {
    switch (status) {
      case _StepStatus.done: return AppColors.success;
      case _StepStatus.inProgress: return AppColors.warning;
      case _StepStatus.pending: return AppColors.textHint;
    }
  }

  Widget get _icon {
    switch (status) {
      case _StepStatus.done:
        return const Icon(Icons.check, color: Colors.white, size: 16);
      case _StepStatus.inProgress:
        return const SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
      case _StepStatus.pending:
        return Text(step,
            style: const TextStyle(color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w600));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        child: Center(child: _icon),
      ),
      const SizedBox(width: 14),
      Text(label, style: TextStyle(
          fontSize: 14,
          fontWeight: status == _StepStatus.inProgress
              ? FontWeight.w600 : FontWeight.normal,
          color: status == _StepStatus.pending
              ? AppColors.textHint : AppColors.textPrimary)),
    ]);
  }
}
