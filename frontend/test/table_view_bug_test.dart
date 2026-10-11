import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';

Widget wrapWithApp({required Widget child, Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
    ),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OwnerPropertiesView Table View loads and hovers without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    LocaleController.setLanguage('ar');
    CountryController.setCountry('EG');

    await tester.pumpWidget(wrapWithApp(child: const OwnerDashboard()));
    await tester.pumpAndSettle();

    // Click on "عقاراتي" (myProperties) in Navigation Rail to switch to OwnerPropertiesView
    final myPropsNav = find.text('عقاراتي');
    if (myPropsNav.evaluate().isNotEmpty) {
      await tester.tap(myPropsNav.first);
      await tester.pumpAndSettle();
    }

    // Verify we are on Table View (which is default)
    expect(find.text('عرض الجدول'), findsOneWidget);

    // Hover over table rows
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 300));
    await gesture.moveTo(const Offset(500, 400));
    await tester.pump();
    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();

    // Check if exception occurred
    expect(tester.takeException(), isNull);
  });
}
