import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';

// ─── Filtros de busca ────────────────────────────────────────────────────────
class WorkerFilters {
  final double maxDistanceKm;
  final double maxPricePerHour;
  final bool onlyVerified;
  final String sortBy; // 'rating' | 'price' | 'distance'

  const WorkerFilters({
    this.maxDistanceKm   = 50,
    this.maxPricePerHour = 500,
    this.onlyVerified    = false,
    this.sortBy          = 'rating',
  });

  WorkerFilters copyWith({
    double? maxDistanceKm,
    double? maxPricePerHour,
    bool? onlyVerified,
    String? sortBy,
  }) => WorkerFilters(
    maxDistanceKm:   maxDistanceKm   ?? this.maxDistanceKm,
    maxPricePerHour: maxPricePerHour ?? this.maxPricePerHour,
    onlyVerified:    onlyVerified    ?? this.onlyVerified,
    sortBy:          sortBy          ?? this.sortBy,
  );
}

class ClientController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─── Usuário ──────────────────────────────────────────────────────────────
  final currentUser       = Rxn<UserModel>();
  final isLoadingUser     = true.obs;

  // ─── Workers ──────────────────────────────────────────────────────────────
  final allWorkers        = <WorkerModel>[].obs;
  final filteredWorkers   = <WorkerModel>[].obs;
  final hasActiveFilters  = false.obs;
  final isLoadingWorkers  = true.obs;

  // ─── Busca / filtros ──────────────────────────────────────────────────────
  final searchQuery       = ''.obs;
  final selectedCategory  = ''.obs;
  final filters           = const WorkerFilters().obs;

  // ─── Localização ─────────────────────────────────────────────────────────
  final userLat           = 0.0.obs;
  final userLng           = 0.0.obs;
  final locationGranted   = false.obs;

  // ─── Pedidos ──────────────────────────────────────────────────────────────
  final myOrders          = <OrderModel>[].obs;
  final isLoadingOrders   = true.obs;

  // ─── Notificações ─────────────────────────────────────────────────────────
  final notificationCount = 0.obs;

  StreamSubscription? _workersSub;
  StreamSubscription? _ordersSub;

  // ─── Categorias da imagem de referência ───────────────────────────────────
  static const categories = [
    ('Eletricista',       '⚡'),
    ('Encanador',         '🔧'),
    ('Pintor',            '🎨'),
    ('Pedreiro',          '🏗️'),
    ('Jardineiro',        '🌿'),
    ('Diarista',          '🧹'),
    ('Montador de Móveis','🪑'),
    ('Ar-condicionado',   '❄️'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _startWorkersStream();
    _startOrdersStream();
    _requestLocation();

    // Reaplica filtros automaticamente
    ever(allWorkers,      (_) => _applyFilters());
    ever(searchQuery,     (_) => _applyFilters());
    ever(selectedCategory,(_) => _applyFilters());
    ever(filters,         (_) => _applyFilters());
    ever(locationGranted, (_) => _applyFilters());
  }

  @override
  void onClose() {
    _workersSub?.cancel();
    _ordersSub?.cancel();
    super.onClose();
  }

  // ─── Carregamento ─────────────────────────────────────────────────────────
  Future<void> reload() async {
    await _loadUser();
    _startWorkersStream();
  }

  Future<void> _loadUser() async {
    isLoadingUser.value = true;
    try {
      final u = await _ds.getUser(_fb.uid);
      currentUser.value = u;
    } catch (_) {
    } finally {
      isLoadingUser.value = false;
    }
  }

  void _startWorkersStream() {
    isLoadingWorkers.value = true;
    _workersSub?.cancel();
    _workersSub = _ds.watchAvailableWorkers().listen(
      (list) {
        allWorkers.assignAll(list);
        isLoadingWorkers.value = false;
      },
      onError: (_) => isLoadingWorkers.value = false,
    );
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

  // ─── Filtros ──────────────────────────────────────────────────────────────
  void _applyFilters() {
    var list = List<WorkerModel>.from(allWorkers);
    final q   = searchQuery.value.toLowerCase().trim();
    final cat = selectedCategory.value;
    final f   = filters.value;

    if (q.isNotEmpty) {
      list = list.where((w) =>
          w.name.toLowerCase().contains(q) ||
          w.categories.any((c) => c.toLowerCase().contains(q)) ||
          w.description.toLowerCase().contains(q)).toList();
    }

    if (cat.isNotEmpty) {
      list = list.where((w) => w.categories
          .any((c) => c.toLowerCase().contains(cat.toLowerCase()))).toList();
    }

    if (f.onlyVerified) {
      list = list.where((w) => w.isVerified).toList();
    }

    list = list.where((w) => w.pricePerHour <= f.maxPricePerHour).toList();

    if (locationGranted.value) {
      list = list.where((w) {
        final d = distanceToWorker(w);
        return d <= f.maxDistanceKm;
      }).toList();
    }

    switch (f.sortBy) {
      case 'rating':
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case 'price':
        list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case 'distance':
        if (locationGranted.value) {
          list.sort((a, b) =>
              distanceToWorker(a).compareTo(distanceToWorker(b)));
        }
        break;
    }

    filteredWorkers.assignAll(list);
    hasActiveFilters.value = f.maxDistanceKm < 50 ||
        f.maxPricePerHour < 500 ||
        f.onlyVerified ||
        f.sortBy != 'rating';
  }

  double distanceToWorker(WorkerModel w) {
    if (!locationGranted.value) return 0;
    return _distanceKm(
        userLat.value, userLng.value, w.address.lat, w.address.lng);
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  // ─── Ações ────────────────────────────────────────────────────────────────
  void onSearch(String v) => searchQuery.value = v;

  void selectCategory(String cat) {
    selectedCategory.value = selectedCategory.value == cat ? '' : cat;
  }

  void applyFilters(WorkerFilters f) => filters.value = f;
  void resetFilters() {
    filters.value = const WorkerFilters();
    searchQuery.value = '';
    selectedCategory.value = '';
  }

  void goToWorkerProfile(WorkerModel w) =>
      Get.toNamed(AppRoutes.workerProfile, arguments: w);

  void goToOrders() => Get.toNamed(AppRoutes.myOrders);

  void goToChats() => Get.toNamed(AppRoutes.chatsList);

  void goToProfile() => Get.toNamed(AppRoutes.clientProfile);

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
