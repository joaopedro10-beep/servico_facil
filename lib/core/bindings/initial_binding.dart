import 'package:get/get.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';

/// FirebaseService e NotificationService são inicializados de forma
/// assíncrona em main.dart (via Get.putAsync), ANTES de runApp(), porque
/// dependem de chamadas await (configuração do Firestore, permissões de
/// notificação, etc). Bindings.dependencies() é síncrono e não pode
/// aguardar isso — por isso eles não são registrados aqui.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Datasources com fenix: recriados se removidos da memória
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<FirestoreDatasource>(() => FirestoreDatasource(), fenix: true);
  }
}
