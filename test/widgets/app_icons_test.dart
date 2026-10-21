import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/theme/app_icons.dart';

void main() {
  test('legacy category emoji and named icons resolve to the same vector family', () {
    for (final pair in [
      ('📱', 'smartphone'),
      ('🎧', 'electronics'),
      ('🎮', 'gaming'),
      ('⌚', 'watch'),
      ('🏠', 'home'),
    ]) {
      expect(AppIcons.category(pair.$1), AppIcons.category(pair.$2));
      expect(AppIcons.category(pair.$1).fontFamily, 'Lucide');
    }
  });
  test('unknown, empty and absent category icons have a safe vector fallback', () {
    for (final value in [null, '', 'unrecognized-icon', 'unexpected emoji']) {
      expect(AppIcons.category(value), AppIcons.categories);
    }
  });
}
