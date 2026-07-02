import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/dialogs/error_banner.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: ctrl.loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Bem-vindo de volta!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Entre com seus dados para continuar.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                AppTextField(
                  controller: ctrl.emailCtrl,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                Obx(() => AppTextField(
                  controller: ctrl.passwordCtrl,
                  label: 'Senha',
                  obscureText: !ctrl.passwordVisible.value,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) => Validators.required(v, field: 'Senha'),
                  suffixIcon: IconButton(
                    icon: Icon(ctrl.passwordVisible.value
                        ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary),
                    onPressed: ctrl.togglePasswordVisibility,
                  ),
                )),
                const SizedBox(height: 10),

                // Esqueceu a senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showResetDialog(context, ctrl),
                    child: const Text('Esqueci minha senha',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ),

                // Erro
                Obx(() => ctrl.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : ErrorBanner(ctrl.errorMessage.value)),

                const SizedBox(height: 8),

                // Botão entrar
                Obx(() => PrimaryButton(
                  label: 'Entrar',
                  isLoading: ctrl.isLoading.value,
                  onPressed: ctrl.loginWithEmail,
                )),
                const SizedBox(height: 16),

                // Divisor
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou', style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                // Google Sign-In — disponível apenas para clientes.
                // Não há como saber, nesta tela única de login, se quem
                // está entrando é cliente ou prestador antes da autenticação
                // acontecer. Por isso a restrição é aplicada em duas camadas
                // depois do clique: AuthRepositoryImpl.loginWithGoogle()
                // verifica se já existe um worker com esse uid e bloqueia
                // com mensagem clara, e as Firestore Rules nunca aceitam um
                // documento em /workers com authProvider != 'password'.
                Obx(() => OutlineButton(
                  label: 'Continuar com Google',
                  onPressed: ctrl.isLoading.value ? null : ctrl.loginWithGoogle,
                  iconWidget: const _GoogleIcon(),
                )),
                const SizedBox(height: 28),

                // Criar conta
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Não tem conta? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.welcome),
                    child: const Text('Criar conta',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, AuthController ctrl) {
    ctrl.resetEmailCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Informe seu e-mail e enviaremos um link de redefinição.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          AppTextField(
            controller: ctrl.resetEmailCtrl,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(() => TextButton(
            onPressed: ctrl.isLoading.value ? null : () async {
              await ctrl.sendPasswordReset();
            },
            child: ctrl.isLoading.value
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enviar'),
          )),
        ],
      ),
    );
  }
}


// ─── Ícone do Google desenhado em código (sem depender de rede) ───────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Azul (fatia direita)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.3, 1.9, true,
      Paint()..color = const Color(0xFF4285F4),
    );
    // Vermelho (fatia top-esquerda)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.6, 1.6, true,
      Paint()..color = const Color(0xFFEA4335),
    );
    // Amarelo (fatia bottom-esquerda)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      5.2, 0.95, true,
      Paint()..color = const Color(0xFFFBBC05),
    );
    // Verde (fatia bottom-direita)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      6.15, 0.75, true,
      Paint()..color = const Color(0xFF34A853),
    );
    // Branco no centro (cria o efeito "G")
    canvas.drawCircle(
      Offset(cx, cy), r * 0.62,
      Paint()..color = Colors.white,
    );
    // Retângulo branco direito (corte do "G")
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r, r * 0.36),
      Paint()..color = Colors.white,
    );
    // Retângulo azul (barra direita do "G")
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r * 0.9, r * 0.36),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
