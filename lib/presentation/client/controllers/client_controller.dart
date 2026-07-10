import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_address.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';

// ─── Categorias de serviço ────────────────────────────────────────────────────
class ServiceCategory {
  final String name;
  final IconData icon;
  const ServiceCategory(this.name, this.icon);
}

const serviceCategories = [
  ServiceCategory('Eletricista',        Icons.electrical_services_rounded),
  ServiceCategory('Encanador',          Icons.plumbing_rounded),
  ServiceCategory('Pintor',             Icons.format_paint_rounded),
  ServiceCategory('Pedreiro',           Icons.construction_rounded),
  ServiceCategory('Jardineiro',         Icons.park_rounded),
  ServiceCategory('Diarista',           Icons.cleaning_services_rounded),
  ServiceCategory('Montador de Móveis', Icons.chair_rounded),
  ServiceCategory('Ar-condicionado',    Icons.ac_unit_rounded),
  ServiceCategory('Chaveiro',           Icons.vpn_key_rounded),
  ServiceCategory('Mudança',            Icons.local_shipping_rounded),
];

// ─── Controller unificado do cliente ─────────────────────────────────────────
class ClientController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ── Usuário ───────────────────────────────────────────────────────────────
  final currentUser    = Rxn<UserModel>();
  final isLoadingUser  = true.obs;

  // ── Pedidos do cliente ────────────────────────────────────────────────────
  final myOrders        = <OrderModel>[].obs;
  final isLoadingOrders = true.obs;

  // ── Notificações badge ────────────────────────────────────────────────────
  final notificationCount = 0.obs;

  // ── Formulário de solicitação ─────────────────────────────────────────────
  final selectedCategory  = ''.obs;
  final isSubmitting      = false.obs;
  final submitError       = ''.obs;
  final submitSuccess     = false.obs;

  // Campos do formulário
  final descriptionCtrl  = TextEditingController();
  final scheduledDate    = Rxn<DateTime>();
  final photoFiles       = <File>[].obs;
  final serviceAddress   = Rxn<UserAddress>();

  // ── Localização ───────────────────────────────────────────────────────────
  final userLat         = 0.0.obs;
  final userLng         = 0.0.obs;
  final locationGranted = false.obs;

  StreamSubscription? _ordersSub;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _startOrdersStream();
    _requestLocation();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    descriptionCtrl.dispose();
    super.onClose();
  }

  // ─── Carregamento ─────────────────────────────────────────────────────────
  Future<void> reload() async => _loadUser();

  Future<void> _loadUser() async {
    isLoadingUser.value = true;
    try {
      final u = await _ds.getUser(_fb.uid);
      currentUser.value = u;
      // Usa endereço do perfil como padrão para o serviço
      if (u?.address.city.isNotEmpty == true) {
        serviceAddress.value = u!.address;
      }
    } catch (_) {
    } finally {
      isLoadingUser.value = false;
    }
  }

  void _startOrdersStream() {
    isLoadingOrders.value = true;
    _ordersSub = _ds.watchClientOrders(_fb.uid).listen(
          (list) {
        myOrders.assignAll(list);
        isLoadingOrders.value = false;
      },
      onError: (_) => isLoadingOrders.value = false,
    );
  }

  Future<void> _requestLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        userLat.value = pos.latitude;
        userLng.value = pos.longitude;
        locationGranted.value = true;
      }
    } catch (_) {}
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  String get firstName {
    final n = currentUser.value?.name ?? '';
    return n.isNotEmpty ? n.split(' ').first : 'Cliente';
  }

  String get nameInitial {
    final n = currentUser.value?.name ?? '';
    return n.isNotEmpty ? n[0].toUpperCase() : 'C';
  }

  List<OrderModel> get activeOrders => myOrders.where((o) =>
  o.status == OrderStatus.pending ||
      o.status == OrderStatus.accepted ||
      o.status == OrderStatus.inProgress).toList();

  List<OrderModel> get doneOrders =>
      myOrders.where((o) => o.status == OrderStatus.done).toList();

  OrderModel? get latestActiveOrder =>
      activeOrders.isNotEmpty ? activeOrders.first : null;

  // ─── Formulário de solicitação ────────────────────────────────────────────
  void selectCategory(String cat) {
    selectedCategory.value = cat;
    submitError.value = '';
    submitSuccess.value = false;
  }

  void clearForm() {
    selectedCategory.value = '';
    descriptionCtrl.clear();
    scheduledDate.value = null;
    photoFiles.clear();
    submitError.value = '';
    submitSuccess.value = false;
    serviceAddress.value = currentUser.value?.address;
  }

  Future<void> pickPhoto() async {
    if (photoFiles.length >= 3) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery,
          imageQuality: 70);
      if (picked != null) photoFiles.add(File(picked.path));
    } catch (_) {}
  }

  void removePhoto(int index) {
    if (index < photoFiles.length) photoFiles.removeAt(index);
  }

  // ─── Submeter solicitação ─────────────────────────────────────────────────
  // REGRA DE NEGÓCIO: o cliente NÃO escolhe um prestador.
  // A plataforma envia a solicitação e o primeiro prestador disponível
  // da categoria que aceitar é vinculado automaticamente.
  Future<void> submitRequest() async {
    if (selectedCategory.value.isEmpty) {
      submitError.value = 'Selecione uma categoria de serviço.';
      return;
    }
    if (descriptionCtrl.text.trim().isEmpty) {
      submitError.value = 'Descreva o serviço que precisa.';
      return;
    }
    if (scheduledDate.value == null) {
      submitError.value = 'Informe a data e horário desejado.';
      return;
    }
    if (serviceAddress.value == null ||
        serviceAddress.value!.city.isEmpty) {
      submitError.value = 'Informe o endereço do serviço.';
      return;
    }

    isSubmitting.value = true;
    submitError.value = '';

    try {
      final user = currentUser.value;
      final now  = DateTime.now();

      // Cria pedido sem workerId definido — ficará vazio até um
      // prestador aceitar (modelo pull: prestador escolhe aceitar)
      final order = OrderModel(
        id:              '',
        userId:          _fb.uid,
        workerId:        '', // vazio até aceite
        serviceCategory: selectedCategory.value,
        description:     descriptionCtrl.text.trim(),
        scheduledAt:     scheduledDate.value!,
        status:          OrderStatus.pending,
        address:         serviceAddress.value!,
        createdAt:       now,
        updatedAt:       now,
        clientName:      user?.name,
      );

      await _ds.createOrder(order);

      // Notifica prestadores disponíveis da categoria
      // (Cloud Function ou datasource faz o dispatch)
      await _ds.saveNotification(
        targetUserId: 'broadcast_${selectedCategory.value}',
        title:        'Nova solicitação de ${selectedCategory.value}',
        body:         descriptionCtrl.text.trim(),
        type:         'new_order',
        targetId:     selectedCategory.value,
      );

      submitSuccess.value = true;
      // NÃO chama clearForm() aqui — o formulário é limpo pelo botão
      // "Nova Solicitação" na tela de sucesso, para o usuário ver o sucesso
    } on FirebaseException catch (e) {
      submitError.value = 'Erro ao enviar: ${e.message}';
    } catch (e) {
      submitError.value = 'Erro inesperado. Tente novamente.';
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Cancelar pedido ──────────────────────────────────────────────────────
  Future<void> cancelOrder(OrderModel order) async {
    if (!order.canClientCancel) return;
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Cancelar solicitação'),
      content: const Text('Deseja cancelar esta solicitação?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false),
            child: const Text('Não')),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Sim, cancelar',
              style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
    if (ok != true) return;
    try {
      await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.cancelled);
    } catch (_) {}
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Sair da conta'),
      content: const Text('Tem certeza que deseja sair?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false),
            child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Sair',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
    if (ok != true) return;
    await Get.find<AuthRepositoryImpl>().signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
