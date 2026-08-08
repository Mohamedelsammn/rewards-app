import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../role_selection/presentation/role_selection_page.dart';
import '../../user_home/presentation/user_home_shell.dart';
import 'cubit/splash_cubit.dart';
import 'cubit/splash_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashCubit(getIt(), getIt())..bootstrap(),
      child: BlocListener<SplashCubit, SplashState>(
        listenWhen: (previous, current) => !previous.isReady && current.isReady,
        listener: (context, state) {
          final page = switch (state.destination!) {
            SplashDestination.roleSelection => const RoleSelectionPage(),
            SplashDestination.userHome => const UserHomeShell(),
          };
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
        },
        child: const _SplashBody(),
      ),
    );
  }
}

/// Deliberately minimal: just the logo animation and the app name
/// underneath it, nothing else -- no tagline, no loading indicator, no
/// cards. The Lottie animation itself communicates "the app is starting."
class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 280, child: Lottie.asset('assets/lottie/splash.json', repeat: true)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.appName, style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
