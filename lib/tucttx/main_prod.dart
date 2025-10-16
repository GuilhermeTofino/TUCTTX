// lib/main_prod.dart
import 'package:app_tenda/firebase/firebase_options.dart';
import 'package:app_tenda/flavors.dart';
import 'package:app_tenda/main.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  // Inicializa a configuração do flavor PROD
  FlavorConfig.initialize(Flavor.prod);
  print('Running in PROD mode');

  // Executa a lógica comum com as opções de PROD
  mainCommon(DefaultFirebaseOptions.currentPlatform);
}
