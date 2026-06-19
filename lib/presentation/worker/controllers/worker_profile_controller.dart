import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/worker_model.dart';
import '../../orders/controllers/order_controller.dart';
import '../../orders/screens/request_service_sheet.dart';

/// Categorias de serviço disponíveis no app.
const List<String> kWorkerCategories = [
  'Limpeza',
  'Elétrica',
  'Hidráulica',
  'Pintura',
  'Jardinagem',
  'Montagem',
  'Reformas',
  'Mudanças',
  'Cuidados',
  'Tecnologia',
];

class WorkerProfileController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final _picker = ImagePicker();

  // ── Estado ────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  final worker = Rxn<WorkerModel>();
  final reviews = <ReviewModel>[].obs;

  // Edit profile
  final isAvailable = true.obs;
  final selectedCategories = <String>[].obs;
  final newPortfolioFiles = <File>[].obs;
  final removedPortfolioUrls = <String>[].obs;

  // Form
  final formKey = GlobalKey<FormState>();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is WorkerModel) {
      worker.value = args;
      _loadReviews(args.id);
    } else if (args is String) {
      loadWorker(args);
    }
  }

  @override
  void onClose() {
    descriptionCtrl.dispose();
    priceCtrl.dispose();
    neighborhoodCtrl.dispose();
    super.onClose();
  }

  // ── Carregamento ──────────────────────────────────────────────────────────

  Future<void> loadWorker(String workerId) async {
    isLoading.value = true;
    try {
      final w = await _ds.getWorker(workerId);
      if (w != null) {
        worker.value = w;
        _loadReviews(w.id);
      }
    } catch (_) {
      errorMessage.value = 'Erro ao carregar perfil.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadReviews(String workerId) async {
    try {
      _ds.watchReviews(workerId).listen((list) {
        reviews.assignAll(list.take(5));
      });
    } catch (_) {}
  }

  // ── Preparar edição ───────────────────────────────────────────────────────

  void prepareEdit() {
    final w = worker.value;
    if (w == null) return;
    descriptionCtrl.text = w.description;
    priceCtrl.text = w.pricePerHour.toStringAsFixed(2);
    neighborhoodCtrl.text = w.neighborhood;
    isAvailable.value = w.isAvailable;
    selectedCategories.assignAll(w.categories);
    newPortfolioFiles.clear();
    removedPortfolioUrls.clear();
  }

  // ── Foto de perfil ────────────────────────────────────────────────────────

  Future<void> pickProfilePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile == null) return;

    isSaving.value = true;
    try {
      final url = await CloudinaryService.upload(
        File(xFile.path),
        folder: 'workers/${worker.value!.id}/profile',
      );
      if (url.isEmpty) {
        Get.snackbar('Upload desabilitado',
            'Configure o Cloudinary para enviar fotos.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await _ds.updateWorker(worker.value!.id, {'photoUrl': url});
      worker.value = worker.value!.copyWith(photoUrl: url);
      Get.snackbar('Foto atualizada', 'Sua foto de perfil foi salva.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível salvar a foto.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Portfolio ─────────────────────────────────────────────────────────────

  Future<void> addPortfolioPhoto() async {
    if (currentPortfolioCount >= 6) {
      Get.snackbar('Limite atingido', 'Máximo de 6 fotos na galeria.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (xFile == null) return;
    newPortfolioFiles.add(File(xFile.path));
  }

  void removeExistingPortfolioPhoto(String url) =>
      removedPortfolioUrls.add(url);

  void removeNewPortfolioPhoto(File file) => newPortfolioFiles.remove(file);

  int get currentPortfolioCount {
    final existing = (worker.value?.portfolioUrls ?? [])
        .where((u) => !removedPortfolioUrls.contains(u))
        .length;
    return existing + newPortfolioFiles.length;
  }

  // ── Disponibilidade ───────────────────────────────────────────────────────

  Future<void> toggleAvailability(bool value) async {
    isAvailable.value = value;
    try {
      await _ds.updateWorker(worker.value!.id, {'isAvailable': value});
      worker.value = worker.value!.copyWith(isAvailable: value);
    } catch (_) {
      isAvailable.value = !value;
      Get.snackbar('Erro', 'Não foi possível atualizar disponibilidade.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ── Salvar perfil ─────────────────────────────────────────────────────────

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategories.isEmpty) {
      Get.snackbar('Atenção', 'Selecione ao menos uma categoria.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    try {
      final w = worker.value!;

      final uploadedUrls = <String>[];
      for (final file in newPortfolioFiles) {
        final url = await CloudinaryService.upload(
          file,
          folder: 'workers/${w.id}/portfolio',
        );
        if (url.isNotEmpty) uploadedUrls.add(url);
      }

      final finalPortfolio = [
        ...w.portfolioUrls.where((u) => !removedPortfolioUrls.contains(u)),
        ...uploadedUrls,
      ];

      final updates = <String, dynamic>{
        'description': descriptionCtrl.text.trim(),
        'pricePerHour': double.parse(priceCtrl.text.replaceAll(',', '.')),
        'neighborhood': neighborhoodCtrl.text.trim(),
        'isAvailable': isAvailable.value,
        'categories': selectedCategories.toList(),
        'portfolioUrls': finalPortfolio,
      };

      await _ds.updateWorker(w.id, updates);

      worker.value = w.copyWith(
        description: updates['description'] as String,
        pricePerHour: updates['pricePerHour'] as double,
        neighborhood: updates['neighborhood'] as String,
        isAvailable: updates['isAvailable'] as bool,
        categories: List<String>.from(updates['categories'] as List),
        portfolioUrls: List<String>.from(updates['portfolioUrls'] as List),
      );

      Get.back();
      Get.snackbar('Perfil atualizado', 'Suas informações foram salvas.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível salvar as alterações.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Navegação ─────────────────────────────────────────────────────────────

  void goToReport() {
    Get.toNamed(AppRoutes.report, arguments: {
      'targetId': worker.value?.id,
      'targetType': 'worker',
    });
  }

  void requestService() {
    if (worker.value == null) return;
    Get.lazyPut(() => OrderController(), fenix: true);
    Get.bottomSheet(
      RequestServiceSheet(worker: worker.value!),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }
}
