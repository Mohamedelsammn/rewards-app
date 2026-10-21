import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../auth/domain/entities/app_user.dart';
import 'character_avatar.dart';

/// Profile header from design_references/profile-page.png: soft game art,
/// a glass character frame with the edit button on its edge, and the light
/// content sheet rising as a dome into the art. Offsets are measured from
/// the status-bar inset.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, super.key});

  final AppUser user;

  /// Ends just below the email; the stats card follows 8 px later (at the
  /// reference's 224).
  static const height = 216.0;
  static const _artHeight = 150.0;

  /// The frame's base sinks into the dome's crest (frame bottom at 159,
  /// dome top at 153.5) so the bubble overlaps the art and the sheet.
  static const _frameTop = 26.0;
  static const _frameWidth = 138.0;
  static const _frameHeight = 133.0;
  static const _editSize = 42.0;
  static const _domeTop = 153.5;
  static const _domeRise = 38.0;
  static const _nameTop = 163.0;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final halfWidth = MediaQuery.sizeOf(context).width / 2;
    // The name and email lines (~50 at 1.0) grow with the text scale.
    final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
    return SizedBox(
      height: inset + height + 50 * (scale - 1),
      child: Stack(
        children: [
          // Base: the art's top color behind the status bar, its bottom color
          // behind the dome, so the band has no visible edges.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.profileHeaderTop, AppColors.profileHeaderBottom],
                  stops: [.3, .75],
                ),
              ),
            ),
          ),
          // The art band sits below the status bar, left-anchored so the
          // coin stays on the left and the gamepad clears the frame.
          Positioned(
            top: inset - 6,
            left: 0,
            right: 0,
            height: _artHeight,
            child: Image.asset(
              AppAssets.profileHeader,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          // Blend the art's top edge into the status-bar area and soften it.
          Positioned(
            top: inset - 6,
            left: 0,
            right: 0,
            height: 44,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.profileHeaderTop, AppColors.profileHeaderTopClear],
                ),
              ),
            ),
          ),
          // ...and its bottom edge into the color behind the dome.
          Positioned(
            top: inset - 6 + _artHeight - 40,
            left: 0,
            right: 0,
            height: 40,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.profileHeaderBottomClear, AppColors.profileHeaderBottom],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: AppColors.profileArtWash)),
          // Content sheet rising into the art as a wide dome.
          Positioned(
            top: inset + _domeTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.pale,
                borderRadius: BorderRadius.vertical(top: Radius.elliptical(halfWidth, _domeRise)),
              ),
            ),
          ),
          // Soft white haze where the frame meets the dome, blending the
          // bubble into the sheet (a gradient, no blur).
          Positioned(
            // Centered on the frame's bottom edge.
            top: inset + _frameTop + _frameHeight - 60,
            left: 0,
            right: 0,
            height: 120,
            child: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(2.4, 1, 1),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.profileFrameHaze, AppColors.profileFrameHazeClear],
                        stops: [.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: inset + _frameTop,
            left: 0,
            right: 0,
            child: Center(child: _CharacterFrame(user: user)),
          ),
          Positioned(
            top: inset + _nameTop,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    // Fixed line heights keep the header math independent of
                    // the fallback font (e.g. Arabic locales).
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.profileEmail,
                    fontSize: 14.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass frame with the character and the edit button centered on the
/// trailing edge. The button lies inside this widget's bounds so its whole
/// circle is tappable.
class _CharacterFrame extends StatelessWidget {
  const _CharacterFrame({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    const half = ProfileHeader._editSize / 2;
    return SizedBox(
      width: ProfileHeader._frameWidth + ProfileHeader._editSize,
      // Room below the frame for the edit button's shadow.
      height: ProfileHeader._frameHeight + 6,
      child: Stack(
        children: [
          PositionedDirectional(
            start: half,
            top: 0,
            width: ProfileHeader._frameWidth,
            height: ProfileHeader._frameHeight,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.profileFrameGlass,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.profileFrameBorder, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CharacterImage(
                  avatarId: user.avatarId,
                  imageUrl: user.avatarImageUrl,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 91,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: AppColors.profileEditShadow,
              child: IconButton(
                tooltip: context.l10n.profileEditTooltip,
                onPressed: () => context.push(Routes.editProfile),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(ProfileHeader._editSize),
                  minimumSize: const Size.square(ProfileHeader._editSize),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(AppIcons.edit, size: 19, color: AppColors.violet),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
