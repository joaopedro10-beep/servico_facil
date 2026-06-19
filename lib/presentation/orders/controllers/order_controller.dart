import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/worker_model.dart';

class OrderController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();
  final _picker = ImagePicker();

  // ── Estado geral ──────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isSaving = false.obs;

  // ── Request Sheet ─────────────────────────────────────────────────────────
  final sheetPhotos = <File>[].obs;
  final sheetAddress = Rxn<UserAddress>();
  final sheetScheduledAt = Rxn<DateTime>();
  final descriptionCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final sheetFormKey = GlobalKey<FormState>();
  final isLoadingLocation = false.obs;

  // ── Order Detail ──────────────────────────────────────────────────────────
  final currentOrder = Rxn<OrderModel>();
  StreamSubscription? _orderSub;

  // ── My Orders ─────────────────────────────────────────────────────────────
  final clientOrders = <OrderModel>[].obs;
  final workerOrders = <OrderModel>[].obs;
  final isLoadingOrders = true.obs;
  StreamSubscription? _clientOrdersSub;
  StreamSubscription? _workerOrdersSub;

  // Tab ativo em MyOrders: 0 = Ativos, 1 = Histórico
  final myOrdersTab = 0.obs;

  // Filtro de status em MyOrders
  final selectedStatusFilter = Rxn<OrderStatus>();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _orderSub?.cancel();
    _clientOrdersSub?.cancel();
    _workerOrdersSub?.cancel();
    descriptionCtrl.dispose();
    addressCtrl.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REQUEST SHEET
  // ─────────────────────────────────────────────────────────────────────────

  void resetSheet() {
    sheetPhotos.clear();
    sheetAddress.value = null;
    sheetScheduledAt.value = null;
    descriptionCtrl.clear();
    addressCtrl.clear();
  }

  Future<void> pickSheetPhoto() async {
    if (sheetPhotos.length >= 3) {
      Get.snackbar('Limite atingido', 'Máximo de 3 fotos por solicitação.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (xFile != null) sheetPhotos.add(File(xFile.path));
  }

  void removeSheetPhoto(int index) => sheetPhotos.removeAt(index);

  Future<void> pickCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        Get.snackbar('Permissão negada',
            'Habilite a localização nas configurações.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      sheetAddress.value = UserAddress(
        street: 'Localização atual',
        city: '',
        state: '',
        lat: pos.latitude,
        lng: pos.longitude,
      );
      addressCtrl.text = 'Localização atual (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível obter a localização.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('pt', 'BR'),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null) return;

    sheetScheduledAt.value =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> submitRequest(WorkerModel worker) async {
    if (!sheetFormKey.currentState!.validate()) return;
    if (sheetScheduledAt.value == null) {
      Get.snackbar('Atenção', 'Selecione a data e hora desejada.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (sheetAddress.value == null && addressCtrl.text.trim().isEmpty) {
      Get.snackbar('Atenção', 'Informe o endereço do serviço.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    try {
      final uid = _fb.uid;

      // Upload das fotos para Cloudinary (retorna [] se não configurado)
      final rawUrls = await CloudinaryService.uploadAll(
        sheetPhotos,
        folder: 'orders/$uid/${DateTime.now().millisecondsSinceEpoch}',
      );
      final photoUrls = rawUrls.where((u) => u.isNotEmpty).toList();

      final address = sheetAddress.value ??
          UserAddress(
            street: addressCtrl.text.trim(),
            city: '',
            state: '',
            lat: 0,
            lng: 0,
          );

      final order = await _ds.createOrder(OrderModel(
        id: '',
        userId: uid,
        workerId: worker.id,
        serviceCategory: worker.categories.isNotEmpty
            ? worker.categories.first
            : 'Geral',
        description: descriptionCtrl.text.trim(),
        photoUrls: photoUrls,
        scheduledAt: sheetScheduledAt.value!,
        address: address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workerName: worker.name,
      ));

      // Notificação para o trabalhador
      await _ds.saveNotification(
        targetUserId: worker.id,
        title: 'Nova solicitação de serviço!',
        body:
            'Você recebeu uma solicitação de ${order.serviceCategory}.',
        type: 'new_order',
        targetId: order.id,
      );

      Get.back(); // fecha o bottom sheet
      resetSheet();

      Get.snackbar(
        'Solicitação enviada!',
        'Aguarde a confirmação do profissional.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Vai para o detalhe do pedido recém-criado
      Get.toNamed(AppRoutes.orderDetail,
          arguments: {'order': order, 'isWorker': false});
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível enviar a solicitação.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ORDER DETAIL
  // ─────────────────────────────────────────────────────────────────────────

  void watchOrder(String orderId) {
    _orderSub?.cancel();
    _orderSub = _ds.watchOrder(orderId).listen((o) => currentOrder.value = o);
  }

  Future<void> cancelOrder() async {
    final order = currentOrder.value;
    if (order == null) return;
    isSaving.value = true;
    try {
      await _ds.updateOrderStatusWithTimestamp(
          order.id, OrderStatus.cancelled);

      await _ds.saveNotification(
        targetUserId: order.workerId,
        title: 'Pedido cancelado',
        body: 'O cliente cancelou a solicitação de ${order.serviceCategory}.',
        type: 'order_update',
        targetId: order.id,
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível cancelar.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> acceptOrder() => _changeStatus(
        OrderStatus.accepted,
        notifyUserId: currentOrder.value!.userId,
        notifyTitle: 'Pedido aceito!',
        notifyBody:
            'Seu pedido de ${currentOrder.value!.serviceCategory} foi aceito pelo profissional.',
      );

  Future<void> refuseOrder() => _changeStatus(
        OrderStatus.cancelled,
        notifyUserId: currentOrder.value!.userId,
        notifyTitle: 'Pedido recusado',
        notifyBody:
            'Infelizmente o profissional não pôde aceitar seu pedido agora.',
      );

  Future<void> startOrder() => _changeStatus(
        OrderStatus.inProgress,
        notifyUserId: currentOrder.value!.userId,
        notifyTitle: 'Serviço iniciado!',
        notifyBody:
            'O profissional iniciou o serviço de ${currentOrder.value!.serviceCategory}.',
      );

  Future<void> completeOrder() => _changeStatus(
        OrderStatus.done,
        notifyUserId: currentOrder.value!.userId,
        notifyTitle: 'Serviço concluído!',
        notifyBody:
            'Que tal avaliar o profissional? Sua opinião ajuda outros clientes.',
      );

  Future<void> _changeStatus(
    OrderStatus newStatus, {
    required String notifyUserId,
    required String notifyTitle,
    required String notifyBody,
  }) async {
    final order = currentOrder.value;
    if (order == null) return;
    isSaving.value = true;
    try {
      await _ds.updateOrderStatusWithTimestamp(order.id, newStatus);
      await _ds.saveNotification(
        targetUserId: notifyUserId,
        title: notifyTitle,
        body: notifyBody,
        type: 'order_update',
        targetId: order.id,
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível atualizar o pedido.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  void openChat(String orderId) {
    Get.toNamed(AppRoutes.chat, arguments: orderId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MY ORDERS
  // ─────────────────────────────────────────────────────────────────────────

  void loadClientOrders() {
    isLoadingOrders.value = true;
    _clientOrdersSub?.cancel();
    _clientOrdersSub = _ds.watchClientOrders(_fb.uid).listen((list) {
      clientOrders.assignAll(list);
      isLoadingOrders.value = false;
    }, onError: (_) => isLoadingOrders.value = false);
  }

  void loadWorkerOrders() {
    isLoadingOrders.value = true;
    _workerOrdersSub?.cancel();
    _workerOrdersSub = _ds.watchWorkerOrders(_fb.uid).listen((list) {
      workerOrders.assignAll(list);
      isLoadingOrders.value = false;
    }, onError: (_) => isLoadingOrders.value = false);
  }

  List<OrderModel> filteredOrdersFor({required bool isWorker}) {
    final all = isWorker ? workerOrders : clientOrders;
    final isActive = myOrdersTab.value == 0;

    var list = all.where((o) {
      return isActive ? o.isActive : !o.isActive;
    }).toList();

    final filter = selectedStatusFilter.value;
    if (filter != null) {
      list = list.where((o) => o.status == filter).toList();
    }

    return list;
  }
}
