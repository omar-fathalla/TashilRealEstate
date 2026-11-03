import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/navigation_bar/tashil_navigation_bar.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/features/public_marketplace/public_marketplace_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
  ];

  for (final size in viewports) {
    testWidgets(
      'home body stays visible and the navigation bar sits on the bottom at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        LocaleController.setLocale(const Locale('ar'));
        CountryController.setCountry('AE');
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            theme: AppTheme.getTheme(
                brightness: Brightness.light, locale: const Locale('ar')),
            supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PublicMarketplaceScreen(),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        final hero = find.text(AppLocalizations.trStatic('heroTitle_ae'));
        expect(hero, findsOneWidget);
        final heroRect = tester.getRect(hero);
        expect(heroRect.height, greaterThan(8));
        expect(heroRect.top, greaterThanOrEqualTo(0));
        expect(heroRect.top, lessThan(size.height * 0.5));

        expect(find.textContaining(AppLocalizations.trStatic('availableUnits')),
            findsOneWidget);
        expect(
            find.text(AppLocalizations.trStatic('navExplore')), findsOneWidget);

        final bar = find.byType(TashilNavigationBar);
        expect(bar, findsOneWidget);
        final barRect = tester.getRect(bar);
        expect(barRect.bottom, closeTo(size.height, 1));
        expect(barRect.top, greaterThan(size.height * 0.75));
        expect(barRect.height, inInclusiveRange(80, 140));
        expect(heroRect.bottom, lessThan(barRect.top));

        final heroBox = tester.renderObject(hero);
        final hit = tester.hitTestOnBinding(heroRect.center);
        expect(
          hit.path.any((entry) => entry.target == heroBox),
          isTrue,
          reason:
              'hero is clipped or covered at ${size.width.toInt()}x${size.height.toInt()}',
        );
      },
    );
  }
}
