import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../controllers/auth_controller.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Ícone / logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.handyman_rounded,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              const Text('ServiçoFácil',
                  style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 10),
              Text(
                'Encontre profissionais de confiança\nperto de você, quando precisar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5,
                ),
              ),
              const Spacer(flex: 3),

              // Botão cliente
              _WelcomeButton(
                label: 'Sou Cliente',
                subtitle: 'Preciso de um profissional',
                icon: Icons.person_search_rounded,
                color: AppColors.primary,
                onTap: () {
                  Get.find<AuthController>().selectUserType('client');
                  Get.toNamed(AppRoutes.registerClient);
                },
              ),
              const SizedBox(height: 14),

              // Botão prestador
              _WelcomeButton(
                label: 'Sou Prestador',
                subtitle: 'Quero oferecer meus serviços',
                icon: Icons.engineering_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Get.find<AuthController>().selectUserType('worker');
                  Get.toNamed(AppRoutes.registerWorker);
                },
              ),
              const SizedBox(height: 24),

              // Link de login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Já tem conta? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.login),
                    child: const Text('Entrar',
                        style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.label, required this.subtitle, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: color,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary,
              )),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
        ]),
      ),
    );
  }

}
