import 'package:app_tenda/core/services/ai_event_parser.dart';
import 'package:app_tenda/domain/repositories/event_repository.dart';
import 'package:app_tenda/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/import_events_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/register_viewmodel.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firebase_user_repository.dart';
import '../../presentation/viewmodels/welcome_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---- Repositories ----
  getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  getIt.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
  getIt.registerLazySingleton<EventRepository>(() => EventRepository());

  // ---- Services ----
  // Registrado como Singleton para manter a mesma instância gerenciando tokens
  // getIt.registerLazySingleton<NotificationService>(
  //   () => NotificationService(getIt<UserRepository>()),
  // );

  getIt.registerLazySingleton<AIEventParser>(
    () => AIEventParser('AIzaSyD-0x0havmKrBfPq6aBLGEVDSTrKOtE92Y'),
  );

  // ---- ViewModels ----
  getIt.registerFactory(() => WelcomeViewModel(getIt<AuthRepository>()));

  // Alterado para LazySingleton para que o listener do onAuthStateChanged
  // (que captura o token via NotificationService) permaneça ativo durante o app
  getIt.registerLazySingleton(() => RegisterViewModel(getIt<AuthRepository>()));

  getIt.registerLazySingleton<HomeViewModel>(() => HomeViewModel());

  getIt.registerFactory<CalendarViewModel>(
    () => CalendarViewModel(getIt<EventRepository>()),
  );

  getIt.registerFactory<ImportEventsViewModel>(
    () =>
        ImportEventsViewModel(getIt<AIEventParser>(), getIt<EventRepository>()),
  );
}
