import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

/// Tela exibida imediatamente após o cliente completar o cadastro
/// (CPF + telefone + endereço). Confirma que o perfil está ativo e
/// o usuário já pode solicitar serviços.
class CompleteProfileSuccessScreen extends StatelessWidget {
  const CompleteProfileSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ícone de sucesso
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 72,
                ),
              ),
              const SizedBox(height: 28),

              // Título
              const Text(
                'Cadastro concluído!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Mensagem principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Seu cadastro foi completo.\nVocê já pode solicitar serviços!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detalhes do que foi desbloqueado
              _UnlockItem(
                icon: Icons.handyman_rounded,
                text: 'Solicitar serviços de qualquer prestador',
              ),
              const SizedBox(height: 8),
              _UnlockItem(
                icon: Icons.location_on_rounded,
                text: 'Ver profissionais próximos de você',
              ),
              const SizedBox(height: 8),
              _UnlockItem(
                icon: Icons.chat_bubble_rounded,
                text: 'Conversar diretamente com prestadores',
              ),
              const SizedBox(height: 8),
              _UnlockItem(
                icon: Icons.star_rounded,
                text: 'Avaliar os serviços recebidos',
              ),

              const Spacer(),

              // Botão
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.clientHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Começar a usar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _UnlockItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    ]);
  }
}
