import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/report_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _ds = Get.find<FirestoreDatasource>();
  final _fb = Get.find<FirebaseService>();

  String? _selectedReason;
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  late String _reportedId;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _reportedId = args?['targetId'] as String? ?? '';
    _orderId = args?['orderId'] as String?;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fazer denúncia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Denúncias falsas podem resultar em suspensão da sua conta. Use este recurso com responsabilidade.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Motivo ─────────────────────────────────────────────────
            const Text('Motivo da denúncia *',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReportModel.reasons.map((reason) {
                final sel = _selectedReason == reason;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedReason = reason),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.error : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? AppColors.error
                              : AppColors.border),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Descrição ──────────────────────────────────────────────
            const Text('Descrição adicional (opcional)',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText:
                    'Descreva o ocorrido com mais detalhes...',
              ),
            ),
            const SizedBox(height: 28),

            // ── Botão ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: _isSaving ? null : _confirmAndSend,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.flag_outlined),
                label: Text(
                    _isSaving ? 'Enviando...' : 'Enviar denúncia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSend() async {
    if (_selectedReason == null) {
      Get.snackbar('Atenção', 'Selecione um motivo para a denúncia.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar denúncia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Motivo:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_selectedReason!),
            if (_descCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Descrição:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_descCtrl.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final report = ReportModel(
        id: '',
        reporterId: _fb.uid,
        reportedId: _reportedId,
        reason: _selectedReason!,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        orderId: _orderId,
        createdAt: DateTime.now(),
      );

      await _ds.createReport(report);

      Get.back();
      Get.snackbar(
        'Denúncia enviada',
        'Nossa equipe irá analisar em breve. Obrigado por ajudar a manter a comunidade segura.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível enviar a denúncia.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
