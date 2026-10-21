import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/environment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/l10n.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../../features/app_config/presentation/app_config_cubit.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';

/// Branded splash shown while `/app-config` and the session load.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppGradients.splash),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(flex: 5, child: Image.asset(AppAssets.splashHero, fit: BoxFit.contain)),
            const Text(
              'Creative',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const Text(
              'Rewards',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.violet),
            ),
            Text(
              context.l10n.splashTagline,
              style: const TextStyle(fontSize: 18, color: AppColors.muted),
            ),
            const Spacer(),
            const SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            const SizedBox(height: 55),
          ],
        ),
      ),
    ),
  );
}

/// Shared layout of the blocking screens.
class _BlockingView extends StatelessWidget {
  const _BlockingView({required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppGradients.splash),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 84, color: AppColors.violet),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.5),
                ),
                if (action != null) ...[const SizedBox(height: 28), action!],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppConfigCubit>();
    final message = cubit.state.config.maintenanceMessage.of(context);
    return _BlockingView(
      icon: Icons.construction_rounded,
      title: context.l10n.maintenanceTitle,
      body: message.isNotEmpty ? message : context.l10n.maintenanceBody,
      action: GradientButton(context.l10n.commonRetry, onPressed: cubit.load),
    );
  }
}

class UpdatePage extends StatelessWidget {
  const UpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = context.watch<AppConfigCubit>().state.config.storeUrl;
    return _BlockingView(
      icon: Icons.system_update_rounded,
      title: context.l10n.updateTitle,
      body: context.l10n.updateBody,
      action: GradientButton(
        context.l10n.updateButton,
        onPressed: () => launchUrl(
          Uri.parse(configured.isEmpty ? AppConstants.playStoreUrl : configured),
          mode: LaunchMode.externalApplication,
        ),
      ),
    );
  }
}

/// Startup could not reach the API (config or session restore).
class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    final config = context.read<AppConfigCubit>();
    final session = context.read<SessionCubit>();
    try {
      if (config.state.status != AppConfigStatus.ready) await config.load();
      if (session.state.status == SessionStatus.offline) await session.restore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _BlockingView(
    icon: Icons.wifi_off_rounded,
    title: context.l10n.offlineTitle,
    body: context.l10n.offlineBody,
    action: GradientButton(context.l10n.commonRetry, busy: _busy, onPressed: _retry),
  );
}

/// Standalone app shown when the build configuration is unusable (wrong
/// `DATA_MODE`, missing or insecure `API_BASE_URL`). Nothing else starts.
class ServiceUnavailableApp extends StatelessWidget {
  const ServiceUnavailableApp({required this.issue, super.key});

  final EnvironmentIssue issue;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    supportedLocales: kSupportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => _BlockingView(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.serviceUnavailableTitle,
        body: issue == EnvironmentIssue.insecureApiUrl
            ? context.l10n.serviceInsecureBody
            : context.l10n.serviceUnavailableBody,
      ),
    ),
  );
}
