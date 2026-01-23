import 'package:app_tenda/data/repositories/firebase_auth_repository.dart';
import 'package:app_tenda/domain/repositories/auth_repository.dart';
import 'package:app_tenda/presentation/viewmodels/home_viewmodel.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/firebase_user_repository.dart';
import '../../domain/repositories/user_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Repositories
  // Usamos lazySingleton para que o repositório só seja criado quando for usado pela primeira vez
  getIt.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
  getIt.registerFactory(() => HomeViewModel(getIt<UserRepository>()));
  getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
}