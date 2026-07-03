import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/models/user_address.dart';

// ─── Modelo de filtros ────────────────────────────────────────────────────────

class WorkerFilters {
  final double maxDistanceKm;   // slider 1–50 km
  final double maxPricePerHour; // slider 0–500
  final bool onlyVerified;
  final SortBy sortBy;

  const WorkerFilters({
    this.maxDistanceKm = 50,
    this.maxPricePerHour = 500,
    this.onlyVerified = false,
    this.sortBy = SortBy.rating,
  });

  WorkerFilters copyWith({
    double? maxDistanceKm,
    double? maxPricePerHour,
    bool? onlyVerified,
    SortBy? sortBy,
  }) =>
      WorkerFilters(
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        maxPricePerHour: maxPricePerHour ?? this.maxPricePerHour,
        onlyVerified: onlyVerified ?? this.onlyVerified,
        sortBy: sortBy ?? this.sortBy,
      );
}

enum SortBy { rating, price, distance }

// ─── Controller ───────────────────────────────────────────────────────────────

class ClientHomeController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ── Estado ────────────────────────────────────────────────────────────────
  final isLoadingUser = true.obs;
  final currentUser = Rxn<UserModel>();
  final filteredWorkers = <WorkerModel>[].obs;
  final hasActiveFilters = false.obs;

  // Stream de workers do Firestore
  final allWorkers = <WorkerModel>[].obs;
  final isLoadingWorkers = true.obs;
  StreamSubscription? _workersSub;

  // Localização
  final userLat = 0.0.obs;
  final userLng = 0.0.obs;
  final locationGranted = false.obs;

  // Busca e filtros
  final searchQuery = ''.obs;
  final selectedCategory = ''.obs; // '' = todas
  final filters = const WorkerFilters().obs;

  // Notificações (badge)
  final notificationCount = 0.obs;

  // Resultado final após filtros


  // ── Lifecycle ─────────────────────────────────────────────────────────────


  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _startWorkersStream();
    _requestLocation();
    _loadNotificationCount();

    // Reaplica filtros automaticamente quando qualquer coisa muda
    ever(allWorkers, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedCategory, (_) => _applyFilters());
    ever(filters, (_) => _applyFilters());
    ever(locationGranted, (_) => _applyFilters());
  }

  @override
  void onClose() {
    _workersSub?.cancel();
    super.onClose();
  }

  // ── Dados do usuário ──────────────────────────────────────────────────────

  Future<void> _loadUser() async {
    try {
      final uid = _fb.uid;
      final user = await _ds.getUser(uid);
      currentUser.value = user;
    } catch (_) {} finally {
      isLoadingUser.value = false;
    }
  }

  String get firstName {
    final name = currentUser.value?.name ?? '';
    return name
        .split(' ')
        .first;
  }

  // ── Stream de workers ─────────────────────────────────────────────────────

  /// Public refresh — chamado pelo pull-to-refresh da tela
  void refresh() => _startWorkersStream();

  void _startWorkersStream() {
    isLoadingWorkers.value = true;
    _workersSub = _ds.watchAvailableWorkers().listen(
          (list) {
        allWorkers.assignAll(list);
        isLoadingWorkers.value = false;
      },
      onError: (_) => isLoadingWorkers.value = false,
    );
  }

  // ── Localização ───────────────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      userLat.value = pos.latitude;
      userLng.value = pos.longitude;
      locationGranted.value = true;
    } catch (_) {
      locationGranted.value = false;
    }
  }

  double distanceToWorker(WorkerModel w) {
    if (!locationGranted.value) return 0;
    return _distanceKm(
        userLat.value, userLng.value, w.address.lat, w.address.lng);
  }

  /// Fórmula de Haversine — retorna distância em km
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    if (lat2 == 0 && lng2 == 0) return 0; // worker sem localização cadastrada
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _rad(double deg) => deg * pi / 180;

  // ── Busca / filtros ───────────────────────────────────────────────────────

  void onSearch(String value) => searchQuery.value = value;

  void selectCategory(String category) {
    selectedCategory.value =
    selectedCategory.value == category ? '' : category;
  }

  void applyFilters(WorkerFilters newFilters) {
    filters.value = newFilters;
    Get.back();
  }

  void resetFilters() {
    filters.value = const WorkerFilters();
  }

  // ── Notificações ──────────────────────────────────────────────────────────

  Future<void> _loadNotificationCount() async {
    // Placeholder — será implementado no prompt de notificações
    notificationCount.value = 0;
  }


  void _applyFilters() {
    var list = List<WorkerModel>.from(allWorkers);

    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((w) {
        return w.name.toLowerCase().contains(q) ||
            w.categories.any((c) => c.toLowerCase().contains(q)) ||
            w.description.toLowerCase().contains(q);
      }).toList();
    }

    final cat = selectedCategory.value;
    if (cat.isNotEmpty) {
      list = list.where((w) => w.categories.contains(cat)).toList();
    }

    final f = filters.value;
    if (f.onlyVerified) {
      list = list.where((w) => w.isVerified).toList();
    }
    list = list.where((w) => w.pricePerHour <= f.maxPricePerHour).toList();

    if (locationGranted.value) {
      list = list.where((w) {
        final d = _distanceKm(
            userLat.value, userLng.value, w.address.lat, w.address.lng);
        return d <= f.maxDistanceKm;
      }).toList();
    }

    switch (f.sortBy) {
      case SortBy.rating:
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case SortBy.price:
        list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case SortBy.distance:
        if (locationGranted.value) {
          list.sort((a, b) {
            final da = _distanceKm(
                userLat.value, userLng.value, a.address.lat, a.address.lng);
            final db = _distanceKm(
                userLat.value, userLng.value, b.address.lat, b.address.lng);
            return da.compareTo(db);
          });
        }
        break;
    }

    filteredWorkers.assignAll(list);

    final activeF = filters.value;
    hasActiveFilters.value = activeF.maxDistanceKm < 50 ||
        activeF.maxPricePerHour < 500 ||
        activeF.onlyVerified ||
        activeF.sortBy != SortBy.rating;
  }
}