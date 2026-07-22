import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/financial_record_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';


class WorkerController extends GetxController {
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final FirebaseService _fb = Get.find<FirebaseService>();

  // ─── Estado geral ─────────────────────────────────────────────────────────
  final worker = Rxn<WorkerModel>();
  final isAvailable = true.obs;
  final isTogglingAvailability = false.obs;

  // ─── Pedidos ──────────────────────────────────────────────────────────────
  final allOrders        = <OrderModel>[].obs;
  final availableOrders  = <OrderModel>[].obs; // pedidos disponíveis na plataforma
  final isLoadingOrders  = true.obs;

  // ─── Avaliações ───────────────────────────────────────────────────────────
  final reviews = <ReviewModel>[].obs;

  // ─── Ganhos ───────────────────────────────────────────────────────────────
  final earningsPeriod = 'month'.obs; // 'today' | 'week' | 'month' | 'year'

  // ─── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription? _ordersSub;
  StreamSubscription? _availableOrdersSub;
  int _lastActiveCount = 0; // controle para evitar cascade de resubscriptions
  StreamSubscription? _reviewsSub;
  StreamSubscription? _financialSub;

  // ─── Registros financeiros (coleção financial_records) ────────────────────
  // Alimentados automaticamente ao finalizar cada serviço no fluxo 99.
  final financialRecords = <FinancialRecordModel>[].obs;

  // Pedidos disponíveis dispensados localmente pelo prestador (aba "Novas")
  final _dismissedOrderIds = <String>{}.obs;

  /// Motivo (legível) de a lista de novas solicitações estar vazia por
  /// bloqueio — exibido como banner na aba "Novas". Vazio = sem bloqueio.
  final availableBlockReason = ''.obs;

  // Controle do alerta de nova solicitação:
  // guarda os ids já conhecidos para notificar apenas pedidos que CHEGARAM
  // enquanto o app está aberto (evita spam no primeiro snapshot).
  final Set<String> _knownAvailableIds = {};
  bool _availableStreamPrimed = false;

  // ─── Computed: listas de pedidos por status ───────────────────────────────
  List<OrderModel> get newOrders =>
      allOrders.where((o) => o.status == OrderStatus.pending).toList();

