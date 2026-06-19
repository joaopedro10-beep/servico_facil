import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';

class BlockScreen extends StatelessWidget {
  const BlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = Get.find<FirestoreDatasource>();
    final fb = Get.find<FirebaseService>();

    final args = Get.arguments as Map<String, dynamic>?;
    final targetId = args?['targetId'] as String? ?? '';
    final targetName = args?['targetName'] as String? ?? 'este usuário';

    return Scaffold(
      appBar: AppBar(title: const Text('Bloquear usuário')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block,
                    color: AppColors.error, size: 52),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Bloquear $targetName?',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            const Text(
              'Ao bloquear, este usuário:',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...[
              'Não poderá enviar mensagens para você',
              'Não aparecerá nas suas buscas',
              'Não poderá solicitar serviços com você',
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Text(item,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'Você pode desbloquear a qualquer momento em Configurações → Usuários bloqueados.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.4),
            ),
            const Spacer(),

            // Botões
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () =>
                    _confirmBlock(context, ds, fb, targetId, targetName),
                icon: const Icon(Icons.block),
                label: const Text('Confirmar bloqueio'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBlock(
    BuildContext context,
    FirestoreDatasource ds,
    FirebaseService fb,
    String targetId,
    String targetName,
  ) async {
    try {
      await ds.blockUser(
          currentUserId: fb.uid, targetId: targetId);
      Get.back();
      Get.snackbar(
        'Usuário bloqueado',
        '$targetName foi bloqueado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível bloquear.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
