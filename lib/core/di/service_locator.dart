import 'package:app_tenda/core/services/ai_event_parser.dart';
import 'package:app_tenda/features/calendar/domain/repositories/event_repository.dart';
import 'package:app_tenda/features/calendar/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:app_tenda/features/calendar/presentation/viewmodels/import_events_viewmodel.dart';
import 'package:app_tenda/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:app_tenda/features/admin/presentation/viewmodels/member_management_viewmodel.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/finance_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:app_tenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:app_tenda/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:app_tenda/features/auth/data/repositories/firebase_user_repository.dart';
import 'package:app_tenda/core/services/menu_repository.dart';
import 'package:app_tenda/core/services/firebase_menu_repository.dart';
import 'package:app_tenda/features/auth/presentation/viewmodels/welcome_viewmodel.dart';
import 'package:app_tenda/core/services/notification_repository.dart';
import 'package:app_tenda/core/services/firebase_notification_repository.dart';
import 'package:app_tenda/core/services/notification_service.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';
import 'package:app_tenda/core/services/calendar_service.dart';
import 'package:app_tenda/features/finance/domain/repositories/finance_repository.dart';
import 'package:app_tenda/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:app_tenda/features/announcements/data/repositories/firebase_announcement_repository.dart';
import 'package:app_tenda/features/announcements/presentation/viewmodels/announcement_viewmodel.dart';
import 'package:app_tenda/features/studies/domain/repositories/study_repository.dart';
import 'package:app_tenda/features/studies/data/repositories/firebase_study_repository.dart';
import 'package:app_tenda/features/studies/presentation/viewmodels/study_viewmodel.dart';
import 'package:app_tenda/features/admin/presentation/viewmodels/cleaning_dashboard_viewmodel.dart';
import 'package:app_tenda/core/services/version_check_service.dart';
import 'package:app_tenda/core/services/layout_service.dart';
import 'package:app_tenda/features/cambone/domain/repositories/cambone_repository.dart';
import 'package:app_tenda/features/cambone/presentation/viewmodels/cambone_viewmodel.dart';
import 'package:app_tenda/features/profile/presentation/viewmodels/my_entities_viewmodel.dart';
import 'package:app_tenda/features/admin/presentation/viewmodels/house_entities_viewmodel.dart';
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
