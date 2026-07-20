import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shimmer/main.dart';

import 'lib/core/bindings/auth_binding.dart';
import 'lib/core/bindings/initial_binding.dart';
import 'lib/core/constants/app_routes.dart';
import 'lib/core/constants/app_strings.dart';
import 'lib/core/theme/app_theme.dart';
import 'lib/core/services/firebase_service.dart';
import 'lib/core/services/notification_service.dart';
import 'lib/firebase_options.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────
import 'lib/presentation/auth/screens/splash_screen.dart';
import 'lib/presentation/auth/screens/onboarding_screen.dart';
import 'lib/presentation/auth/screens/welcome_screen.dart';
import 'lib/presentation/auth/screens/login_screen.dart';
import 'lib/presentation/auth/screens/register_client_screen.dart';
import 'lib/presentation/auth/screens/complete_profile_screen.dart';
import 'lib/presentation/auth/screens/complete_profile_success_screen.dart';
import 'lib/presentation/auth/screens/register_worker_screen.dart';
import 'lib/presentation/auth/screens/document_upload_screen.dart';
import 'lib/presentation/auth/screens/verify_email_screen.dart';
import 'lib/presentation/auth/screens/pending_verification_screen.dart';

// ── Client ───────────────────────────────────────────────────────────────────
import 'lib/presentation/client/screens/client_home_screen.dart';
import 'lib/presentation/client/screens/client_profile_screen.dart';
import 'lib/presentation/client/controllers/client_home_controller.dart';
import 'lib/presentation/client/controllers/client_profile_controller.dart';

// ── Worker ───────────────────────────────────────────────────────────────────
import 'lib/presentation/worker/screens/worker_home_screen.dart';
import 'lib/presentation/worker/screens/worker_profile_screen.dart';
import 'lib/presentation/worker/screens/edit_worker_profile_screen.dart';
import 'lib/presentation/worker/screens/earnings_screen.dart';
import 'lib/presentation/worker/controllers/worker_home_controller.dart';
import 'lib/presentation/worker/controllers/worker_profile_controller.dart';

// ── Orders ───────────────────────────────────────────────────────────────────
import 'lib/presentation/orders/screens/order_detail_screen.dart';
import 'lib/presentation/orders/screens/my_orders_screen.dart';
import 'lib/presentation/orders/controllers/order_controller.dart';

// ── Chat ─────────────────────────────────────────────────────────────────────
import 'lib/presentation/chat/screens/chat_screen.dart';
import 'lib/presentation/chat/screens/chats_list_screen.dart';
import 'lib/presentation/chat/controllers/chat_controller.dart';

// ── Reviews ──────────────────────────────────────────────────────────────────
import 'lib/presentation/reviews/screens/rate_service_screen.dart';
import 'lib/presentation/reviews/screens/reviews_screen.dart';
import 'lib/presentation/reviews/controllers/review_controller.dart';

// ── Safety ───────────────────────────────────────────────────────────────────
import 'lib/presentation/safety/screens/report_screen.dart';
import 'lib/presentation/safety/screens/safety_tips_screen.dart';
import 'lib/presentation/safety/screens/block_screen.dart';

// ── Notifications ────────────────────────────────────────────────────────────
import 'lib/presentation/notifications/screens/notifications_screen.dart';
import 'lib/presentation/notifications/controllers/notifications_controller.dart';

// ── Settings ─────────────────────────────────────────────────────────────────
import 'lib/presentation/settings/screens/settings_screen.dart';
import 'lib/presentation/settings/controllers/settings_controller.dart';

// ── Shared ───────────────────────────────────────────────────────────────────

// ── Admin ─────────────────────────────────────────────────────────────────────
import 'lib/presentation/admin/screens/admin_home_screen.dart';
import 'lib/presentation/admin/controllers/admin_controller.dart';
import 'lib/data/datasources/admin_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Serviços que dependem de chamadas assíncronas (configuração do
  // Firestore, permissões de notificação, canal Android, etc.) precisam
  // ser inicializados ANTES do runApp(), usando Get.putAsync — diferente
  // de InitialBinding.dependencies(), que é síncrono e não pode aguardar.
  await Get.putAsync<FirebaseService>(() => FirebaseService().init(),
      permanent: true);
  await Get.putAsync<NotificationService>(() => NotificationService().init(),
      permanent: true);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Remove a barra de navegação horizontal do Android (3 botões/gestos)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],

      // Fecha teclado ao tocar fora
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
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
          name: AppRoutes.workerProfile,
          page: () => const WorkerProfileScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => WorkerProfileController(), fenix: true);
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
        GetPage(
          name: AppRoutes.clientProfile,
          page: () => const ClientProfileScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ClientProfileController(), fenix: true);
          }),
          transition: Transition.rightToLeft,
        ),

        // ── Worker ───────────────────────────────────────────────────────
        GetPage(
          name: AppRoutes.workerHome,
          page: () => const WorkerHomeScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => WorkerHomeController(), fenix: true);
          }),
          transition: Transition.fadeIn,
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
