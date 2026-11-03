import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/config/firebase_emulator.dart';
import 'package:tashil_real_estate/core/config/screenshot_hooks.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/core/utils/content_sized_grid.dart';
import 'package:tashil_real_estate/core/utils/coordinate_format.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';
import 'package:tashil_real_estate/features/fast_onboarding/fast_onboarding_screen.dart';
import 'package:tashil_real_estate/features/investor_dashboard/models/investor_portfolio_model.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_overview_view.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/features/smart_valuation/widgets/district_location_picker_dialog.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_login_screen.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_home_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home, {Locale locale = const Locale('ar'), double textScale = 1}) {
    LocaleController.setLocale(locale);
    return MaterialApp(
      locale: locale,
      theme: AppTheme.getTheme(brightness: Brightness.light, locale: locale),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home,
    );
  }

  void setSurface(WidgetTester tester, Size size, {double inset = 0}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: inset);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
  }

  test('emulator mode only allows loopback Firebase hosts', () {
    expect(FirebaseEmulatorConfig.isLoopbackHost('127.0.0.1'), isTrue);
    expect(FirebaseEmulatorConfig.isLoopbackHost('127.0.0.2'), isTrue);
    expect(FirebaseEmulatorConfig.isLoopbackHost('localhost'), isTrue);
    expect(FirebaseEmulatorConfig.isLoopbackHost('identitytoolkit.googleapis.com'), isFalse);
    expect(FirebaseEmulatorConfig.isLoopbackHost('firestore.googleapis.com'), isFalse);
    expect(FirebaseEmulatorConfig.isLoopbackHost('firebase.googleapis.com'), isFalse);
    expect(FirebaseEmulatorConfig.authOriginFor('127.0.0.2'), 'http://127.0.0.2:9099');
    expect(
      () => FirebaseEmulatorConfig.authOriginFor('identitytoolkit.googleapis.com'),
      throwsStateError,
    );
    expect(ScreenshotHooks.parseTextScale('2'), 2);
    expect(ScreenshotHooks.parseTextScale('2.0'), 2);
    expect(ScreenshotHooks.parseTextScale('9'), isNull);
  });

  test('coordinates stay latitude then longitude inside an LTR isolate', () {
    final text = formatLatLng(25.081, 55.140);
    expect(text, '\u206625.081, 55.140\u2069');
    expect(text.indexOf('25.081'), lessThan(text.indexOf('55.140')));
  });

  test('an investor email is not labeled as a portfolio owner', () {
    LocaleController.setLocale(const Locale('ar'));
    String tr(String key) => AppLocalizations.trStatic(key);
    expect(headerRoleTitleForEmail('investor@demo.tashil.test', tr), 'مستثمر');
    expect(headerRoleTitleForEmail('owner@demo.tashil.test', tr), tr('ownerRoleTitle'));
    expect(tr('officeRegistrationNumberLabel'), 'رقم المكتب (ORN)');
  });

  testWidgets('focused add-listing fields stay above the keyboard', (tester) async {
    Future<void> check(Size size) async {
      setSurface(tester, size, inset: 280);
      await tester.pumpWidget(app(const FastOnboardingScreen()));
      await tester.pump();
      final fields = find.byType(TextField);
      expect(fields, findsWidgets);
      final limit = size.height - 280;
      final count = tester.widgetList<TextField>(fields).length;
      for (var i = 0; i < count; i++) {
        final finder = fields.at(i);
        tester.widget<TextField>(finder).focusNode?.requestFocus();
        await tester.pump();
        await tester.pump();
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(-1), reason: 'field $i at $size');
        expect(rect.bottom, lessThanOrEqualTo(limit + 1), reason: 'field $i at $size');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }

    await check(const Size(360, 640));
    await check(const Size(768, 1024));
  });

  testWidgets('focused login fields stay above the keyboard', (tester) async {
    Future<void> check(Size size) async {
      setSurface(tester, size, inset: 300);
      await tester.pumpWidget(app(const LoginScreen()));
      await tester.pump();
      final fields = find.byType(TextField);
      expect(fields, findsWidgets);
      final limit = size.height - 300;
      for (var i = 0; i < tester.widgetList<TextField>(fields).length; i++) {
        final finder = fields.at(i);
        tester.widget<TextField>(finder).focusNode?.requestFocus();
        await tester.pump();
        await tester.pump();
        final rect = tester.getRect(finder);
        expect(rect.bottom, lessThanOrEqualTo(limit + 1));
        expect(rect.top, greaterThanOrEqualTo(-1));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }

    await check(const Size(360, 640));
    await check(const Size(768, 1024));
  });

  testWidgets('scale 2 labels wrap instead of clipping', (tester) async {
    setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(app(const LoginScreen(), textScale: 2));
    await tester.pump();
    void expectFullyVisible(String label) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label).first);
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      final textRect = tester.getRect(find.text(label).first);
      expect(textRect.width, greaterThan(8), reason: label);
    }

    expectFullyVisible(AppLocalizations.trStatic('signIn'));
    expectFullyVisible('Google');
    expectFullyVisible('Apple');

    await tester.pumpWidget(app(const FastOnboardingScreen(), textScale: 2));
    await tester.pump();
    expectFullyVisible(AppLocalizations.trStatic('publishPropertyDirectBtn'));
    expectFullyVisible(AppLocalizations.trStatic('startVoiceDictationBtn'));

    await tester.pumpWidget(app(const Scaffold(body: OwnerOverviewView()), textScale: 2));
    await tester.pump();
    expectFullyVisible(AppLocalizations.trStatic('aiValuationBannerTitle'));

    await tester.pumpWidget(app(const Scaffold(body: TenantHomeView()), textScale: 2));
    await tester.pump();
    expectFullyVisible('مرحباً، كريم سامي');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('legal notice and valuation are dialogs from 600dp up', (tester) async {
    setSurface(tester, const Size(768, 1024));
    await tester.pumpWidget(app(_DialogOpener(
      open: (context) => LegalWarningNoticeDialog.show(
        context,
        ScreenshotHooks.demoLegalInvoice('dubai'),
      ),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    setSurface(tester, const Size(768, 1024));
    CountryController.setCountry('AE');
    await tester.pumpWidget(app(_DialogOpener(
      open: (context) => SmartValuationDialog.show(context),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(localizedUaeCityName('ar'), 'دبي مارينا');
    expect(localizedUaeCityName('en'), 'Dubai Marina');

    setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => LegalWarningNoticeDialog.show(
            context,
            ScreenshotHooks.demoLegalInvoice('dubai'),
          ),
          child: const Text('open-legal-phone'),
        ),
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('open-legal-phone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('targets are at least 48dp and Arabic district copy is local', (tester) async {
    setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(app(
      Scaffold(
        body: Column(
          children: [
            TashilFilterChip(label: 'دبي مارينا', selected: true, onSelected: (_) {}),
            TashilConnectedIconButtonGroup(
              items: [
                TashilConnectedIconItem(icon: Icons.star, tooltip: 'star', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
    expect(tester.getSize(find.byType(TashilFilterChip)).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byType(TashilConnectedIconButtonGroup)).height, greaterThanOrEqualTo(48));

    await tester.pumpWidget(app(const SuperAdminLoginScreen()));
    await tester.pump();
    final forgot = find.text(AppLocalizations.trStatic('forgotPassword'));
    final button = find.ancestor(of: forgot, matching: find.byType(TextButton));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));

    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => DistrictLocationPickerDialog.show(context, countryCode: 'AE'),
          child: const Text('open-district'),
        ),
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('open-district'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('دبي الرئيسية ومارينا'), findsOneWidget);
    expect(find.text('Dubai Prime & Marina'), findsNothing);
    expect(find.text(AppLocalizations.trStatic('useCurrentGpsLocation')), findsOneWidget);
    final locate = tester.renderObject<RenderParagraph>(
      find.text(AppLocalizations.trStatic('useCurrentGpsLocation')),
    );
    expect(locate.didExceedMaxLines, isFalse);
    expect(find.textContaining('\u2066'), findsWidgets);
  });

  testWidgets('home filter chips wrap inside 320dp', (tester) async {
    setSurface(tester, const Size(320, 568));
    await tester.pumpWidget(app(
      Scaffold(
        body: TashilConnectedButtonGroup<String>(
          selectedValue: 'all',
          onSelectionChanged: _noop,
          segments: const [
            TashilConnectedButtonSegment(value: 'all', label: 'الكل', icon: Icons.grid_view),
            TashilConnectedButtonSegment(value: 'featured', label: 'مميزة', icon: Icons.star),
            TashilConnectedButtonSegment(value: 'furnished', label: 'مفروشة فقط', icon: Icons.chair),
          ],
        ),
      ),
    ));
    await tester.pump();
    final rect = tester.getRect(find.text('مفروشة فقط'));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.left, greaterThanOrEqualTo(0));
  });

  testWidgets('empty amenities heading is hidden and stat cards hug their content', (tester) async {
    setSurface(tester, const Size(768, 1024));
    final property = PropertyItem(
      id: 'empty-amenities',
      titles: const {'ar': 'شقة', 'en': 'Apartment', 'hi': 'अपार्टमेंट'},
      descriptions: const {'ar': 'وصف', 'en': 'Description', 'hi': 'विवरण'},
      propertyTypeCode: 'apartment',
      locations: const {'ar': 'دبي مارينا', 'en': 'Dubai Marina', 'hi': 'दुबई मरीना'},
      cityCode: 'dubai',
      pricePerMonth: 1000,
      bedrooms: 1,
      bathrooms: 1,
      areaSqM: 50,
      imageUrls: const [],
      amenitiesMap: const {'ar': [], 'en': [], 'hi': []},
      agencyNames: const {'ar': 'وكالة', 'en': 'Agency', 'hi': 'एजेंसी'},
    );
    await tester.pumpWidget(app(PropertyDetailsDialog(property: property, asPage: true)));
    await tester.pump();
    expect(find.text(AppLocalizations.trStatic('amenities')), findsNothing);

    await tester.pumpWidget(app(
      const Scaffold(
        body: ContentSizedGrid(
          maxWidth: 700,
          columns: 2,
          spacing: 14,
          children: [
            SizedBox(height: 88, child: Text('kpi-a')),
            SizedBox(height: 88, child: Text('kpi-b')),
          ],
        ),
      ),
    ));
    await tester.pump();
    expect(tester.getSize(find.text('kpi-a')).height, lessThan(120));
  });

  testWidgets('an empty investor portfolio hides the reorder hint', (tester) async {
    setSurface(tester, const Size(800, 1400));
    const empty = InvestorPortfolioSummary(
      countryCode: 'AE',
      totalPortfolioValue: 0,
      totalPurchaseCost: 0,
      grossAnnualRentalIncome: 0,
      annualOperatingExpenses: 0,
      netAnnualCashFlow: 0,
      portfolioGrossYield: 0,
      portfolioNetRoi: 0,
      portfolioCapitalGrowthRate: 0,
      occupancyRate: 0,
      totalUnitsCount: 0,
      occupiedUnitsCount: 0,
      vacantUnitsCount: 0,
      assets: [],
      cashFlowHistory: [],
    );
    await tester.pumpWidget(app(const InvestorDashboardView(testSummary: empty), locale: const Locale('en')));
    await tester.pump();
    LocaleController.setLocale(const Locale('en'));
    expect(find.text(AppLocalizations.trStatic('reorderableListHint')), findsNothing);
  });
}

void _noop(String value) {}

class _DialogOpener extends StatefulWidget {
  final void Function(BuildContext context) open;
  const _DialogOpener({required this.open});

  @override
  State<_DialogOpener> createState() => _DialogOpenerState();
}

class _DialogOpenerState extends State<_DialogOpener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.open(context);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
