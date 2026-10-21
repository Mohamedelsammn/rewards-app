import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Regression test for the "No Material widget found" crash that hit
/// AdminProfilePage (and, before that, the User Home search field and
/// Settings page): `GlassScaffold` renders its body on a
/// `CupertinoPageScaffold`, which -- unlike Material's `Scaffold` -- supplies
/// no implicit `Material` ancestor, so any Material widget (`ListTile`,
/// `TextField`, ...) hosted directly in a shell's `body` throws.
///
/// `UserHomeShell` and `AdminShell` now wrap their `IndexedStack` body in a
/// single `Material(type: MaterialType.transparency)` (see those files) so
/// every current and future hosted page gets a valid ancestor for free. This
/// test mirrors that exact shell shape to guard the pattern itself, without
/// needing the full DI graph either shell's real pages depend on.
void main() {
  Widget shellBody({required bool withMaterialAncestor}) {
    final indexedStack = const IndexedStack(
      index: 0,
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: ListTile(title: Text('Sign out')),
        ),
      ],
    );
    return MaterialApp(
      home: GlassScaffold(
        body: withMaterialAncestor
            ? Material(type: MaterialType.transparency, child: indexedStack)
            : indexedStack,
      ),
    );
  }

  testWidgets('a ListTile hosted in a shell body throws without a Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(shellBody(withMaterialAncestor: false));
    await tester.pump();

    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('the same ListTile renders cleanly once the shell wraps its body in Material '
      '(the fix applied to UserHomeShell/AdminShell)', (tester) async {
    await tester.pumpWidget(shellBody(withMaterialAncestor: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(ListTile, 'Sign out'), findsOneWidget);
  });
}
