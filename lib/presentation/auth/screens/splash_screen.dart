import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();

    // Aguarda a animação e então decide para onde navegar
    Future.delayed(const Duration(milliseconds: 1800), _checkAuth);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final fb = Get.find<FirebaseService>();
    final user = fb.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    // Verifica se e-mail foi confirmado
    await user.reload();
    if (!user.emailVerified) {
      Get.offAllNamed(AppRoutes.verifyEmail);
      return;
    }

    // Verifica tipo do usuário
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    String? userType = await storage.read(key: 'user_type');

    // Se não tiver no cache, consulta Firestore
    if (userType == null) {
      final firestoreDs = Get.find<FirestoreDatasource>();
      final worker = await firestoreDs.getWorker(user.uid);
      userType = worker != null ? 'worker' : 'client';
      await storage.write(key: 'user_type', value: userType);
    }

    if (userType == 'worker') {
      // Trabalhador: verifica se já está aprovado
      final firestoreDs = Get.find<FirestoreDatasource>();
      final worker = await firestoreDs.getWorker(user.uid);
      if (worker != null && !worker.isVerified) {
        Get.offAllNamed(AppRoutes.pendingVerification);
        return;
      }
      Get.offAllNamed(AppRoutes.workerHome);
    } else {
      Get.offAllNamed(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      size: 52, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('ServiçoFácil',
                    style: TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                    )),
                const SizedBox(height: 8),
                Text('Conectando pessoas e serviços',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14, fontFamily: 'Poppins',
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
