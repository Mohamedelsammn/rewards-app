import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/l10n.dart';
import '../core/localization/locale_controller.dart';
import '../core/network/auth_interceptor.dart';
import '../core/services/ads/ads_manager.dart';
import '../core/theme/app_theme.dart';
import '../features/app_config/presentation/app_config_cubit.dart';
import '../features/auth/presentation/bloc/session_cubit.dart';
import '../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../features/rewarded_ads/presentation/rewarded_ads_cubit.dart';
import '../features/wallet/presentation/bloc/wallet_cubit.dart';
import 'di/injection_container.dart';
import 'router/app_router.dart';
import 'router/routes.dart';

class CreativeRewardsApp extends StatefulWidget {
  const CreativeRewardsApp({super.key});

  @override
  State<CreativeRewardsApp> createState() => _CreativeRewardsAppState();
}

class _CreativeRewardsAppState extends State<CreativeRewardsApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router = createAppRouter(session: sl(), config: sl());

  /// Main tabs: the only screens an App Open ad may cover on return.
  static const _appOpenScreens = {Routes.home, Routes.categories, Routes.wallet, Routes.profile};

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AdsManager>()) {
      sl<AdsManager>().eligibleForAppOpen = () =>
          sl<SessionCubit>().state.status == SessionStatus.authenticated &&
          _appOpenScreens.contains(_router.routerDelegate.currentConfiguration.uri.path);
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  void _onSession(BuildContext context, SessionState state) {
    if (state.status != SessionStatus.unauthenticated) return;
    // Drop the previous user's cached state.
    context.read<WalletCubit>().clear();
    context.read<UnreadCountCubit>().clear();
    if (sl.isRegistered<PendingAdSessions>()) sl<PendingAdSessions>().clear();
    final reason = state.endReason;
    if (reason == null) return;
    final l10n = AppLocalizations.of(_messengerKey.currentContext ?? context);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          reason == SessionEndReason.suspended ? l10n.errAccountSuspended : l10n.errSessionExpired,
        ),
      ),
    );
    context.read<SessionCubit>().acknowledgeEndReason();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<SessionCubit>.value(value: sl()),
      BlocProvider<AppConfigCubit>.value(value: sl()),
      BlocProvider<WalletCubit>.value(value: sl()),
      BlocProvider<UnreadCountCubit>.value(value: sl()),
    ],
    child: ValueListenableBuilder<Locale>(
      valueListenable: sl<LocaleController>(),
      builder: (context, locale, _) => BlocListener<SessionCubit, SessionState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || current.endReason != null,
        listener: _onSession,
        child: MaterialApp.router(
          title: 'Creative Rewards',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messengerKey,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    ),
  );
}
