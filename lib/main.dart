import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/bindings/auth_binding.dart';
import 'core/bindings/initial_binding.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/auth/screens/onboarding_screen.dart';
import 'presentation/auth/screens/welcome_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_client_screen.dart';
import 'presentation/auth/screens/complete_profile_screen.dart';
import 'presentation/auth/screens/complete_profile_success_screen.dart';
import 'presentation/auth/screens/register_worker_screen.dart';
import 'presentation/auth/screens/document_upload_screen.dart';
import 'presentation/auth/screens/verify_email_screen.dart';
import 'presentation/auth/screens/pending_verification_screen.dart';

// ── Client ───────────────────────────────────────────────────────────────────
import 'presentation/client/screens/client_home_screen.dart';
import 'presentation/client/screens/client_profile_screen.dart';
import 'presentation/client/controllers/client_home_controller.dart';
import 'presentation/client/controllers/client_profile_controller.dart';

// ── Worker ───────────────────────────────────────────────────────────────────
import 'presentation/worker/screens/worker_home_screen.dart';
import 'presentation/worker/screens/worker_request_detail_screen.dart';
import 'presentation/worker/screens/worker_navigation_screen.dart';
import 'presentation/worker/screens/worker_profile_screen.dart';
import 'presentation/worker/screens/edit_worker_profile_screen.dart';
import 'presentation/worker/screens/earnings_screen.dart';
import 'presentation/worker/screens/sections/worker_clients_section.dart';
import 'presentation/worker/screens/sections/worker_reports_section.dart';
import 'presentation/worker/screens/sections/worker_reviews_section.dart';
import 'presentation/worker/screens/sections/worker_financial_section.dart';
import 'presentation/worker/screens/sections/worker_settings_section.dart';
import 'presentation/worker/controllers/worker_controller.dart';
import 'presentation/worker/controllers/worker_home_controller.dart';
import 'presentation/worker/controllers/worker_profile_controller.dart';

// ── Orders ───────────────────────────────────────────────────────────────────
import 'presentation/orders/screens/order_detail_screen.dart';
import 'presentation/orders/screens/my_orders_screen.dart';
import 'presentation/orders/controllers/order_controller.dart';

// ── Chat ─────────────────────────────────────────────────────────────────────
import 'presentation/chat/screens/chat_screen.dart';
import 'presentation/chat/screens/chats_list_screen.dart';
import 'presentation/chat/controllers/chat_controller.dart';

// ── Reviews ──────────────────────────────────────────────────────────────────
import 'presentation/reviews/screens/rate_service_screen.dart';
import 'presentation/reviews/screens/reviews_screen.dart';
import 'presentation/reviews/controllers/review_controller.dart';

// ── Safety ───────────────────────────────────────────────────────────────────
import 'presentation/safety/screens/report_screen.dart';
import 'presentation/safety/screens/safety_tips_screen.dart';
import 'presentation/safety/screens/block_screen.dart';

// ── Notifications ────────────────────────────────────────────────────────────
import 'presentation/notifications/screens/notifications_screen.dart';
import 'presentation/notifications/controllers/notifications_controller.dart';

// ── Settings ─────────────────────────────────────────────────────────────────
import 'presentation/settings/screens/settings_screen.dart';
import 'presentation/settings/controllers/settings_controller.dart';

// ── Admin ─────────────────────────────────────────────────────────────────────
import 'presentation/admin/screens/admin_home_screen.dart';
import 'presentation/admin/controllers/admin_controller.dart';
import 'data/datasources/admin_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa os dados de data/hora do intl para pt_BR ANTES de qualquer
  // tela usar DateFormat('...', 'pt_BR'). Sem isso, telas como Notificações
  // e Relatórios quebram com LocaleDataException e "não carregam".
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Serviços que dependem de chamadas assíncronas (configuração do
  // Firestore, permissões de notificação, canal Android, etc.) precisam
  // ser inicializados ANTES do runApp(), usando Get.putAsync — diferente
  // de InitialBinding.dependencies(), que é síncrono e não pode aguardar.
  await Get.putAsync<FirebaseService>(
        () => FirebaseService().init(),
    permanent: true,
  );
  await Get.putAsync<NotificationService>(
        () => NotificationService().init(),
    permanent: true,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Remove a barra de navegação horizontal do Android (3 botões/gestos)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ServicoFacilApp());
}