  /// Solicitações que o prestador deve ver na aba "Novas":
  /// pedidos pendentes já vinculados a ele (workerId == uid) +
  /// pedidos disponíveis na plataforma (workerId == '') da sua categoria.
  ///
  /// CORREÇÃO: antes a UI exibia apenas [newOrders], mas pedidos criados
  /// pelo cliente nascem com workerId == '' — por isso o prestador nunca
  /// via as solicitações. Agora as duas fontes são combinadas (sem
  /// duplicatas e sem os pedidos dispensados localmente).
  List<OrderModel> get incomingOrders {
    final seen = <String>{};
    final list = <OrderModel>[];
    for (final o in [...newOrders, ...availableOrders]) {
      if (_dismissedOrderIds.contains(o.id)) continue;
      if (seen.add(o.id)) list.add(o);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<OrderModel> get acceptedOrders =>
      allOrders.where((o) => o.status == OrderStatus.accepted).toList();

  List<OrderModel> get inProgressOrders =>
      allOrders.where((o) => o.status == OrderStatus.inProgress).toList();

  List<OrderModel> get activeOrders => allOrders
      .where((o) =>
  o.status == OrderStatus.accepted ||
      o.status == OrderStatus.inProgress)
      .toList();

  /// Atendimento ATIVO agora (bloqueia novo aceite imediato):
  /// arrived, inProgress, ou accepted SEM agendamento.
  /// Pedidos aceitos COM scheduledAt são "agendados" — não contam como
  /// ativos, permitindo ao prestador agendar vários trabalhos futuros.
  bool get hasActiveJob => allOrders.any((o) =>
      o.status == OrderStatus.arrived ||
      o.status == OrderStatus.inProgress ||
      (o.status == OrderStatus.accepted && o.scheduledAt == null));

  List<OrderModel> get doneOrders =>
      allOrders.where((o) => o.status == OrderStatus.done).toList();

  List<OrderModel> get cancelledOrders =>
      allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

  // ─── Computed: dashboard stats ────────────────────────────────────────────
  int get todayOrders {
    final t = DateTime.now();
    return allOrders
        .where((o) =>
    o.createdAt.year == t.year &&
        o.createdAt.month == t.month &&
        o.createdAt.day == t.day)
        .length;
  }

  int get totalCompleted => doneOrders.length;

  double get avgRating => worker.value?.avgRating ?? 0.0;

  // ─── Computed: ganhos ─────────────────────────────────────────────────────
  List<OrderModel> get filteredEarnings {
    final done = doneOrders;
    final now = DateTime.now();
    switch (earningsPeriod.value) {
      case 'today':
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).toList();
      case 'week':
        return done
            .where((o) =>
        now.difference(o.completedAt ?? o.updatedAt).inDays <= 7)
            .toList();
      case 'year':
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year;
        }).toList();
      default: // month
        return done.where((o) {
          final d = o.completedAt ?? o.updatedAt;
          return d.year == now.year && d.month == now.month;
        }).toList();
    }
  }

  double get totalEarnings =>
      filteredEarnings.fold(0.0, (s, o) => s + (o.price ?? 0));

  /// Ganhos por mês (últimos 6 meses para o gráfico)
  List<double> get earningsByMonth {
    final now = DateTime.now();
    return List.generate(6, (i) {
      int m = now.month - (5 - i);
      int y = now.year;
      if (m <= 0) {
        m += 12;
        y--;
      }
      return doneOrders
          .where((o) {
        final d = o.completedAt ?? o.updatedAt;
        return d.year == y && d.month == m;
      })
          .fold(0.0, (s, o) => s + (o.price ?? 0));
    });
  }


  // ─── Stats completos para o Dashboard ────────────────────────────────────
  int get weekOrders {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return doneOrders.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).length;
  }

  int get monthOrders {
    final now = DateTime.now();
    return doneOrders.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.year == now.year && d.month == now.month;
    }).length;
  }

  double get earningsToday {
    final now = DateTime.now();
    return doneOrders.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (s, o) => s + (o.price ?? 0));
  }

  double get earningsWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return doneOrders.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).fold(0.0, (s, o) => s + (o.price ?? 0));
  }

  double get earningsMonth {
    final now = DateTime.now();
    return doneOrders.where((o) {
      final d = o.completedAt ?? o.updatedAt;
      return d.year == now.year && d.month == now.month;
    }).fold(0.0, (s, o) => s + (o.price ?? 0));
  }

  double get earningsTotal =>
      doneOrders.fold(0.0, (s, o) => s + (o.price ?? 0));

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadWorker().then((_) {
      _startAvailableOrdersStream();
      _startFinancialStream();
    });
    _startOrdersStream();
    _startReviewsStream();
    // Reinicia stream quando worker muda (aprovação, suspensão, categorias)
    ever(worker, (_) => _startAvailableOrdersStream());
    // Monitora hasActiveJob via debounce — evita recriar stream a cada pedido individual
    // ever(allOrders) causaria cascata: update → recria stream → update → recria stream...
    // Solução: escuta mudanças de activeOrders.length que é mais estável
    _lastActiveCount = activeOrders.length;
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _availableOrdersSub?.cancel();
    _reviewsSub?.cancel();
    _financialSub?.cancel();
    super.onClose();
  }

  // ─── Financeiro (registros de serviços concluídos) ────────────────────────

  void _startFinancialStream() {
    final w = worker.value;
    if (w == null) return;
    _financialSub?.cancel();
    _financialSub =
        _ds.watchWorkerFinancialRecords(w.id).listen((list) {
      financialRecords.assignAll(list);
    }, onError: (_) {});
  }

  double get financialPendingTotal => financialRecords
      .where((r) => r.paymentStatus == PaymentStatus.pending)
      .fold(0.0, (s, r) => s + r.netAmount);

  double get financialPaidTotal => financialRecords
      .where((r) => r.paymentStatus == PaymentStatus.paid)
      .fold(0.0, (s, r) => s + r.netAmount);

  double get financialWithdrawnTotal => financialRecords
      .where((r) => r.paymentStatus == PaymentStatus.withdrawn)
      .fold(0.0, (s, r) => s + r.netAmount);

  double get financialGrossTotal =>
      financialRecords.fold(0.0, (s, r) => s + r.grossAmount);

  double get financialNetTotal =>
      financialRecords.fold(0.0, (s, r) => s + r.netAmount);

  // ─── Carregamento ─────────────────────────────────────────────────────────
  Future<void> reload() => _loadWorker();

  Future<void> _loadWorker() async {
    try {
      final w = await _ds.getWorker(_fb.uid);
      if (w != null) {
        worker.value = w;
        isAvailable.value = w.isAvailable;
      }
    } catch (_) {}
  }

  void _startOrdersStream() {
    isLoadingOrders.value = true;
    _ordersSub = _ds.watchWorkerOrders(_fb.uid).listen(
          (list) {
        allOrders.assignAll(list);
        isLoadingOrders.value = false;
      },
      onError: (_) => isLoadingOrders.value = false,
    );
  }

  void _startReviewsStream() {
    _reviewsSub = _ds.watchReviews(_fb.uid).listen(
          (list) => reviews.assignAll(list),
    );
  }

  // ─── Disponibilidade ──────────────────────────────────────────────────────
  Future<void> toggleAvailability(bool value) async {
    isTogglingAvailability.value = true;
    try {
      await _ds.updateWorker(_fb.uid, {'isAvailable': value});
      isAvailable.value = value;
      worker.value = worker.value?.copyWith(isAvailable: value);
    } catch (_) {
      isAvailable.value = !value;
    } finally {
      isTogglingAvailability.value = false;
    }
  }

  // ─── Ações rápidas de pedido ──────────────────────────────────────────────
  /// Aceita um pedido disponível.
  ///
  /// FLUXO:
  /// 1. Guarda local: verifica hasActiveJob
  /// 2. Transação Firestore: claimOrder (atômica — evita dois prestadores no mesmo pedido)
  /// 3. Para stream de pedidos disponíveis (prestador está ocupado)
  /// 4. Notifica o cliente em tempo real
  /// 5. Ambas as telas atualizam via streams Firestore (sem navegação manual)
  final isAccepting = false.obs;

  /// Aceita o pedido. Retorna true em caso de sucesso — os chamadores
  /// (ex.: tela de solicitação) só devem navegar para o mapa se true.
  Future<bool> acceptOrder(OrderModel order,
      {bool openNavigation = true, bool skipActiveGuard = false}) async {
    // Guarda local (ignorada no fluxo de AGENDAMENTO, que aceita e já
    // grava scheduledAt — trabalho agendado não conta como ativo)
    if (!skipActiveGuard && hasActiveJob) {
      Get.snackbar(
        'Serviço em andamento',
        'Conclua o serviço atual antes de aceitar outro — ou use a opção Agendar.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF9A825),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    isAccepting.value = true;
    try {
      final workerName = worker.value?.name ?? '';
      final workerId   = _fb.uid;

      // Transação atômica — verifica e aceita em uma única operação
      await _ds.acceptOrder(order.id, workerId, workerName);

      // Para de receber novos pedidos imediatamente
      _availableOrdersSub?.cancel();
      availableOrders.clear();

      // Notifica o cliente — pedido aceito
      await _ds.saveNotification(
        targetUserId: order.userId,
        title:        'Profissional encontrado! 🎉',
        body:         '$workerName aceitou seu pedido de ${order.serviceCategory}.',
        type:         'order_accepted',
        targetId:     order.id,
      );

      // Streams do Firestore atualizam automaticamente as duas telas:
      // - watchClientOrders (cliente): pedido muda de pending → accepted
      // - watchWorkerOrders (prestador): pedido aparece com workerId=uid
      // - watchAvailableOrdersForWorker (outros): pedido some (workerId != '')
      // Reinicia stream explicitamente (hasActiveJob agora = true)
      _startAvailableOrdersStream();

      if (openNavigation) {
        // Fluxo estilo 99: abre imediatamente a tela de navegação
        Get.toNamed(AppRoutes.workerNavigation,
            arguments: {'orderId': order.id});
      } else {
        Get.snackbar(
          'Pedido aceito!',
          'Você aceitou o pedido de ${order.serviceCategory}.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1D9E75),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
      return true;
    } on ValidationException catch (e) {
      // Pedido já foi aceito por outro prestador
      Get.snackbar(
        'Pedido indisponível',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      // permission-denied aqui normalmente indica regras antigas ou
      // prestador não elegível (isVerified/isAvailable/isSuspended).
      final msg = e.toString().contains('permission-denied')
          ? 'Permissão negada. Verifique se seu perfil está aprovado e '
              'disponível, e se as regras do Firestore estão atualizadas.'
          : 'Não foi possível aceitar o pedido. Tente novamente.';
      Get.snackbar(
        'Erro',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isAccepting.value = false;
    }
  }

  Future<void> refuseOrder(OrderModel order) async {
    // Pedido ainda não vinculado (workerId == ''): apenas dispensa
    // localmente — ele continua disponível para outros prestadores e o
    // cliente NÃO deve receber "pedido recusado" (outro profissional
    // ainda pode aceitar).
    if (order.workerId == null || order.workerId!.isEmpty) {
      _dismissedOrderIds.add(order.id);
      availableOrders.refresh();
      allOrders.refresh(); // garante rebuild da aba "Novas" e badges
      Get.snackbar('Solicitação dispensada',
          'Ela continua disponível para outros prestadores.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
      return;
    }

    // Pedido já vinculado a este prestador: volta para a fila e avisa o cliente.
    await _ds.refuseOrder(order.id);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Pedido recusado',
      body: 'O profissional não pôde aceitar seu pedido agora.',
      type: 'order_update',
      targetId: order.id,
    );
  }

  Future<void> startOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.inProgress);
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Serviço iniciado!',
      body: 'O profissional chegou e iniciou o serviço de ' + order.serviceCategory + '.',
      type: 'order_started',
      targetId: order.id,
    );
  }

  Future<void> completeOrder(OrderModel order) async {
    await _ds.updateOrderStatusWithTimestamp(order.id, OrderStatus.done);
    // Reinicia stream de disponíveis — prestador ficou livre novamente
    await _ds.saveNotification(
      targetUserId: order.userId,
      title: 'Serviço concluído!',
      body: 'Que tal avaliar o profissional?',
      type: 'order_update',
      targetId: order.id,
    );
    // Prestador terminou o serviço — pode receber novos chamados
    _startAvailableOrdersStream();
  }

  // ─── Navegação ────────────────────────────────────────────────────────────
  void goToEdit() => Get.toNamed(AppRoutes.editWorkerProfile);

  void goToChat(String orderId) =>
      Get.toNamed(AppRoutes.chat, arguments: orderId);


  void _startAvailableOrdersStream() {
    final w = worker.value;
    if (w == null) return;

    _availableOrdersSub?.cancel();
    _availableStreamPrimed = false; // primeiro snapshot não gera alerta

    // Categorias ativas: usa activeCategories se preenchido, senão categories do perfil
    final activeCats = w.activeCategories.isNotEmpty
        ? w.activeCategories
        : w.categories;

    // Repassa todos os critérios de elegibilidade ao datasource
    _availableOrdersSub = _ds.watchAvailableOrdersForWorker(
      activeCategories:  activeCats,
      hasActiveJob:      hasActiveJob,
      isVerified:        w.isVerified,
      isAvailable:       w.isAvailable,
      isSuspended:       w.isSuspended,
      verificationStatus: w.verificationStatus.name,
    ).listen(
      (list) {
        availableOrders.assignAll(list);
        _alertNewAvailableOrders(list);
      },
      onError: (e) {
        availableOrders.clear();
        // Diagnóstico visível — antes o erro era engolido e a aba
        // "Novas" ficava vazia sem explicação.
        availableBlockReason.value =
            e.toString().contains('permission-denied')
                ? 'Sem permissão para ver solicitações. Verifique se seu '
                    'perfil está aprovado e se você está DISPONÍVEL, e se '
                    'as regras do Firestore estão atualizadas (v8).'
                : 'Erro ao carregar solicitações. Verifique sua conexão.';
      },
    );

    // Motivos de elegibilidade local (sem erro de rede)
    if (!w.isVerified || w.verificationStatus.name != 'approved') {
      availableBlockReason.value =
          'Seu perfil ainda não foi aprovado pelo administrador — você '
          'receberá solicitações após a aprovação.';
    } else if (w.isSuspended) {
      availableBlockReason.value =
          'Seu perfil está suspenso. Fale com o suporte.';
    } else if (!w.isAvailable) {
      availableBlockReason.value =
          'Você está OFFLINE. Ative sua disponibilidade no painel para '
          'receber novas solicitações.';
    } else if (activeCats.isEmpty) {
      availableBlockReason.value =
          'Nenhuma categoria de serviço ativa no seu perfil.';
    } else {
      availableBlockReason.value = '';
    }
  }

  /// Dispara um alerta (notificação local + snackbar) quando uma nova
  /// solicitação chega em tempo real enquanto o prestador está logado.
  void _alertNewAvailableOrders(List<OrderModel> list) {
    if (!_availableStreamPrimed) {
      // Primeiro snapshot após login/reinício de stream: só memoriza.
      _knownAvailableIds
        ..clear()
        ..addAll(list.map((o) => o.id));
      _availableStreamPrimed = true;
      return;
    }

    final fresh =
        list.where((o) => !_knownAvailableIds.contains(o.id)).toList();
    _knownAvailableIds.addAll(list.map((o) => o.id));
    if (fresh.isEmpty) return;

    final first = fresh.first;
    final title = fresh.length == 1
        ? 'Nova solicitação de serviço!'
        : '${fresh.length} novas solicitações!';
    final body = fresh.length == 1
        ? '${first.clientName ?? 'Um cliente'} solicitou ${first.serviceCategory}.'
        : 'Você tem novas solicitações aguardando resposta.';

    // Notificação no sistema (aparece mesmo com o app em segundo plano)
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().showLocal(
        title: title,
        body: body,
        type: 'new_order',
        targetId: first.id,
      );
    }

    // Alerta visual dentro do app — tocar abre a tela da solicitação
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1D9E75),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.notifications_active_rounded,
          color: Colors.white),
      onTap: (_) => Get.toNamed(AppRoutes.workerRequestDetail,
          arguments: {'order': first}),
      mainButton: TextButton(
        onPressed: () => Get.toNamed(AppRoutes.workerRequestDetail,
            arguments: {'order': first}),
        child: const Text('VER',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Future<void> updateActiveCategories(List<String> active) async {
    try {
      await _ds.updateWorker(_fb.uid, {'activeCategories': active});
      // copyWith atualiza worker.value → ever(worker) dispara _startAvailableOrdersStream
      worker.value = worker.value?.copyWith(activeCategories: active);
    } catch (_) {}
  }


  /// Prestador agenda o serviço e notifica o cliente com data/hora
  /// Agenda o serviço: prestador define data/hora.
  /// Salva: scheduledAt (Timestamp), updatedAt (serverTimestamp), status=accepted.
  /// Notifica o cliente com a data formatada.
  Future<void> scheduleOrder(OrderModel order, DateTime scheduledAt) async {
    try {
      final day    = scheduledAt.day.toString().padLeft(2, '0');
      final month  = scheduledAt.month.toString().padLeft(2, '0');
      final hour   = scheduledAt.hour.toString().padLeft(2, '0');
      final minute = scheduledAt.minute.toString().padLeft(2, '0');

      // Salva via datasource (nunca acessar Firestore diretamente no controller)
      await _ds.scheduleOrder(order.id, scheduledAt);

      // Notifica o cliente com data/hora legíveis
      await _ds.saveNotification(
        targetUserId: order.userId,
        title:   'Serviço agendado! 📅',
        body:    'Seu pedido de ${order.serviceCategory} foi agendado '
                 'para $day/$month às $hour:$minute. Aguarde o profissional.',
        type:    'order_scheduled',
        targetId: order.id,
      );
    } catch (_) {}
  }

  List<OrderModel> get scheduledOrders => allOrders.where((o) =>
      o.status == OrderStatus.accepted &&
      o.scheduledAt != null &&
      o.scheduledAt!.isAfter(DateTime.now())).toList();

  List<OrderModel> get openOrders => allOrders.where((o) =>
      o.status == OrderStatus.accepted &&
      o.scheduledAt == null).toList();

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sair',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = Get.find<AuthRepositoryImpl>();
    await repo.signOut();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
