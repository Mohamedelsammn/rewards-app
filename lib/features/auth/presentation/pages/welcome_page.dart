import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Container(
          decoration: const BoxDecoration(gradient: AppGradients.welcome),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: constraints.maxHeight * .57,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, .82, 1],
                  ).createShader(bounds),
                  child: Image.asset(
                    AppAssets.welcomeHero,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * (constraints.maxHeight < 700 ? .16 : .42),
                      ),
                      Text(
                        l10n.welcomeTitleTop,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: AppGradients.headline.createShader,
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          l10n.welcomeTitleBottom,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, color: AppColors.muted),
                      ),
                      const Spacer(),
                      GradientButton(
                        l10n.welcomeGetStarted,
                        dark: true,
                        onPressed: () => context.push(Routes.registerEmail),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => context.push(Routes.login),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: l10n.welcomeHaveAccount,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              TextSpan(
                                text: l10n.welcomeLogin,
                                style: const TextStyle(
                                  color: AppColors.violet,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
