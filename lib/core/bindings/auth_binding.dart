import 'package:get/get.dart';

import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../presentation/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<FirestoreDatasource>(() => FirestoreDatasource(), fenix: true);
    Get.lazyPut<AuthRepositoryImpl>(() => AuthRepositoryImpl(), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
