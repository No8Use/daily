import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/notes/notes_cubit.dart';
import 'package:daily/cubits/reviews/reviews_cubit.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/repositories/habits_repository.dart';
import 'package:daily/data/repositories/notes_repository.dart';
import 'package:daily/data/repositories/reviews_repository.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/utils/backup_service.dart';
import 'package:daily/utils/notification_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Initializes GetIt service locator dependencies.
Future<void> setupServiceLocator() async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<BackupService>(() => BackupService(getIt<AppDatabase>()));

  // Repositories
  getIt.registerLazySingleton<HabitsRepository>(() => HabitsRepository(getIt<AppDatabase>()));
  getIt.registerLazySingleton<TasksRepository>(() => TasksRepository(getIt<AppDatabase>()));
  getIt.registerLazySingleton<NotesRepository>(() => NotesRepository(getIt<AppDatabase>()));
  getIt.registerLazySingleton<ReviewsRepository>(() => ReviewsRepository(getIt<AppDatabase>()));

  // Cubits (Factory registration)
  getIt.registerFactory<HabitsCubit>(() => HabitsCubit(getIt<HabitsRepository>()));
  getIt.registerFactory<TasksCubit>(() => TasksCubit(getIt<TasksRepository>()));
  getIt.registerFactory<NotesCubit>(
    () => NotesCubit(getIt<NotesRepository>(), getIt<NotificationService>()),
  );
  getIt.registerFactory<ReviewsCubit>(() => ReviewsCubit(getIt<ReviewsRepository>()));
  getIt.registerFactory<HeatmapCubit>(
    () => HeatmapCubit(
      habitsRepository: getIt<HabitsRepository>(),
      tasksRepository: getIt<TasksRepository>(),
    ),
  );
}
