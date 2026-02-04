import 'package:app_tenda/core/services/ai_event_parser.dart';
import 'package:app_tenda/domain/repositories/event_repository.dart';
import 'package:app_tenda/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/import_events_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/register_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/member_management_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:app_tenda/domain/repositories/auth_repository.dart';
import 'package:app_tenda/domain/repositories/user_repository.dart';
import 'package:app_tenda/data/repositories/firebase_auth_repository.dart';
import 'package:app_tenda/data/repositories/firebase_user_repository.dart';
import 'package:app_tenda/domain/repositories/menu_repository.dart';
import 'package:app_tenda/data/repositories/firebase_menu_repository.dart';
import 'package:app_tenda/presentation/viewmodels/welcome_viewmodel.dart';
import 'package:app_tenda/domain/repositories/notification_repository.dart';
import 'package:app_tenda/data/repositories/firebase_notification_repository.dart';
import 'package:app_tenda/core/services/notification_service.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/domain/repositories/announcement_repository.dart';
import 'package:app_tenda/data/repositories/firebase_announcement_repository.dart';
import 'package:app_tenda/presentation/viewmodels/announcement_viewmodel.dart';
import 'package:app_tenda/domain/repositories/study_repository.dart';
import 'package:app_tenda/data/repositories/firebase_study_repository.dart';
import 'package:app_tenda/presentation/viewmodels/study_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---- Repositories ----
  getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  getIt.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
  getIt.registerLazySingleton<EventRepository>(() => EventRepository());
  getIt.registerLazySingleton<MenuRepository>(() => FirebaseMenuRepository());
  getIt.registerLazySingleton<NotificationRepository>(
    () => FirebaseNotificationRepository(),
  );
  getIt.registerLazySingleton<FinanceRepository>(
    () => FirebaseFinanceRepository(),
  );
  getIt.registerLazySingleton<AnnouncementRepository>(
    () => FirebaseAnnouncementRepository(),
  );
  getIt.registerLazySingleton<StudyRepository>(() => FirebaseStudyRepository());

  // ---- Services ----
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<PushTriggerService>(() => PushTriggerService());

  const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (geminiKey.isEmpty) {
    print("ALERTA: GEMINI_API_KEY não configurada. A IA não funcionará.");
  }

  getIt.registerLazySingleton<AIEventParser>(() => AIEventParser(geminiKey));

  // ---- ViewModels ----
  getIt.registerFactory(() => WelcomeViewModel(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterViewModel(getIt<AuthRepository>()));
  getIt.registerLazySingleton<HomeViewModel>(() => HomeViewModel());

  getIt.registerFactory<CalendarViewModel>(
    () => CalendarViewModel(getIt<EventRepository>()),
  );

  getIt.registerFactory<ImportEventsViewModel>(
    () =>
        ImportEventsViewModel(getIt<AIEventParser>(), getIt<EventRepository>()),
  );

  getIt.registerFactory<MemberManagementViewModel>(
    () => MemberManagementViewModel(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<FinanceViewModel>(() => FinanceViewModel());
  getIt.registerLazySingleton<AnnouncementViewModel>(
    () => AnnouncementViewModel(),
  );
  getIt.registerLazySingleton<StudyViewModel>(() => StudyViewModel());
}
