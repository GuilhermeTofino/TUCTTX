import 'package:app_tenda/app.dart';
import 'package:app_tenda/firebase/firebase_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Importe seu widget App principal
// import 'package:tucttx/app.dart';

Future<void> mainCommon(FirebaseOptions firebaseOptions) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções do flavor correto
  await Firebase.initializeApp(options: firebaseOptions);

  // Inicializa as notificações
  await FirebaseNotifications.initializeNotifications();

  runApp(const App()); // Substitua pelo seu widget App
}