class ServicoFacilApp extends StatelessWidget {
  const ServicoFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,

      // Localização para DatePicker em pt-BR
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],

      // Fecha teclado ao tocar fora de campos de texto
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: EdgeInsets.zero),
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child!,
          ),
        );
      },

      getPages: _pages(),
    );
  }

  List<GetPage> _pages() => [
    // ── Auth ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomeScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.registerClient,
      page: () => const RegisterClientScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.completeProfile,
      page: () => const CompleteProfileScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.completeProfileSuccess,
      page: () => const CompleteProfileSuccessScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.registerWorker,
      page: () => const RegisterWorkerScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.documentUpload,
      page: () => const DocumentUploadScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.verifyEmail,
      page: () => const VerifyEmailScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.pendingVerification,
      page: () => const PendingVerificationScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),

    // ── Client ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.clientHome,
      page: () => const ClientHomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ClientHomeController(), fenix: true);
        Get.lazyPut(() => ClientProfileController(), fenix: true);
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.clientProfile,
      page: () => const ClientProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ClientProfileController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.myOrders,
      page: () => const MyOrdersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Worker ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.workerHome,
      page: () => const WorkerHomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WorkerController(), fenix: true);
        Get.lazyPut(() => WorkerHomeController(), fenix: true);
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.workerProfile,
      page: () => const WorkerProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WorkerProfileController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editWorkerProfile,
      page: () => const EditWorkerProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WorkerProfileController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerOrders,
      page: () => const MyOrdersScreen(isWorker: true),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerEarnings,
      page: () => const EarningsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerReviews,
      page: () => const ReviewsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReviewController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Worker — telas do drawer ──────────────────────────────────────
    GetPage(
      name: AppRoutes.workerClients,
      // IMPORTANTE: seções abertas como rota precisam de Scaffold próprio.
      // Sem Scaffold não há Material ancestor → textos com sublinhado
      // amarelo, fundo preto e conteúdo sob a status bar.
      page: () => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: WorkerClientsSection(ctrl: Get.find<WorkerController>()),
        ),
      ),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<WorkerController>()) {
          Get.put(WorkerController());
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerReports,
      // Correção do erro de visualização em Relatórios: a seção era
      // renderizada sem Scaffold/Material, quebrando o layout.
      page: () => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: WorkerReportsSection(ctrl: Get.find<WorkerController>()),
        ),
      ),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<WorkerController>()) {
          Get.put(WorkerController());
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerFinancial,
      page: () => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          title: const Text('Financeiro'),
        ),
        body: WorkerFinancialSection(ctrl: Get.find<WorkerController>()),
      ),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<WorkerController>()) {
          Get.put(WorkerController());
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.workerSettings,
      page: () => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          title: const Text('Configurações'),
        ),
        body: WorkerSettingsSection(ctrl: Get.find<WorkerController>()),
      ),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<WorkerController>()) {
          Get.put(WorkerController());
        }
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Worker — fluxo estilo 99 ──────────────────────────────────────
    GetPage(
      name: AppRoutes.workerRequestDetail,
      page: () => const WorkerRequestDetailScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<WorkerController>()) {
          Get.put(WorkerController());
        }
      }),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.workerNavigation,
      page: () => const WorkerNavigationScreen(),
      transition: Transition.fadeIn,
    ),

    // ── Orders ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Chat ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChatController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.chatsList,
      page: () => const ChatsListScreen(),
      transition: Transition.rightToLeft,
    ),

    // ── Reviews ──────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.rateService,
      page: () => const RateServiceScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReviewController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.reviews,
      page: () => const ReviewsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReviewController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Safety ───────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.report,
      page: () => const ReportScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.safetyTips,
      page: () => const SafetyTipsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.block,
      page: () => const BlockScreen(),
      transition: Transition.rightToLeft,
    ),

    // ── Notifications ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationsController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Settings ─────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SettingsController(), fenix: true);
      }),
      transition: Transition.rightToLeft,
    ),

    // ── Admin ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.adminHome,
      page: () => const AdminHomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AdminDatasource(), fenix: true);
        Get.lazyPut(() => AdminController(), fenix: true);
      }),
      transition: Transition.fadeIn,
    ),
  ];
}
