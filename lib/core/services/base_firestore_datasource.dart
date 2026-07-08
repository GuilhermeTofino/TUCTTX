import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';

abstract class BaseFirestoreDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Atalho para acessar a coleção raiz do tenant atual
  // Ex: /environments/dev/tenants/tucttx/
  DocumentReference get tenantRoot {
    final env = AppConfig.instance.environment == AppEnvironment.dev
        ? 'dev'
        : 'prod';

    return firestore
        .collection('environments')
        .doc(env)
        .collection('tenants')
        .doc(AppConfig.instance.tenant.tenantSlug);
  }

  // Atalho para subcoleções do tenant
  // Ex: /tenants/tucttx/users
  CollectionReference tenantCollection(String path) =>
      tenantRoot.collection(path);

  // NOVO: Atalho para um documento específico dentro de uma subcoleção do tenant
  // Ex: /tenants/tucttx/users/UID_DO_USUARIO
  DocumentReference tenantDocument(String collectionPath, String docId) =>
      tenantCollection(collectionPath).doc(docId);
}
