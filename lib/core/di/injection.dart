import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/cache/cache_service.dart';
import '../../services/notification_service.dart';
import '../../services/secure_storage_service.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/giveaway_repository.dart';
import '../../shared/repositories/participation_repository.dart';
import '../../shared/repositories/storage_repository.dart';
import '../../shared/repositories/user_repository.dart';
import '../../shared/repositories/winner_repository.dart';
import '../localization/locale_controller.dart';
import '../network/supabase_client_provider.dart';

final getIt = GetIt.instance;

/// Manual get_it registration (no injectable codegen -- see the summary
/// note on this simplification). Called once from bootstrap after Supabase
/// and Hive have both finished their async initialization.
Future<void> configureDependencies() async {
  final supabaseProvider = await SupabaseClientProvider.initialize();
  final cacheService = await CacheService.initialize();

  getIt
    ..registerSingleton<SupabaseClient>(supabaseProvider.client)
    ..registerSingleton<CacheService>(cacheService)
    ..registerLazySingleton<SecureStorageService>(SecureStorageService.new)
    ..registerLazySingleton<AuthRepository>(() => AuthRepository(getIt()))
    ..registerLazySingleton<UserRepository>(() => UserRepository(getIt()))
    ..registerLazySingleton<GiveawayRepository>(() => GiveawayRepository(getIt(), getIt()))
    ..registerLazySingleton<ParticipationRepository>(
      () => ParticipationRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<WinnerRepository>(() => WinnerRepository(getIt()))
    ..registerLazySingleton<StorageRepository>(() => StorageRepository(getIt()))
    ..registerSingleton<LocaleController>(LocaleController(getIt()))
    ..registerLazySingleton<NotificationService>(() => NotificationService(getIt()));

  await getIt<LocaleController>().loadPersisted();
}
