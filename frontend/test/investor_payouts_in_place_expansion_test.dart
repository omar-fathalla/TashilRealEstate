import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/transfer_details_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
    LocaleController.setLocale(locale);
    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF3B82F6),
          tertiary: const Color(0xFFF59E0B),
        ),
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Investor Dashboard Payouts In-Place Expansion Tests', () {
    testWidgets('Tapping on a payout card expands in-place without opening TransferDetailsDialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      CountryController.setCountry('EG');

      await tester.pumpWidget(wrapWithApp(const InvestorDashboardView(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Switch to Payout Ledger tab (index 2: "سجل التحويلات")
      final payoutTabFinder = find.text('سجل التحويلات');
      expect(payoutTabFinder, findsOneWidget);
      await tester.tap(payoutTabFinder);
      await tester.pumpAndSettle();

      // Verify that initially the details dialog is NOT open
      expect(find.byType(TransferDetailsDialog), findsNothing);

      // Verify initial state: CIB-EG-998124 card exists
      final payoutCardFinder = find.textContaining('CIB-EG-998124');
      expect(payoutCardFinder, findsOneWidget);

      // Verify action buttons are not visible before expansion
      expect(find.text('تحميل إيصال الحوالة'), findsNothing);
      expect(find.text('مشاركة إشعار التحويل'), findsNothing);

      // Tap on the payout card row
      await tester.tap(payoutCardFinder);
      await tester.pumpAndSettle();

      // CRITICAL CHECK: Verify that NO modal dialog or TransferDetailsDialog was shown!
      expect(find.byType(TransferDetailsDialog), findsNothing);
      expect(find.byType(Dialog), findsNothing);

      // Verify that in-place expansion details are now visible
      expect(find.text('البنك التجاري الدولي'), findsWidgets);
      expect(find.text('تسوية مكتملة ومؤكدة'), findsOneWidget);
      expect(find.text('إيداع بنكي مباشر'), findsOneWidget);
      expect(find.text('رقم المرجع البنكي:'), findsOneWidget);
      expect(find.text('الحساب المصرفي المستلم:'), findsOneWidget);
      expect(find.text('الفاتورة الضريبية المرتبطة:'), findsOneWidget);
      expect(find.text('INV-998124'), findsOneWidget);

      // Verify Connected Button Group action toolbar is present
      expect(find.text('تحميل إيصال الحوالة'), findsOneWidget);
      expect(find.text('مشاركة إشعار التحويل'), findsOneWidget);
      expect(find.text('نسخ الرقم المرجعي'), findsOneWidget);

      // Tap download receipt action button and verify snackbar feedback
      await tester.tap(find.text('تحميل إيصال الحوالة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CIB-EG-998124'), findsWidgets);

      // Tap card again to collapse
      await tester.tap(find.textContaining('CIB-EG-998124').first);
      await tester.pumpAndSettle();

      // Verify collapsed: details are hidden
      expect(find.text('الفاتورة الضريبية المرتبطة:'), findsNothing);
      expect(find.text('تحميل إيصال الحوالة'), findsNothing);
    });

    testWidgets('Payout card expansion works seamlessly in English', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      CountryController.setCountry('EG');

      await tester.pumpWidget(wrapWithApp(const InvestorDashboardView(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Switch to Recent Payouts tab in English
      final loc = AppLocalizations(const Locale('en'));
      final payoutTabFinder = find.text(loc.tr('recentPayouts'));
      expect(payoutTabFinder, findsOneWidget);
      await tester.tap(payoutTabFinder);
      await tester.pumpAndSettle();

      // Find first payout card and tap it
      final payoutCardFinder = find.textContaining('CIB-EG-998124');
      expect(payoutCardFinder, findsOneWidget);
      await tester.tap(payoutCardFinder);
      await tester.pumpAndSettle();

      // Verify English expanded details
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Commercial International Bank'), findsWidgets);
      expect(find.text('Settled & Verified'), findsOneWidget);
      expect(find.text('Direct Bank Deposit'), findsOneWidget);
      expect(find.text('Bank Reference Number:'), findsOneWidget);
      expect(find.text('Download Transfer Receipt'), findsOneWidget);
      expect(find.text('Share Transfer Notice'), findsOneWidget);
      expect(find.text('Copy Reference'), findsOneWidget);
    });

    testWidgets('Payout card expansion works seamlessly in Hindi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      CountryController.setCountry('EG');

      await tester.pumpWidget(wrapWithApp(const InvestorDashboardView(), locale: const Locale('hi')));
      await tester.pumpAndSettle();

      // Switch to Recent Payouts tab in Hindi
      final loc = AppLocalizations(const Locale('hi'));
      final payoutTabFinder = find.text(loc.tr('recentPayouts'));
      expect(payoutTabFinder, findsOneWidget);
      await tester.ensureVisible(payoutTabFinder);
      await tester.tap(payoutTabFinder);
      await tester.pumpAndSettle();

      // Find first payout card and tap it
      final payoutCardFinder = find.textContaining('CIB-EG-998124');
      expect(payoutCardFinder, findsOneWidget);
      await tester.tap(payoutCardFinder);
      await tester.pumpAndSettle();

      // Verify Hindi expanded details
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('कमर्शियल इंटरनेशनल बैंक'), findsWidgets);
      expect(find.text('निपटान पूर्ण और सत्यापित'), findsOneWidget);
      expect(find.text('प्रत्यक्ष बैंक जमा'), findsOneWidget);
      expect(find.text('बैंक संदर्भ संख्या:'), findsOneWidget);
      expect(find.text('स्थानांतरण रसीद डाउनलोड करें'), findsOneWidget);
      expect(find.text('स्थानांतरण सूचना साझा करें'), findsOneWidget);
      expect(find.text('संदर्भ कॉपी करें'), findsOneWidget);
    });
  });
}
