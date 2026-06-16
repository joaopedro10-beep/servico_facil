import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Serviços globais permanentes
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // Datasources com fenix: recriados se removidos da memória
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<FirestoreDatasource>(() => FirestoreDatasource(), fenix: true);
  }
}

