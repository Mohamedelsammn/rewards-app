import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/page_transitions.dart';
import '../../features/app_config/presentation/app_config_cubit.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/auth/presentation/onboarding_draft.dart';
import '../../features/auth/presentation/pages/character_page.dart';
import '../../features/auth/presentation/pages/email_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/password_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/catalog/domain/entities/catalog_entities.dart';
import '../../features/catalog/presentation/pages/categories_page.dart';
import '../../features/catalog/presentation/pages/category_details_page.dart';
import '../../features/giveaways/domain/entities/giveaway_entities.dart';
import '../../features/giveaways/presentation/celebration/winner_celebration_page.dart';
import '../../features/giveaways/presentation/pages/giveaway_details_page.dart';
import '../../features/giveaways/presentation/pages/giveaways_page.dart';
import '../../features/giveaways/presentation/pages/my_giveaways_page.dart';
import '../../features/giveaways/presentation/pages/ticket_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/domain/notification_entities.dart';
import '../../features/notifications/presentation/pages/inbox_page.dart';
import '../../features/notifications/presentation/pages/notification_details_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/profile/presentation/pages/account_settings_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/delete_account_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/info_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/sessions_page.dart';
import '../../features/rewarded_ads/presentation/earn_page.dart';
import '../../features/wallet/presentation/pages/refer_page.dart';
import '../../features/wallet/presentation/pages/transactions_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../shell/main_shell.dart';
import '../startup/animated_splash.dart';
import '../startup/startup_ads.dart';
import '../startup/startup_pages.dart';
import 'routes.dart';

const _blockingPaths = {Routes.splash, Routes.maintenance, Routes.update, Routes.offline};

/// Where the app must be, given config and session state; `null` keeps the
/// requested [location]. Pure so it can be unit tested.
///
/// [splashIntroDone] lets the start-up splash finish its short intro before
/// leaving it, so a fast start transitions gracefully instead of cutting.
String? resolveRedirect({
  required String location,
  required AppConfigState config,
  required bool updateRequired,
  required SessionState session,
  bool splashIntroDone = true,
}) {
  String? to(String path) => location == path ? null : path;
  if (location == Routes.splash && !splashIntroDone) return null;

  switch (config.status) {
    case AppConfigStatus.loading:
      return to(Routes.splash);
    case AppConfigStatus.failed:
      return to(Routes.offline);
    case AppConfigStatus.ready:
      if (config.config.maintenance) return to(Routes.maintenance);
      if (updateRequired) return to(Routes.update);
  }
  switch (session.status) {
    case SessionStatus.unknown:
      return to(Routes.splash);
    case SessionStatus.offline:
      return to(Routes.offline);
    case SessionStatus.unauthenticated:
      return Routes.signedOutPaths.contains(location) ? null : Routes.welcome;
    case SessionStatus.authenticated:
      if (Routes.signedOutPaths.contains(location) || _blockingPaths.contains(location)) {
        return Routes.home;
      }
      return null;
  }
}

