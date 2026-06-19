import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_model.dart';
import '../controllers/order_controller.dart';

class RequestServiceSheet extends StatelessWidget {
  const RequestServiceSheet({super.key, required this.worker});
  final WorkerModel worker;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderController>()..resetSheet();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: ctrl.sheetFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Solicitar serviço',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              // Info do trabalhador
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${worker.name} · ${worker.categories.isNotEmpty ? worker.categories.first : ""}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'R\$ ${worker.pricePerHour.toStringAsFixed(0)}/h',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Descrição ──────────────────────────────────────────────
              _Label('Descreva o problema *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: ctrl.descriptionCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Ex: Torneira da cozinha pingando há 3 dias, preciso trocar o vedante...',
                ),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Descreva o problema com pelo menos 20 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Fotos ──────────────────────────────────────────────────
              _Label('Fotos do problema (máx. 3)'),
              const SizedBox(height: 8),
              Obx(() => _buildPhotoRow(ctrl)),
              const SizedBox(height: 20),

              // ── Data e hora ────────────────────────────────────────────
              _Label('Data e hora desejada *'),
              const SizedBox(height: 6),
              Obx(() {
                final dt = ctrl.sheetScheduledAt.value;
                return GestureDetector(
                  onTap: () => ctrl.pickDateTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          dt != null
                              ? DateFormat(
                                      "EEE, dd 'de' MMM · HH:mm",
                                      'pt_BR')
                                  .format(dt)
                              : 'Selecionar data e hora',
                          style: TextStyle(
                            fontSize: 14,
                            color: dt != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // ── Endereço ───────────────────────────────────────────────
              _Label('Endereço do serviço *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: ctrl.addressCtrl,
                decoration: InputDecoration(
                  hintText: 'Rua, número, bairro...',
                  suffixIcon: Obx(() => ctrl.isLoadingLocation.value
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2)),
                        )
                      : IconButton(
                          tooltip: 'Usar minha localização',
                          icon: const Icon(Icons.my_location,
                              color: AppColors.primary),
                          onPressed: ctrl.pickCurrentLocation,
                        )),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) && ctrl.sheetAddress.value == null
                        ? 'Informe o endereço'
                        : null,
              ),
              const SizedBox(height: 28),

              // ── Botão enviar ───────────────────────────────────────────
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isSaving.value
                          ? null
                          : () => ctrl.submitRequest(worker),
                      icon: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(ctrl.isSaving.value
                          ? 'Enviando...'
                          : 'Enviar solicitação'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoRow(OrderController ctrl) {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          // Thumbnails das fotos
          ...ctrl.sheetPhotos.asMap().entries.map((e) {
            return Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: FileImage(e.value),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => ctrl.removeSheetPhoto(e.key),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            );
          }),

          // Botão adicionar (só aparece se < 3)
          if (ctrl.sheetPhotos.length < 3)
            GestureDetector(
              onTap: ctrl.pickSheetPhoto,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primary,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.primary, size: 26),
                    SizedBox(height: 2),
                    Text('Adicionar',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}
