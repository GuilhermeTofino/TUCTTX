import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tenda/core/config/app_config.dart';

abstract class BaseFirestoreDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Atalho para a raiz do ambiente atual (não depende de saber o tenant
  // ainda). Usado para coleções globais que existem ANTES do login resolver
  // a casa do usuário, como o índice uid -> tenantSlug.
  // Ex: /environments/dev/
  DocumentReference get environmentRoot {
    final env = AppConfig.instance.environment == AppEnvironment.dev
        ? 'dev'
        : 'prod';

    return firestore.collection('environments').doc(env);
  }

  // Atalho para acessar a coleção raiz do tenant atual
  // Ex: /environments/dev/tenants/tucttx/
  DocumentReference get tenantRoot =>
      environmentRoot.collection('tenants').doc(AppConfig.instance.tenant.tenantSlug);

  // Atalho para subcoleções do tenant
  // Ex: /tenants/tucttx/users
  CollectionReference tenantCollection(String path) =>
      tenantRoot.collection(path);

  // NOVO: Atalho para um documento específico dentro de uma subcoleção do tenant
  // Ex: /tenants/tucttx/users/UID_DO_USUARIO
  DocumentReference tenantDocument(String collectionPath, String docId) =>
      tenantCollection(collectionPath).doc(docId);

  // Índice global (por ambiente) de uid -> tenantSlug. É a única coisa que
  // precisa ser consultada ANTES de sabermos a casa do usuário: no login,
  // buscamos aqui primeiro para então montar os caminhos tenant-scoped acima.
  // Ex: /environments/dev/userTenantIndex/UID_DO_USUARIO -> { tenantSlug: 'tucttx' }
  DocumentReference userTenantIndexDocument(String uid) =>
      environmentRoot.collection('userTenantIndex').doc(uid);
}
