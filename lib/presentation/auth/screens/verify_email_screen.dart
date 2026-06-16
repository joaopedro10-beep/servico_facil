import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../controllers/auth_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _checkTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Verifica automaticamente a cada 5 segundos se o email foi confirmado
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      Get.find<AuthController>().checkVerificationAndProceed();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _resend() async {
    if (_resendCooldown > 0) return;
    await Get.find<AuthController>().resendVerificationEmail();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

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
              // Ícone animado
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    size: 52, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              const Text('Verifique seu e-mail',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                'Enviamos um link de confirmação para o seu e-mail. '
                    'Clique no link para ativar sua conta e continuar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.6, fontSize: 14),
              ),
              const SizedBox(height: 12),
              // Verificando automaticamente
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppColors.primary)),
                SizedBox(width: 8),
                Text('Aguardando confirmação...',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 13)),
              ]),
              const Spacer(),

              // Botão reenviar
              Obx(() => PrimaryButton(
                label: _resendCooldown > 0
                    ? 'Reenviar em ${_resendCooldown}s'
                    : 'Reenviar e-mail',
                isLoading: ctrl.isLoading.value,
                onPressed: _resendCooldown > 0 ? null : _resend,
                icon: Icons.send_outlined,
              )),
              const SizedBox(height: 14),

              // Verificar agora
              OutlinedButton(
                onPressed: ctrl.checkVerificationAndProceed,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('Já confirmei, continuar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 14),

              // Voltar / trocar conta
              TextButton(
                onPressed: () async {
                  _checkTimer?.cancel();
                  await ctrl.signOut();
                },
                child: const Text('Usar outra conta',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
