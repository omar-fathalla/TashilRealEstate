import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/config/demo_data.dart';
import 'package:tashil_real_estate/core/config/firebase_emulator.dart';
import 'package:tashil_real_estate/core/config/screenshot_hooks.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/core/theme/tashil_banner_colors.dart';
import 'package:tashil_real_estate/features/brokers/broker_profile_screen.dart';
import 'package:tashil_real_estate/features/brokers/broker_repository.dart';
import 'package:tashil_real_estate/features/brokers/models/broker_profile.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production builds do not publish sample listings or fake permits', () {
    expect(DemoData.enabled, isFalse);
    expect(FirebaseEmulatorConfig.enabled, isFalse);
    expect(ScreenshotHooks.enabled, isFalse);
    expect(ScreenshotHooks.details, isNull);
    expect(ScreenshotHooks.legalEmirate, isNull);
    expect(PropertyItem.marketplaceSamples, isEmpty);
    final dubai = PropertyItem.sampleProperties.where((item) => item.cityCode == 'dubai');
    expect(dubai, isNotEmpty);
    for (final item in dubai) {
      expect(item.isSample, isTrue);
      expect(item.advertisingPermitNumber, isEmpty);
    }
  });

  test('dark hero bands use container roles', () {
    final scheme = AppTheme.getTheme(brightness: Brightness.dark).colorScheme;
    final colors = TashilBannerColors.gradient(scheme);
    expect(colors, [scheme.surfaceContainer, scheme.primaryContainer]);
    expect(TashilBannerColors.foreground(scheme), scheme.onPrimaryContainer);
    final light = AppTheme.getTheme(brightness: Brightness.light).colorScheme;
    expect(TashilBannerColors.gradient(light).first, light.primary);
    expect(TashilBannerColors.foreground(light), light.onPrimary);
  });

  test('logged-out visitors may open a broker profile', () {
    expect(
      RouteAccess.redirect(
        isLoggedIn: false,
        role: null,
        roleKnown: false,
        location: '/brokers/broker-demo-marina',
      ),
      isNull,
    );
  });

  test('dark surfaces come from the seed and meet WCAG AA for body text', () {
    const seed = Color(0xFF0F172A);
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final theme = AppTheme.getTheme(seedColor: seed, brightness: brightness);
      final scheme = theme.colorScheme;
      final surfaces = [
        scheme.surface,
        scheme.surfaceDim,
        scheme.surfaceBright,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ];
      for (final surface in surfaces) {
        expect(_contrast(scheme.onSurface, surface), greaterThanOrEqualTo(4.5));
        expect(surface.toARGB32() == 0xFF000000, isFalse);
      }
      if (brightness == Brightness.dark) {
        expect(theme.cardTheme.color, scheme.surfaceContainerLow);
        expect(theme.appBarTheme.backgroundColor, scheme.surface);
        expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
        expect(theme.navigationBarTheme.backgroundColor, scheme.surfaceContainer);
      }
    }
  });

  testWidgets('a sample listing shows the sample badge and no permit QR', (tester) async {
    LocaleController.setLocale(const Locale('ar'));
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final sample = PropertyItem.sampleProperties.firstWhere((item) => item.cityCode == 'dubai');
    await tester.pumpWidget(_app(Center(child: SizedBox(width: 460, child: PropertyCard(property: sample)))));
    await tester.pump();
    expect(find.text('إعلان تجريبي'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('broker profile shows the registration number beside the office ORN', (tester) async {
    LocaleController.setLocale(const Locale('en'));
    BrokerRepository().upsert(BrokerProfile.marinaDemo);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(const BrokerProfileScreen(brokerId: 'broker-demo-marina')));
    await tester.pumpAndSettle();
    expect(find.text('Layla Al Mansoori'), findsOneWidget);
    expect(find.text('Broker registration number: BR-48291'), findsOneWidget);
    expect(find.text('Office registration number (ORN): ORN-1044'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    final chips = tester.widgetList<TashilAssistChip>(find.byType(TashilAssistChip));
    expect(chips.length, 3);
    for (final chip in chips) {
      expect(chip.height, 48);
      expect(chip.enabled, isTrue);
    }
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpWidget(_app(const BrokerProfileScreen(brokerId: 'broker-demo-marina')));
    await tester.pumpAndSettle();
    expect(find.text('Layla Al Mansoori'), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: LocaleController.currentLocale.value,
    theme: AppTheme.getTheme(brightness: Brightness.light),
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance();
  final darker = background.computeLuminance();
  final hi = lighter > darker ? lighter : darker;
  final lo = lighter > darker ? darker : lighter;
  return (hi + 0.05) / (lo + 0.05);
}
