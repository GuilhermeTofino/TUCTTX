import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';

abstract class BaseFirestoreDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Atalho para acessar a coleção raiz do tenant atual
  // Ex: /tenants/tucttx/
  DocumentReference get tenantRoot => 
      firestore.collection('tenants').doc(AppConfig.instance.tenant.tenantSlug);

  // Atalho para subcoleções do tenant
  // Ex: /tenants/tucttx/users
  CollectionReference tenantCollection(String path) => 
      tenantRoot.collection(path);
}