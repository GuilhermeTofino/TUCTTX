import 'package:app_tenda/presentation/viewmodels/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/register_viewmodel.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firebase_user_repository.dart';
import '../../presentation/viewmodels/welcome_viewmodel.dart';
// Importe as novas ViewModels conforme for criando:
// import '../../presentation/viewmodels/register_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---- Repositories ----
  // LazySingleton: Uma única instância para o app todo, criada apenas no primeiro uso.
  getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  getIt.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());

  // ---- ViewModels ----
  // Factory: Cria uma NOVA instância toda vez que a tela for aberta (ideal para ViewModels)
  // No service_locator.dart
  getIt.registerFactory(() => WelcomeViewModel(getIt<AuthRepository>()));
  getIt.registerFactory(() => RegisterViewModel(getIt<AuthRepository>()));
  getIt.registerLazySingleton<HomeViewModel>(() => HomeViewModel());
  // Exemplo de como registrar a de registro futuramente:
  // getIt.registerFactory(() => RegisterViewModel(getIt<AuthRepository>()));
}
