import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/worker_profile_controller.dart';

class EditWorkerProfileScreen extends StatelessWidget {
  const EditWorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WorkerProfileController>()..prepareEdit();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          Obx(() => ctrl.isSaving.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2)))
              : TextButton(
                  onPressed: ctrl.saveProfile,
                  child: const Text('Salvar',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                )),
        ],
      ),
      body: Form(
        key: ctrl.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Foto de perfil ─────────────────────────────────────────────
            _SectionTitle(title: 'Foto de perfil'),
            const SizedBox(height: 12),
            _buildProfilePhotoEditor(ctrl),

            const SizedBox(height: 24),

            // ── Disponibilidade ────────────────────────────────────────────
            _SectionTitle(title: 'Disponibilidade'),
            const SizedBox(height: 8),
            _buildAvailabilitySwitch(ctrl),

            const SizedBox(height: 24),

            // ── Descrição ──────────────────────────────────────────────────
            _SectionTitle(title: 'Descrição profissional'),
            const SizedBox(height: 8),
            TextFormField(
              controller: ctrl.descriptionCtrl,
              maxLines: 4,
              maxLength: 400,
              decoration: const InputDecoration(
                hintText: 'Fale sobre sua experiência e diferenciais...',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 20)
                      ? 'Mínimo de 20 caracteres'
                      : null,
            ),

            const SizedBox(height: 24),

            // ── Categorias ─────────────────────────────────────────────────
            _SectionTitle(title: 'Categorias de serviço'),
            const SizedBox(height: 8),
            _buildCategorySelector(ctrl),

            const SizedBox(height: 24),

            // ── Preço ──────────────────────────────────────────────────────
            _SectionTitle(title: 'Preço por hora (R\$)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: ctrl.priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o preço';
                final val =
                    double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Preço inválido';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Bairro ─────────────────────────────────────────────────────
            _SectionTitle(title: 'Bairro de atuação'),
            const SizedBox(height: 8),
            TextFormField(
              controller: ctrl.neighborhoodCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Ex: Centro, Vila Nova...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Informe o bairro'
                      : null,
            ),

            const SizedBox(height: 24),

            // ── Galeria ────────────────────────────────────────────────────
            _SectionTitle(title: 'Galeria de trabalhos'),
            const SizedBox(height: 4),
            const Text(
              'Máximo 6 fotos. Toque no × para remover.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildGalleryEditor(ctrl),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Foto de perfil ───────────────────────────────────────────────────────

  Widget _buildProfilePhotoEditor(WorkerProfileController ctrl) {
    return Center(
      child: Obx(() {
        final w = ctrl.worker.value;
        return Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.border,
              child: w?.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: w!.photoUrl!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator.adaptive(),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 55,
                            color: AppColors.textHint),
                      ),
                    )
                  : const Icon(Icons.person,
                      size: 55, color: AppColors.textHint),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: ctrl.pickProfilePhoto,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─── Disponibilidade ──────────────────────────────────────────────────────

  Widget _buildAvailabilitySwitch(WorkerProfileController ctrl) {
    return Obx(() => Card(
          child: SwitchListTile.adaptive(
            value: ctrl.isAvailable.value,
            onChanged: ctrl.toggleAvailability,
            activeColor: AppColors.primary,
            title: Text(
              ctrl.isAvailable.value
                  ? 'Estou disponível para serviços'
                  : 'Estou indisponível no momento',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              ctrl.isAvailable.value
                  ? 'Você aparece nas buscas dos clientes.'
                  : 'Você não aparece nas buscas.',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            secondary: Icon(
              ctrl.isAvailable.value
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              color: ctrl.isAvailable.value
                  ? AppColors.success
                  : AppColors.textHint,
            ),
          ),
        ));
  }

  // ─── Categorias ───────────────────────────────────────────────────────────

  Widget _buildCategorySelector(WorkerProfileController ctrl) {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kWorkerCategories.map((String cat) {
            final selected = ctrl.selectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => ctrl.toggleCategory(cat),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : AppColors.border,
              ),
            );
          }).toList(),
        ));
  }

  // ─── Galeria ──────────────────────────────────────────────────────────────

  Widget _buildGalleryEditor(WorkerProfileController ctrl) {
    return Obx(() {
      final existingUrls = (ctrl.worker.value?.portfolioUrls ?? [])
          .where((u) => !ctrl.removedPortfolioUrls.contains(u))
          .toList();
      final newFiles = ctrl.newPortfolioFiles;
      final canAdd = ctrl.currentPortfolioCount < 6;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: existingUrls.length + newFiles.length + (canAdd ? 1 : 0),
        itemBuilder: (_, i) {
          // Botão de adicionar
          if (i == existingUrls.length + newFiles.length) {
            return _addPhotoButton(ctrl);
          }
          // Fotos existentes
          if (i < existingUrls.length) {
            return _photoTileExisting(existingUrls[i], ctrl);
          }
          // Fotos novas
          final file = newFiles[i - existingUrls.length];
          return _photoTileNew(file, ctrl);
        },
      );
    });
  }

  Widget _addPhotoButton(WorkerProfileController ctrl) {
    return GestureDetector(
      onTap: ctrl.addPortfolioPhoto,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.primary, style: BorderStyle.solid, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 28),
            SizedBox(height: 4),
            Text('Adicionar',
                style:
                    TextStyle(fontSize: 11, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _photoTileExisting(String url, WorkerProfileController ctrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.border),
            errorWidget: (_, __, ___) => Container(
                color: AppColors.border,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textHint)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => ctrl.removeExistingPortfolioPhoto(url),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoTileNew(File file, WorkerProfileController ctrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        // Badge "novo"
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Novo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => ctrl.removeNewPortfolioPhoto(file),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget auxiliar de título de seção ───────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }
}
