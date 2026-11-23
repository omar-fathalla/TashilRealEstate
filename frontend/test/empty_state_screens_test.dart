import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/payment_schedule_screen.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/tenant_checkout_screen.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/monthly_payment_schedule_dialog.dart';

// TAQ-61: /checkout and /payment-schedule must show an empty state, not "Bad state: No element".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<RentInvoiceModel> savedInvoices;
  late List<ManagedPropertyModel> savedProperties;

  setUp(() {
    savedInvoices = RentCollectionService().invoicesNotifier.value;
    savedProperties = PropertyLifecycleService().propertiesNotifier.value;
  });

  tearDown(() {
    RentCollectionService().invoicesNotifier.value = savedInvoices;
    PropertyLifecycleService().propertiesNotifier.value = savedProperties;
  });

  Widget app(Widget screen, {required String path, Locale locale = const Locale('en')}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry('EG');
    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(path: path, builder: (_, __) => screen),
        GoRoute(path: '/tenant', builder: (_, __) => const Scaffold(body: Text('tenant dashboard'))),
        GoRoute(path: '/owner', builder: (_, __) => const Scaffold(body: Text('owner dashboard'))),
        GoRoute(path: '/fast-onboarding', builder: (_, __) => const Scaffold(body: Text('add property'))),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A))),
    );
  }

  String tr(String key, String lang) => AppLocalizations(Locale(lang)).tr(key);

  void expectNoBadState(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Bad state'), findsNothing);
  }

  group('checkout screen', () {
    testWidgets('shows the empty state when the tenant has no invoices (en, ar, hi)', (tester) async {
      RentCollectionService().invoicesNotifier.value = [];
      for (final lang in ['en', 'ar', 'hi']) {
        await tester.pumpWidget(app(const TenantCheckoutScreen(), path: '/checkout', locale: Locale(lang)));
        await tester.pumpAndSettle();
        expectNoBadState(tester);
        expect(find.byType(TashilEmptyState), findsOneWidget, reason: lang);
        expect(find.text(tr('checkoutEmptyTitle', lang)), findsOneWidget, reason: lang);
        expect(find.text(tr('checkoutEmptyMessage', lang)), findsOneWidget, reason: lang);
        expect(find.byType(TenantCheckoutDialog), findsNothing);
      }
    });

    testWidgets('the action is a 48dp target that goes to the dashboard', (tester) async {
      RentCollectionService().invoicesNotifier.value = [];
      await tester.pumpWidget(app(const TenantCheckoutScreen(), path: '/checkout'));
      await tester.pumpAndSettle();
      final action = find.text(tr('backToDashboard', 'en'));
      expect(action, findsOneWidget);
      final button = find.ancestor(of: action, matching: find.byType(TashilButton));
      expect(tester.getSize(button.first).height, greaterThanOrEqualTo(48));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('tenant dashboard'), findsOneWidget);
    });

    testWidgets('the empty state is laid out right-to-left in Arabic', (tester) async {
      RentCollectionService().invoicesNotifier.value = [];
      await tester.pumpWidget(app(const TenantCheckoutScreen(), path: '/checkout', locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(find.byType(TashilEmptyState))), TextDirection.rtl);
    });

    testWidgets('an unknown invoice id shows the not-found state', (tester) async {
      await tester.pumpWidget(app(const TenantCheckoutScreen(invoiceId: 'does-not-exist'), path: '/checkout'));
      await tester.pumpAndSettle();
      expectNoBadState(tester);
      expect(find.text(tr('checkoutInvoiceNotFoundTitle', 'en')), findsOneWidget);
      expect(find.byType(TenantCheckoutDialog), findsNothing);
    });

    testWidgets('a known invoice id still opens the checkout form', (tester) async {
      RentCollectionService().resetToDefaults();
      final invoice = RentCollectionService().invoicesNotifier.value.first;
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(TenantCheckoutScreen(invoiceId: invoice.id), path: '/checkout'));
      await tester.pumpAndSettle();
      expectNoBadState(tester);
      expect(find.byType(TenantCheckoutDialog), findsOneWidget);
      expect(find.byType(TashilEmptyState), findsNothing);
    });

    test('resolveInvoice never throws and prefers the selected country', () {
      expect(TenantCheckoutScreen.resolveInvoice(const [], 'EG'), isNull);
      expect(TenantCheckoutScreen.resolveInvoice(const [], 'EG', invoiceId: 'x'), isNull);
      RentCollectionService().resetToDefaults();
      final invoices = RentCollectionService().invoicesNotifier.value;
      final ae = invoices.firstWhere((i) => i.countryCode == 'AE');
      expect(TenantCheckoutScreen.resolveInvoice(invoices, 'AE')!.countryCode, 'AE');
      expect(TenantCheckoutScreen.resolveInvoice(invoices, 'AE', invoiceId: ae.id), ae);
      expect(TenantCheckoutScreen.resolveInvoice(invoices, 'AE', invoiceId: 'missing'), isNull);
      expect(TenantCheckoutScreen.resolveInvoice([ae], 'EG'), ae);
    });
  });

  group('payment schedule screen', () {
    testWidgets('shows the empty state when the owner has no properties (en, ar, hi)', (tester) async {
      PropertyLifecycleService().propertiesNotifier.value = [];
      for (final lang in ['en', 'ar', 'hi']) {
        await tester.pumpWidget(app(const PaymentScheduleScreen(), path: '/payment-schedule', locale: Locale(lang)));
        await tester.pumpAndSettle();
        expectNoBadState(tester);
        expect(find.byType(TashilEmptyState), findsOneWidget, reason: lang);
        expect(find.text(tr('scheduleEmptyTitle', lang)), findsOneWidget, reason: lang);
        expect(find.text(tr('scheduleEmptyMessage', lang)), findsOneWidget, reason: lang);
        expect(find.byType(MonthlyPaymentScheduleDialog), findsNothing);
      }
    });

    testWidgets('the actions are 48dp targets: add a property, or go to the dashboard', (tester) async {
      PropertyLifecycleService().propertiesNotifier.value = [];
      await tester.pumpWidget(app(const PaymentScheduleScreen(), path: '/payment-schedule'));
      await tester.pumpAndSettle();
      for (final label in [tr('addProperty', 'en'), tr('backToDashboard', 'en')]) {
        final action = find.text(label);
        expect(action, findsOneWidget);
        final button = find.ancestor(of: action, matching: find.byType(TashilButton));
        expect(tester.getSize(button.first).height, greaterThanOrEqualTo(48), reason: label);
      }
      await tester.tap(find.text(tr('addProperty', 'en')));
      await tester.pumpAndSettle();
      expect(find.text('add property'), findsOneWidget);
    });

    testWidgets('an unknown property id shows the not-found state', (tester) async {
      await tester.pumpWidget(app(const PaymentScheduleScreen(propertyId: 'does-not-exist'), path: '/payment-schedule'));
      await tester.pumpAndSettle();
      expectNoBadState(tester);
      expect(find.text(tr('schedulePropertyNotFoundTitle', 'en')), findsOneWidget);
      expect(find.byType(MonthlyPaymentScheduleDialog), findsNothing);
      await tester.tap(find.text(tr('backToDashboard', 'en')));
      await tester.pumpAndSettle();
      expect(find.text('owner dashboard'), findsOneWidget);
    });

    test('resolveProperty never throws', () {
      expect(PaymentScheduleScreen.resolveProperty(const [], 'EG'), isNull);
      expect(PaymentScheduleScreen.resolveProperty(const [], 'EG', propertyId: 'x'), isNull);
    });
  });
}
