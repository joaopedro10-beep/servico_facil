import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/financial_record_model.dart';
import '../../../data/models/order_model.dart';

/// Controller do atendimento em andamento (estilo 99 Motorista).
///
/// Responsável por:
///  • acompanhar o pedido em tempo real (Firestore = única fonte de verdade);
///  • posição do prestador, distância e ETA até o cliente;
///  • transições de status via botão deslizante:
///      accepted → arrived → inProgress → completed
///  • cronômetro baseado EXCLUSIVAMENTE em startedAt (serverTimestamp) —
///    nunca no relógio local como origem: fechar e reabrir o app não
///    afeta a contagem;
///  • ganhos ao vivo (bruto, comissão, líquido) com hourlyRate da coleção
///    `categories` e platformFeePercent das configurações globais.
///
/// Nenhum cálculo financeiro acontece na UI — tudo aqui e no datasource.
class WorkerNavigationController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ── Estado do pedido ──────────────────────────────────────────────────────
  final order = Rxn<OrderModel>();
  final isWorking = false.obs; // ação de slide em andamento

  // ── Cliente ───────────────────────────────────────────────────────────────
  final clientPhone = ''.obs;
  final clientRating = 0.0.obs;
  final clientReviews = 0.obs;

  // ── Precificação (carregada do Firestore, nunca fixa no código) ──────────
  final hourlyRate = 0.0.obs;
  final feePercent = 15.0.obs;
  final pricingLoaded = false.obs;
  // Origem do valor/hora: 'category' | 'settingsDefault' | 'fallback' |
  // 'order' (snapshot já congelado no pedido)
  final pricingSource = ''.obs;
  bool _warnedMissingCategory = false;

  // ── Localização / rota ────────────────────────────────────────────────────
  final workerLat = 0.0.obs;
  final workerLng = 0.0.obs;
  final hasWorkerPosition = false.obs;

  // ── Cronômetro / ganhos ao vivo ───────────────────────────────────────────
  final elapsed = Duration.zero.obs;

  StreamSubscription? _orderSub;
  StreamSubscription<Position>? _posSub;
  Timer? _ticker;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Aceita OrderModel, String (orderId) ou Map — mesmo padrão robusto
    // usado nas demais telas do app.
    final args = Get.arguments;
    String? orderId;
    if (args is OrderModel) {
      order.value = args;
      orderId = args.id;
    } else if (args is String) {
      orderId = args;
    } else if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      final o = map['order'] as OrderModel?;
      order.value = o;
      orderId = map['orderId'] as String? ?? o?.id;
    }

    if (orderId == null || orderId.isEmpty) return;

    _watchOrder(orderId);
    _startLocation();
    _startTicker();
  }

  @override
  void onClose() {
    _orderSub?.cancel();
    _posSub?.cancel();
    _ticker?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pedido em tempo real
  // ─────────────────────────────────────────────────────────────────────────

  void _watchOrder(String orderId) {
    _orderSub = _ds.watchOrder(orderId).listen((o) {
      final firstLoad = order.value == null;
      order.value = o;
      if (o == null) return;
      if (firstLoad || !pricingLoaded.value) _loadPricingAndClient(o);
    });
  }

  Future<void> _loadPricingAndClient(OrderModel o) async {
    // Se o pedido já congelou o snapshot financeiro (serviço iniciado),
    // usa os valores acordados; senão resolve pela configuração atual.
    // IMPORTANTE: a resolução é TOLERANTE e nunca lança — categoria não
    // cadastrada não pode travar o atendimento (usa default do admin ou
    // fallback, com aviso ao prestador).
    try {
      if (o.hourlyRate != null && o.hourlyRate! > 0) {
        hourlyRate.value = o.hourlyRate!;
        pricingSource.value = 'order';
      } else {
        final (rate, source) =
            await _ds.resolveCategoryHourlyRate(o.serviceCategory);
        hourlyRate.value = rate;
        pricingSource.value = source;

        // Aviso único (não bloqueante) quando a categoria não está
        // cadastrada em `categories` — o serviço segue com o valor padrão.
        if (source != 'category' && !_warnedMissingCategory) {
          _warnedMissingCategory = true;
          Get.snackbar(
            'Categoria sem valor cadastrado',
            'A categoria "${o.serviceCategory}" não tem valor/hora na '
                'coleção "categories" do Firestore. Usando '
                'R\$ ${rate.toStringAsFixed(2)}/h '
                '${source == 'settingsDefault' ? '(padrão do admin)' : '(padrão do sistema)'}. '
                'Peça ao administrador para cadastrá-la.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFF9A825),
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
          );
        }
      }

      if (o.platformFeePercent != null) {
        feePercent.value = o.platformFeePercent!;
      } else {
        feePercent.value = await _ds.getPlatformFeePercent();
      }
      pricingLoaded.value = true;
    } catch (_) {
      // Mesmo em erro inesperado, não trava o fluxo: mantém defaults
      // (hourlyRate 60 / fee 15) e segue.
      if (hourlyRate.value <= 0) hourlyRate.value = 60.0;
      pricingLoaded.value = true;
      pricingSource.value = 'fallback';
    }

    // Perfil público do cliente (telefone p/ WhatsApp, avaliação)
    try {
      final p = await _ds.getClientPublicProfile(o.userId);
      clientPhone.value = (p['phone'] ?? '') as String;
      clientRating.value = (p['rating'] as double?) ?? 0;
      clientReviews.value = (p['totalReviews'] as int?) ?? 0;
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Localização / distância / ETA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high));
      _setPosition(pos);

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25, // atualiza a cada ~25m
        ),
      ).listen(_setPosition);
    } catch (_) {}
  }

  void _setPosition(Position pos) {
    workerLat.value = pos.latitude;
    workerLng.value = pos.longitude;
    hasWorkerPosition.value = true;
  }

  bool get hasDestination {
    final a = order.value?.address;
    return a != null && (a.lat != 0 || a.lng != 0);
  }

  /// Distância em km até o cliente (Haversine).
  double get distanceKm {
    final o = order.value;
    if (o == null || !hasWorkerPosition.value || !hasDestination) return 0;
    return _haversineKm(
        workerLat.value, workerLng.value, o.address.lat, o.address.lng);
  }

  /// ETA estimado assumindo deslocamento urbano médio de 30 km/h.
  int get etaMinutes {
    final km = distanceKm;
    if (km <= 0) return 0;
    return max(1, (km / 30.0 * 60).round());
  }

  double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;

  // ─────────────────────────────────────────────────────────────────────────
  // Cronômetro (fonte de verdade: startedAt serverTimestamp)
  // ─────────────────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final o = order.value;
      if (o == null ||
          o.status != OrderStatus.inProgress ||
          o.startedAt == null) {
        if (elapsed.value != Duration.zero &&
            o?.status != OrderStatus.inProgress) {
          elapsed.value = Duration.zero;
        }
        return;
      }
      // Sempre recalculado a partir de startedAt — fechar e reabrir o app
      // não afeta a contagem.
      final diff = DateTime.now().difference(o.startedAt!);
      elapsed.value = diff.isNegative ? Duration.zero : diff;
    });
  }

  // ── Ganhos ao vivo (derivados, nunca calculados na UI) ───────────────────
  double get grossNow =>
      (elapsed.value.inSeconds / 3600.0) * hourlyRate.value;
  double get feeNow => grossNow * feePercent.value / 100.0;
  double get netNow => grossNow - feeNow;

  String get elapsedLabel {
    final d = elapsed.value;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Transições de status (botão deslizante)
  // accepted → arrived → inProgress → completed
  // ─────────────────────────────────────────────────────────────────────────

  String get slideLabel {
    switch (order.value?.status) {
      case OrderStatus.accepted:
        return 'Arraste para informar chegada ao cliente';
      case OrderStatus.arrived:
        return 'Arraste para iniciar o serviço';
      case OrderStatus.inProgress:
        return 'Arraste para finalizar o serviço';
      default:
        return '';
    }
  }

  /// Ação do slide conforme o status atual.
  Future<void> onSlideConfirmed() async {
    final o = order.value;
    if (o == null) return;
    isWorking.value = true;
    try {
      switch (o.status) {
        case OrderStatus.accepted:
          await _confirmArrival(o);
          break;
        case OrderStatus.arrived:
          await _startService(o);
          break;
        case OrderStatus.inProgress:
          await _finishService(o);
          break;
        default:
          break;
      }
    } on ValidationException catch (e) {
      Get.snackbar('Atenção', e.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFF9A825),
          colorText: Colors.white);
    } catch (e) {
      // Diagnóstico claro: a causa mais comum de falha na troca de status
      // é o Firestore com regras antigas (sem a transição 'arrived' e sem
      // os campos financeiros liberados). As regras v6 corrigem isso.
      final msg = e.toString().contains('permission-denied')
          ? 'Permissão negada pelo Firestore. Publique as regras '
              'atualizadas (v6) que liberam as transições do novo fluxo '
              '(arrived, campos financeiros).'
          : 'Não foi possível atualizar o serviço. Verifique sua conexão.';
      Get.snackbar('Erro', msg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: Colors.white,
          duration: const Duration(seconds: 6));
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> _confirmArrival(OrderModel o) async {
    await _ds.markArrived(o.id);
    await _ds.saveNotification(
      targetUserId: o.userId,
      title: 'O profissional chegou! 📍',
      body:
          '${o.workerName ?? 'O profissional'} chegou ao local do serviço.',
      type: 'order_update',
      targetId: o.id,
    );
  }

  Future<void> _startService(OrderModel o) async {
    // Garante a precificação carregada — a resolução é tolerante e nunca
    // lança; na pior hipótese usa o default com aviso (fluxo não trava).
    if (!pricingLoaded.value) {
      await _loadPricingAndClient(o);
    }
    if (hourlyRate.value <= 0) hourlyRate.value = 60.0;

    await _ds.startServiceTimer(
      o.id,
      hourlyRate: hourlyRate.value,
      platformFeePercent: feePercent.value,
    );
    await _ds.saveNotification(
      targetUserId: o.userId,
      title: 'Serviço iniciado! 🔧',
      body: 'O serviço de ${o.serviceCategory} está em execução. '
          'Cobrança: R\$ ${hourlyRate.value.toStringAsFixed(2)}/hora.',
      type: 'order_update',
      targetId: o.id,
    );
  }

  Future<void> _finishService(OrderModel o) async {
    final record = await _ds.finishServiceAndSettle(o.id);

    await _ds.saveNotification(
      targetUserId: o.userId,
      title: 'Serviço finalizado! ✅',
      body: 'Duração: ${record.durationLabel} · '
          'Total: R\$ ${record.grossAmount.toStringAsFixed(2)}. '
          'Que tal avaliar o profissional?',
      type: 'order_update',
      targetId: o.id,
    );

    _showSummary(record);
  }

  /// Resumo financeiro exibido ao prestador após a conclusão.
  void _showSummary(FinancialRecordModel r) {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle_rounded,
              color: Color(0xFF1D9E75), size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Serviço concluído!')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _summaryLine('Tempo trabalhado', r.durationLabel),
          _summaryLine('Valor bruto',
              'R\$ ${r.grossAmount.toStringAsFixed(2)}'),
          _summaryLine(
              'Comissão (${r.platformFeePercent.toStringAsFixed(0)}%)',
              '- R\$ ${r.platformFeeAmount.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _summaryLine('Você recebe',
              'R\$ ${r.netAmount.toStringAsFixed(2)}',
              bold: true),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Get.back(); // fecha o diálogo
                Get.offAllNamed(AppRoutes.workerHome);
              },
              child: const Text('Voltar ao início',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w400))),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 18 : 13,
                color: bold ? const Color(0xFF1D9E75) : Colors.black87,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Contato com o cliente
  // ─────────────────────────────────────────────────────────────────────────

  String get _digitsPhone =>
      clientPhone.value.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> openWhatsApp() async {
    final phone = _digitsPhone;
    if (phone.isEmpty) {
      Get.snackbar('Sem telefone',
          'O cliente não cadastrou um número de telefone.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    final intl = phone.startsWith('55') ? phone : '55$phone';
    final uri = Uri.parse('https://wa.me/$intl');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> callClient() async {
    final phone = _digitsPhone;
    if (phone.isEmpty) {
      Get.snackbar('Sem telefone',
          'O cliente não cadastrou um número de telefone.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void openChat() {
    final o = order.value;
    if (o == null) return;
    Get.toNamed(AppRoutes.chat, arguments: o.id);
  }
}