/// Re-runs the redirect whenever one of the app-scoped cubits changes.
class _StreamsListenable extends ChangeNotifier {
  _StreamsListenable(List<Stream<Object?>> streams) {
    for (final stream in streams) {
      _subscriptions.add(stream.listen((_) => notifyListeners()));
    }
  }

  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

GoRoute _draftRoute(String path, Widget Function(OnboardingDraft draft) build) => GoRoute(
  path: path,
  redirect: (_, state) => state.extra is OnboardingDraft ? null : Routes.welcome,
  pageBuilder: (_, state) => onboardingPage(state, build(state.extra! as OnboardingDraft)),
);

GoRouter createAppRouter({required SessionCubit session, required AppConfigCubit config}) {
  final refresh = Listenable.merge([
    _StreamsListenable([session.stream, config.stream]),
    splashIntroDone,
    startupAdDone,
  ]);
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (_, state) => resolveRedirect(
      location: state.matchedLocation,
      config: config.state,
      updateRequired: config.updateRequired,
      session: session.state,
      // The splash also waits for the cold-start App Open ad, if any.
      splashIntroDone: splashIntroDone.value && startupAdDone.value,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.maintenance, builder: (_, _) => const MaintenancePage()),
      GoRoute(path: Routes.update, builder: (_, _) => const UpdatePage()),
      GoRoute(path: Routes.offline, builder: (_, _) => const OfflinePage()),
      // Signed out
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (_, state) => onboardingPage(state, const WelcomePage()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) =>
            onboardingPage(state, LoginPage(initialEmail: state.extra as String?)),
      ),
      GoRoute(
        path: Routes.registerEmail,
        pageBuilder: (_, state) => onboardingPage(state, const EmailPage()),
      ),
      _draftRoute(Routes.registerOtp, (draft) => OtpPage(draft: draft)),
      _draftRoute(Routes.registerPassword, (draft) => PasswordPage(draft: draft)),
      _draftRoute(Routes.registerCharacter, (draft) => CharacterPage(draft: draft)),
      _draftRoute(Routes.forgotOtp, (draft) => OtpPage(draft: draft)),
      _draftRoute(Routes.forgotPassword, (draft) => PasswordPage(draft: draft)),
      // Signed in
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.categories, builder: (_, _) => const CategoriesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.wallet, builder: (_, _) => const WalletPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfilePage())],
          ),
        ],
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) => CategoryDetailsPage(
          categoryId: state.pathParameters['id']!,
          preview: state.extra is RewardCategory ? state.extra! as RewardCategory : null,
        ),
      ),
      GoRoute(path: Routes.giveaways, builder: (_, _) => const GiveawaysPage()),
      GoRoute(
        path: '/giveaway/:id',
        builder: (_, state) => GiveawayDetailsPage(giveawayId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.ticket,
        redirect: (_, state) => state.extra is TicketArgs ? null : Routes.myGiveaways,
        builder: (_, state) => TicketPage(args: state.extra! as TicketArgs),
      ),
      GoRoute(
        path: Routes.celebration,
        redirect: (_, state) => state.extra is Winning ? null : Routes.myGiveaways,
        builder: (_, state) => WinnerCelebrationPage(winning: state.extra! as Winning),
      ),
      GoRoute(path: Routes.myGiveaways, builder: (_, _) => const MyGiveawaysPage()),
      GoRoute(path: Routes.orders, builder: (_, _) => const OrdersPage()),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => OrderDetailsPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.notifications, builder: (_, _) => const InboxPage()),
      GoRoute(
        path: '/notification/:id',
        builder: (_, state) => NotificationDetailsPage(
          id: state.pathParameters['id']!,
          initial: state.extra is AppNotification ? state.extra! as AppNotification : null,
        ),
      ),
      GoRoute(path: Routes.transactions, builder: (_, _) => const TransactionsPage()),
      GoRoute(path: Routes.earn, builder: (_, _) => const EarnPage()),
      GoRoute(path: Routes.refer, builder: (_, _) => const ReferPage()),
      GoRoute(path: Routes.editProfile, builder: (_, _) => const EditProfilePage()),
      GoRoute(path: Routes.settings, builder: (_, _) => const AccountSettingsPage()),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordPage()),
      GoRoute(path: Routes.sessions, builder: (_, _) => const SessionsPage()),
      GoRoute(
        path: Routes.notificationSettings,
        builder: (_, _) => const NotificationPreferencesPage(),
      ),
      GoRoute(path: Routes.deleteAccount, builder: (_, _) => const DeleteAccountPage()),
      GoRoute(
        path: '/info/:kind',
        builder: (_, state) => InfoPage(
          kind: InfoKind.values.firstWhere(
            (kind) => kind.name == state.pathParameters['kind'],
            orElse: () => InfoKind.about,
          ),
        ),
      ),
    ],
  );
}
