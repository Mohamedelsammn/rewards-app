import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// Tab-level title with an optional trailing action.
class PanelTitle extends StatelessWidget {
  const PanelTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
      ?action,
    ],
  );
}

class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => Navigator.of(context).maybePop(),
    style: IconButton.styleFrom(
      backgroundColor: AppColors.backButton,
      foregroundColor: AppColors.ink,
      minimumSize: const Size(48, 48),
    ),
    // Material arrows mirror themselves in RTL.
    icon: const Icon(Icons.arrow_back),
  );
}

class CircleArrow extends StatelessWidget {
  const CircleArrow({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: const BoxDecoration(color: AppColors.circleArrow, shape: BoxShape.circle),
    child: Icon(
      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
      color: AppColors.ink,
    ),
  );
}

/// Title block of secondary screens (My Orders, My Giveaways, …) with an
/// optional decorative illustration.
class SecondaryHeader extends StatelessWidget {
  const SecondaryHeader({
    required this.title,
    required this.subtitle,
    this.art,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final HeaderArt? art;
  final Widget? action;

  /// Below the back button; the header grows when a long title wraps
  /// instead of pushing the title up into the button.
  static const _textTop = 58.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Stack(
      children: [
        if (art != null) PositionedDirectional(top: -12, end: 0, child: art!),
        const PositionedDirectional(top: 0, start: 0, child: CircleBackButton()),
        if (action != null) PositionedDirectional(top: 0, end: 0, child: action!),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: art == null ? 132 : 170),
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: _textTop, end: art == null ? 0 : 65),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

enum HeaderArtKind { gift, bag }

class HeaderArt extends StatelessWidget {
  const HeaderArt(this.kind, {super.key});

  final HeaderArtKind kind;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipOval(
      child: SizedBox(
        width: 154,
        height: 152,
        child: OverflowBox(
          alignment: kind == HeaderArtKind.bag ? Alignment.topLeft : Alignment.center,
          maxWidth: 330,
          maxHeight: 330,
          child: Image.asset(AppAssets.welcomeHero, width: 330, height: 330, fit: BoxFit.cover),
        ),
      ),
    ),
  );
}
