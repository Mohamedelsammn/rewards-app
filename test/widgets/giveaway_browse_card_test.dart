import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/features/user_home/presentation/user_home_page.dart';
import 'package:rewardsapp/l10n/generated/app_localizations.dart';
import 'package:rewardsapp/shared/models/giveaway.dart';
import 'package:rewardsapp/shared/widgets/app_network_image.dart';

Giveaway _giveaway(String id) {
  final now = DateTime.now();
  return Giveaway(
    id: id,
    title: 'Product $id',
    organizerName: 'Organizer',
    prizeDescription: '',
    descriptionRules: '',
    imageUrl: null,
    startDate: now.subtract(const Duration(days: 1)),
    endDate: now.add(const Duration(days: 3)),
    endTime: '18:00',
    status: GiveawayStatus.active,
    numberDigitWidth: 4,
    maxParticipants: null,
    participantCount: 12,
  );
}

void main() {
  for (final width in [320.0, 360.0, 393.0, 430.0]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('product image stays undistorted at $width dp in ${locale.languageCode}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 700);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: (width - 32) / 2,
                  height: 240,
                  child: GiveawayBrowseCard(giveaway: _giveaway('$width')),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final image = tester.widget<AppNetworkImage>(find.byType(AppNetworkImage));
        expect(image.fit, BoxFit.contain);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
