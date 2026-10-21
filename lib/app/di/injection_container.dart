import 'package:get_it/get_it.dart';

import '../../core/constants/app_info.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/security/secure_token_storage.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../features/app_config/data/app_config_repository_impl.dart';
import '../../features/app_config/domain/app_config.dart';
import '../../features/app_config/presentation/app_config_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/catalog/data/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/giveaways/data/giveaways_repository_impl.dart';
import '../../features/giveaways/domain/repositories/giveaways_repository.dart';
import '../../features/giveaways/presentation/celebration/celebration_coordinator.dart';
import '../../features/home/data/home_repository_impl.dart';
import '../../features/home/domain/home_feed.dart';
import '../../features/notifications/data/notifications_repository_impl.dart';
import '../../features/notifications/data/push_device_registrar.dart';
import '../../features/notifications/domain/notification_entities.dart';
import '../../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../../features/orders/data/orders_repository_impl.dart';
import '../../features/orders/domain/order_entities.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/rewarded_ads/data/ad_rewards_repository_impl.dart';
import '../../features/rewarded_ads/domain/ad_reward_entities.dart';
import '../../features/wallet/data/wallet_repository_impl.dart';
import '../../features/wallet/domain/wallet_entities.dart';
import '../../features/wallet/presentation/bloc/wallet_cubit.dart';

/// Service locator. Presentation resolves repositories and services from
/// here; feature code never constructs infrastructure itself.
final sl = GetIt.instance;

Future<void> configureDependencies({required String apiBaseUrl}) async {
  final tokens = SecureTokenStorage();
  final appInfo = await AppInfo.load();
  final locale = LocaleController(tokens);
  await locale.loadPersisted();

  final api = ApiClient.create(
    baseUrl: apiBaseUrl,
    tokens: tokens,
    onSessionEnded: (reason) => sl<SessionCubit>().sessionEnded(reason),
  );

  sl
    ..registerSingleton<SecureTokenStorage>(tokens)
    ..registerSingleton<AppInfo>(appInfo)
    ..registerSingleton<LocaleController>(locale)
    ..registerSingleton<ApiClient>(api)
    // Repositories
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(AuthRemoteDataSource(api), tokens),
    )
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(api))
    ..registerLazySingleton<AppConfigRepository>(() => AppConfigRepositoryImpl(api))
    ..registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(api))
    ..registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(api))
    ..registerLazySingleton<OrdersRepository>(() => OrdersRepositoryImpl(api))
    ..registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(api))
    ..registerLazySingleton<AdRewardsRepository>(() => AdRewardsRepositoryImpl(api))
    ..registerLazySingleton<GiveawaysRepository>(() => GiveawaysRepositoryImpl(api))
    ..registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(api))
    // Platform services
    ..registerLazySingleton<AdMobService>(AdMobService.new)
    ..registerLazySingleton<RewardedAdPresenter>(() => sl<AdMobService>())
    ..registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(
        PushDeviceRegistrarImpl(sl<NotificationsRepository>(), tokens, appInfo),
      ),
    )
    ..registerLazySingleton<CelebrationCoordinator>(
      () => CelebrationCoordinator(sl<GiveawaysRepository>()),
    )
    // App-scoped state
    ..registerLazySingleton<SessionCubit>(
      () => SessionCubit(
        sl<AuthRepository>(),
        beforeSignOut: () => sl<PushNotificationService>().unregister(),
      ),
    )
    ..registerLazySingleton<AppConfigCubit>(
      () => AppConfigCubit(sl<AppConfigRepository>(), appVersion: appInfo.version),
    )
    ..registerLazySingleton<WalletCubit>(() => WalletCubit(sl<WalletRepository>()))
    ..registerLazySingleton<UnreadCountCubit>(
      () => UnreadCountCubit(sl<NotificationsRepository>()),
    );
}
