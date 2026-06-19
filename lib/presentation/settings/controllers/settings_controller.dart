import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase_service.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/constants/app_routes.dart';

class SettingsController extends GetxController {
  final FirebaseService _fb = Get.find<FirebaseService>();
  final FirestoreDatasource _ds = Get.find<FirestoreDatasource>();
  final AuthRepositoryImpl _auth = Get.find<AuthRepositoryImpl>();

  final isDarkMode = false.obs;
  final notificationsEnabled = true.obs;
  final isDeletingAccount = false.obs;

  static const _keyDark = 'dark_mode';
  static const _keyNotif = 'notifications_enabled';

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_keyDark) ?? false;
    notificationsEnabled.value = prefs.getBool(_keyNotif) ?? true;
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, value);
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotif, value);
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é permanente. Todos os seus dados serão removidos e não poderão ser recuperados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir permanentemente'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    isDeletingAccount.value = true;
    try {
      final uid = _fb.uid;
      // Apaga dados do Firestore
      await _ds.deleteUserData(uid);
      // Apaga conta do Firebase Auth
      await _auth.signOut();
      await _fb.auth.currentUser?.delete();
      Get.offAllNamed(AppRoutes.welcome);
    } catch (_) {
      Get.snackbar(
        'Erro',
        'Não foi possível excluir a conta. Tente fazer login novamente antes.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }
}
