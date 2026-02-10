import 'package:app_tenda/core/services/ai_event_parser.dart';
import 'package:app_tenda/domain/repositories/event_repository.dart';
import 'package:app_tenda/presentation/viewmodels/calendar/calendar_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/home/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/import_events/import_events_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/auth/register_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/admin/member_management_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/finance/finance_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:app_tenda/domain/repositories/auth_repository.dart';
import 'package:app_tenda/domain/repositories/user_repository.dart';
import 'package:app_tenda/data/repositories/firebase_auth_repository.dart';
import 'package:app_tenda/data/repositories/firebase_user_repository.dart';
import 'package:app_tenda/domain/repositories/menu_repository.dart';
import 'package:app_tenda/data/repositories/firebase_menu_repository.dart';
import 'package:app_tenda/presentation/viewmodels/auth/welcome_viewmodel.dart';
import 'package:app_tenda/domain/repositories/notification_repository.dart';
import 'package:app_tenda/data/repositories/firebase_notification_repository.dart';
import 'package:app_tenda/core/services/notification_service.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';
import 'package:app_tenda/core/services/calendar_service.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/domain/repositories/announcement_repository.dart';
import 'package:app_tenda/data/repositories/firebase_announcement_repository.dart';
import 'package:app_tenda/presentation/viewmodels/announcements/announcement_viewmodel.dart';
import 'package:app_tenda/domain/repositories/study_repository.dart';
import 'package:app_tenda/data/repositories/firebase_study_repository.dart';
import 'package:app_tenda/presentation/viewmodels/studies/study_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/admin/cleaning_dashboard_viewmodel.dart';
import 'package:app_tenda/core/services/version_check_service.dart';
import 'package:app_tenda/core/services/layout_service.dart';
import 'package:app_tenda/domain/repositories/cambone_repository.dart';
import 'package:app_tenda/presentation/viewmodels/cambone/cambone_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/profile/my_entities_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/admin/house_entities_viewmodel.dart';
import 'package:app_tenda/core/services/dynamic_island/dynamic_island_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  getIt.registerLazySingleton<CalendarService>(() => CalendarService());

  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (geminiKey.isEmpty) {
    print(
      "ALERTA: GEMINI_API_KEY não configurada no .env. A IA não funcionará.",
    );
  }

  getIt.registerLazySingleton<AIEventParser>(() => AIEventParser(geminiKey));

  // ---- Version Check Service ----
  getIt.registerLazySingleton<VersionCheckService>(() => VersionCheckService());
  getIt.registerLazySingleton<LayoutService>(() => LayoutService());
  getIt.registerLazySingleton<DynamicIslandService>(
    () => DynamicIslandService(),
  );

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
  getIt.registerFactory<CleaningDashboardViewModel>(
    () => CleaningDashboardViewModel(),
  );

  getIt.registerLazySingleton<CamboneRepository>(() => CamboneRepository());
  getIt.registerFactory<CamboneViewModel>(
    () => CamboneViewModel(
      getIt<AIEventParser>(),
      getIt<CamboneRepository>(),
      getIt<PushTriggerService>(), // Added
    ),
  );

  getIt.registerFactory<MyEntitiesViewModel>(() => MyEntitiesViewModel());
  getIt.registerFactory(() => HouseEntitiesViewModel());
}
