import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/profile_repository.dart';

/// A character image: the server URL when set, otherwise the bundled art.
class CharacterImage extends StatelessWidget {
  const CharacterImage({
    required this.avatarId,
    this.imageUrl,
    this.alignment = Alignment.center,
    super.key,
  });

  final int? avatarId;
  final String? imageUrl;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => AppImage(
    url: imageUrl,
    fallbackAsset: AppAssets.character(avatarId ?? 1),
    alignment: alignment,
  );
}

/// The selectable 3-column character grid (onboarding and edit profile).
class CharacterGrid extends StatelessWidget {
  const CharacterGrid({
    required this.avatars,
    required this.selected,
    required this.onSelected,
    this.spacing = 13,
    super.key,
  });

  final List<Avatar> avatars;
  final int? selected;
  final ValueChanged<int> onSelected;
  final double spacing;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(4, 5, 8, 8),
    itemCount: avatars.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
    ),
    itemBuilder: (_, index) {
      final avatar = avatars[index];
      final isSelected = selected == avatar.id;
      return Semantics(
        button: true,
        selected: isSelected,
        label: context.l10n.characterOption(index + 1),
        child: InkWell(
          onTap: () => onSelected(avatar.id),
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: isSelected ? AppColors.violet : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CharacterImage(avatarId: avatar.id, imageUrl: avatar.imageUrl),
                  ),
                ),
              ),
              if (isSelected)
                const PositionedDirectional(
                  end: -4,
                  top: -4,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.violet,
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
