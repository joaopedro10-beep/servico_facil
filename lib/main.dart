import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/bindings/initial_binding.dart';
import 'core/bindings/auth_binding.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';

// Gerado pelo FlutterFire CLI — descomente após rodar `flutterfire configure`
// import 'firebase_options.dart';

import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/auth/screens/onboarding_screen.dart';
import 'presentation/auth/screens/welcome_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_client_screen.dart';
import 'presentation/auth/screens/register_worker_screen.dart';
import 'presentation/auth/screens/document_upload_screen.dart';
import 'presentation/auth/screens/verify_email_screen.dart';
import 'presentation/auth/screens/pending_verification_screen.dart';

// Placeholders — serão criados nos próximos prompts
import 'presentation/shared/placeholder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
      getPages: _pages(),
      // Fecha o teclado ao tocar fora de campos
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child!,
      ),
    );
  }

  List<GetPage> _pages() => [
    // ── Auth ─────────────────────────────────────────────────────────────
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

    // ── Client (placeholder até o Prompt 5) ──────────────────────────────
    GetPage(
      name: AppRoutes.clientHome,
      page: () => const PlaceholderScreen(title: 'Home do Cliente'),
      transition: Transition.fadeIn,
    ),

    // ── Worker (placeholder até o Prompt 10) ─────────────────────────────
    GetPage(
      name: AppRoutes.workerHome,
      page: () => const PlaceholderScreen(title: 'Dashboard do Prestador'),
      transition: Transition.fadeIn,
    ),
  ];
}
