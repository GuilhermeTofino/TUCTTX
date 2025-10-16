// lib/main_dev.dart
import 'package:app_tenda/firebase/firebase_options_dev.dart';
import 'package:app_tenda/flavors.dart';
import 'package:app_tenda/main.dart';

void main() {
  // Inicializa a configuração do flavor DEV
  FlavorConfig.initialize(Flavor.dev);
  print('Running in DEV mode'); 

  // Executa a lógica comum com as opções de DEV
  mainCommon(DefaultFirebaseOptions.currentPlatform);
}
