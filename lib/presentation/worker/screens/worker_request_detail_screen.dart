import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../widgets/service_route_map.dart';
import '../controllers/worker_controller.dart';
import 'worker_home_screen.dart' show WTheme;

/// Tela de nova solicitação (estilo 99).
///
/// Exibe apenas as informações essenciais do pedido — cliente, endereço,
/// categoria, descrição, fotos, distância e avaliação do cliente — com
/// SOMENTE duas ações possíveis:
///   • Aceitar → status accepted + abre imediatamente a
///     WorkerNavigationScreen
///   • Recusar → dispensa a solicitação e volta
class WorkerRequestDetailScreen extends StatefulWidget {
  const WorkerRequestDetailScreen({super.key});

  @override
  State<WorkerRequestDetailScreen> createState() =>
      _WorkerRequestDetailScreenState();
}

class _WorkerRequestDetailScreenState
    extends State<WorkerRequestDetailScreen> {
  late final WorkerController ctrl;
  OrderModel? order;

  double? distanceKm;
  double? _myLat;
  double? _myLng;
  double? _destLat;
  double? _destLng;
  double clientRating = 0;
  int clientReviews = 0;
  bool accepting = false;

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<WorkerController>()
        ? Get.find<WorkerController>()
        : Get.put(WorkerController());

    final args = Get.arguments;
    if (args is OrderModel) {
      order = args;
    } else if (args is Map) {
      order = Map<String, dynamic>.from(args)['order'] as OrderModel?;
    }

    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final o = order;
    if (o == null) return;

    // Avaliação do cliente
    try {
      final ds = Get.find<FirestoreDatasource>();
      final p = await ds.getClientPublicProfile(o.userId);
      if (mounted) {
        setState(() {
          clientRating = (p['rating'] as double?) ?? 0;
          clientReviews = (p['totalReviews'] as int?) ?? 0;
        });
      }
    } catch (_) {}

    // Coordenadas do destino: do pedido ou geocodificadas do endereço
    // (endereços via CEP chegavam com lat/lng = 0 e o mapa não aparecia)
    try {
      if (o.address.lat != 0 || o.address.lng != 0) {
        _destLat = o.address.lat;
        _destLng = o.address.lng;
      } else {
        final r =
            await GeocodingService.geocode(o.address.fullAddress);
        if (r != null) {
          _destLat = r.$1;
          _destLng = r.$2;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}

    // Distância até o local
    try {
      if (_destLat != null && _destLng != null) {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium));
        final meters = Geolocator.distanceBetween(pos.latitude,
            pos.longitude, _destLat!, _destLng!);
        if (mounted) {
          setState(() {
            distanceKm = meters / 1000;
            _myLat = pos.latitude;
            _myLng = pos.longitude;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _accept() async {
    final o = order;
    if (o == null || accepting) return;

    // REGRA DE NEGÓCIO: com um atendimento ATIVO, não é possível aceitar
    // outro imediatamente — apenas AGENDAR para depois.
    if (ctrl.hasActiveJob) {
      await _scheduleInstead(o);
      return;
    }

    setState(() => accepting = true);
    try {
      // Só abre a navegação se o aceite realmente funcionou
      final ok = await ctrl.acceptOrder(o, openNavigation: false);
      if (ok && mounted) {
        Get.offNamed(AppRoutes.workerNavigation,
            arguments: {'orderId': o.id});
      }
    } finally {
      if (mounted) setState(() => accepting = false);
    }
  }

  /// Agenda o trabalho: escolhe data/hora, aceita o pedido e grava o
  /// scheduledAt — SEM abrir a navegação (o atendimento atual continua).
  Future<void> _scheduleInstead(OrderModel o) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Agendar para quando?',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Horário do atendimento',
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    setState(() => accepting = true);
    try {
      final ok = await ctrl.acceptOrder(o,
          openNavigation: false, skipActiveGuard: true);
      if (!ok) return;
      final ds = Get.find<FirestoreDatasource>();
      await ds.scheduleOrder(o.id, scheduled);
      await ds.saveNotification(
        targetUserId: o.userId,
        title: 'Serviço agendado! 📅',
        body: 'Seu pedido de ${o.serviceCategory} foi agendado para '
            '${DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(scheduled)}.',
        type: 'order_update',
        targetId: o.id,
      );
      if (mounted) {
        Get.back();
        Get.snackbar('Trabalho agendado!',
            'Você pode iniciá-lo pela aba Aceitas na data marcada.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: WTheme.primary,
            colorText: Colors.white);
      }
    } finally {
      if (mounted) setState(() => accepting = false);
    }
  }

  void _refuse() {
    final o = order;
    if (o != null) ctrl.refuseOrder(o);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    if (o == null) {
      return const Scaffold(
        body: Center(child: Text('Solicitação não encontrada.')),
      );
    }

    return Scaffold(
      backgroundColor: WTheme.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [WTheme.primary, WTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(children: [
              const Row(children: [
                Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('Nova solicitação',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    (o.clientName?.isNotEmpty == true
                            ? o.clientName![0]
                            : 'C')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.clientName ?? 'Cliente',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        if (clientReviews > 0) ...[
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                              '${clientRating.toStringAsFixed(1)} '
                              '($clientReviews)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                        ],
                        if (distanceKm != null)
                          Text(
                              '${distanceKm!.toStringAsFixed(1)} km de você',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(o.serviceCategory,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),

          // ── Conteúdo ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Mapa do local (substitui o layout só-texto; o
                //    endereço vira informação complementar abaixo) ─────────
                if (_destLat != null && _destLng != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: IgnorePointer(
                        // preview estático — interação fica para a
                        // tela de navegação após o aceite
                        child: ServiceRouteMap(
                          workerLat: _myLat ?? 0,
                          workerLng: _myLng ?? 0,
                          clientLat: _destLat!,
                          clientLng: _destLng!,
                          hasWorkerPosition:
                              _myLat != null && _myLng != null,
                          accentColor: WTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _InfoCard(
                  icon: Icons.location_on_rounded,
                  iconColor: WTheme.red,
                  title: 'Endereço do serviço',
                  child: Text(o.address.fullAddress,
                      style: const TextStyle(
                          fontSize: 14, height: 1.4)),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.description_rounded,
                  iconColor: WTheme.primary,
                  title: 'Descrição do problema',
                  child: Text(
                      o.description.isEmpty
                          ? 'Sem descrição.'
                          : o.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.45)),
                ),
                if (o.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF6A1B9A),
                    title: 'Fotos anexadas',
                    child: SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: o.photoUrls.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: o.photoUrls[i],
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 90, color: WTheme.border),
                            errorWidget: (_, __, ___) => Container(
                              width: 90,
                              color: WTheme.border,
                              child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: WTheme.textLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ]),
      ),

      // ── APENAS Aceitar / Recusar ─────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  foregroundColor: WTheme.red,
                  side: const BorderSide(color: WTheme.red, width: 1.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: accepting ? null : _refuse,
                child: const Text('Recusar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WTheme.primary,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: accepting ? null : _accept,
                child: accepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(
                                Colors.white)))
                    : Text(
                        ctrl.hasActiveJob ? 'Agendar' : 'Aceitar',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WTheme.border),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: WTheme.textDark)),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
