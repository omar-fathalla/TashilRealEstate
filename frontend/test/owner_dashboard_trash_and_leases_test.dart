import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_trash_view.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('ar'),
    String country = 'EG',
  }) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

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
        ),
      ),
      home: Scaffold(body: child),
    );
  }

  setUp(() {
    LegalClausesService().resetToDefaults();
    RentCollectionService().resetToDefaults();
  });

  group('Owner Dashboard - Trash Navigation Rail & Drawer Integration', () {
    testWidgets('Desktop Navigation Rail displays Trash destination with live dynamic badge', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create a soft-deleted invoice and a soft-deleted contract to verify badge
      final activeInvoices = RentCollectionService().getInvoicesForCountry('EG');
      if (activeInvoices.isNotEmpty) {
        RentCollectionService().softDeleteInvoice(activeInvoices.first.id);
      }
      final activeContracts = LegalClausesService().getActiveContractsForCountry('EG');
      if (activeContracts.isNotEmpty) {
        LegalClausesService().softDeleteContract(activeContracts.first.id);
      }

      await tester.pumpWidget(buildTestApp(
        child: const OwnerDashboard(),
        locale: const Locale('ar'),
        country: 'EG',
      ));
      await tester.pumpAndSettle();

      // Verify the Trash destination exists in rail
      final trashDestination = find.text('المحذوفات');
      expect(trashDestination, findsWidgets);

      // Verify live badge count equals total trashed items (1 invoice + 1 contract = 2)
      final badge2 = find.text('2');
      expect(badge2, findsWidgets);

      // Tap on Trash destination in rail to navigate to OwnerTrashView
      await tester.tap(trashDestination.first);
      await tester.pumpAndSettle();

      // Verify OwnerTrashView is rendered
      expect(find.byType(OwnerTrashView), findsOneWidget);
      expect(find.text('المحذوفات'), findsWidgets);
    });

    testWidgets('Trilingual parity: Trash destination appears accurately in Arabic, English, and Hindi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // English
      await tester.pumpWidget(buildTestApp(
        child: const OwnerDashboard(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Trash & Recycle Bin'), findsWidgets);

      // Hindi
      await tester.pumpWidget(buildTestApp(
        child: const OwnerDashboard(),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('कचरा और हटाए गए आइटम'), findsWidgets);
    });
  });

  group('Owner Trash View - Unified Invoices & Contracts Lifecycle', () {
    testWidgets('Displays both trashed invoices and trashed contracts with segment filtering', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Soft delete 1 invoice and 1 contract
      final activeInvoices = RentCollectionService().getInvoicesForCountry('EG');
      expect(activeInvoices, isNotEmpty);
      RentCollectionService().softDeleteInvoice(activeInvoices.first.id);

      final activeContracts = LegalClausesService().getActiveContractsForCountry('EG');
      expect(activeContracts, isNotEmpty);
      LegalClausesService().softDeleteContract(activeContracts.first.id);

      await tester.pumpWidget(buildTestApp(
        child: const OwnerTrashView(),
        locale: const Locale('ar'),
        country: 'EG',
      ));
      await tester.pumpAndSettle();

      // Verify segments in TashilConnectedButtonGroup (which include count badges)
      expect(find.textContaining('جميع المحذوفات'), findsWidgets);
      expect(find.textContaining('الفواتير المحذوفة'), findsWidgets);
      expect(find.textContaining('العقود المحذوفة'), findsWidgets);

      // Verify badges and labels
      expect(find.text('فاتورة تحصيل'), findsWidgets);
      expect(find.text('عقد إيجار'), findsWidgets);

      // Tap on 'العقود المحذوفة' filter segment inside TashilConnectedButtonGroup
      final contractsSegment = find.descendant(
        of: find.byType(TashilConnectedButtonGroup<String>),
        matching: find.textContaining('العقود المحذوفة'),
      );
      expect(contractsSegment, findsOneWidget);
      await tester.tap(contractsSegment);
      await tester.pumpAndSettle();

      // Contract should be visible, invoice hidden
      expect(find.text('عقد إيجار'), findsWidgets);
      expect(find.text('فاتورة تحصيل'), findsNothing);

      // Tap on 'الفواتير المحذوفة' filter segment inside TashilConnectedButtonGroup
      final invoicesSegment = find.descendant(
        of: find.byType(TashilConnectedButtonGroup<String>),
        matching: find.textContaining('الفواتير المحذوفة'),
      );
      expect(invoicesSegment, findsOneWidget);
      await tester.tap(invoicesSegment);
      await tester.pumpAndSettle();

      // Invoice should be visible, contract hidden
      expect(find.text('فاتورة تحصيل'), findsWidgets);
      expect(find.text('عقد إيجار'), findsNothing);
    });

    testWidgets('Restoring a trashed contract moves it back to active contracts', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeContracts = LegalClausesService().getActiveContractsForCountry('EG');
      final targetContract = activeContracts.first;
      LegalClausesService().softDeleteContract(targetContract.id);

      expect(LegalClausesService().getDeletedContractsForCountry('EG').length, 1);

      await tester.pumpWidget(buildTestApp(
        child: const OwnerTrashView(),
        locale: const Locale('ar'),
        country: 'EG',
      ));
      await tester.pumpAndSettle();

      // Tap restore on contract
      final restoreBtn = find.widgetWithText(TashilButton, 'استعادة');
      expect(restoreBtn, findsWidgets);
      await tester.tap(restoreBtn.first);
      await tester.pumpAndSettle();

      // Contract should now be restored
      expect(LegalClausesService().getDeletedContractsForCountry('EG'), isEmpty);
      expect(LegalClausesService().getActiveContractsForCountry('EG').any((c) => c.id == targetContract.id), isTrue);
    });
  });

  group('Leases Management View - Edit and Delete Contracts', () {
    testWidgets('Contract card contains Edit ("تعديل") and Delete ("حذف") buttons in ConnectedButtonGroup', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: const LeasesManagementView(),
        locale: const Locale('ar'),
        country: 'EG',
      ));
      await tester.pumpAndSettle();

      // Verify contract card action buttons exist
      expect(find.text('تعديل العقد'), findsWidgets);
      expect(find.text('حذف العقد'), findsWidgets);
    });

    testWidgets('Deleting a contract prompts confirmation dialog, soft deletes contract, and shows undo SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialActiveCount = LegalClausesService().getActiveContractsForCountry('EG').length;
      expect(initialActiveCount, greaterThan(0));

      await tester.pumpWidget(buildTestApp(
        child: const LeasesManagementView(),
        locale: const Locale('ar'),
        country: 'EG',
      ));
      await tester.pumpAndSettle();

      // Tap "حذف العقد" button on the first contract card
      final deleteBtn = find.text('حذف العقد').first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify TashilAlertDialog confirmation appears
      expect(find.text('تأكيد نقل العقد إلى المحذوفات'), findsOneWidget);
      expect(find.text('هل أنت متأكد من نقل هذا العقد إلى المحذوفات؟ ستظل نسخته محفوظة لمدة 7 أيام ويمكنك استعادتها.'), findsOneWidget);

      // Confirm deletion
      final confirmDeleteAction = find.descendant(
        of: find.byType(TashilAlertDialog),
        matching: find.text('حذف العقد'),
      );
      expect(confirmDeleteAction, findsOneWidget);
      await tester.tap(confirmDeleteAction);
      await tester.pumpAndSettle();

      // Verify contract was soft-deleted
      final updatedActiveCount = LegalClausesService().getActiveContractsForCountry('EG').length;
      expect(updatedActiveCount, equals(initialActiveCount - 1));
      expect(LegalClausesService().getDeletedContractsForCountry('EG').length, equals(1));

      // Verify SnackBar appeared with undo action
      expect(find.text('تم نقل العقد إلى المحذوفات بنجاح'), findsOneWidget);
      expect(find.text('استعادة'), findsOneWidget);

      // Tap Undo ("استعادة") in SnackBar
      await tester.tap(find.text('استعادة'));
      await tester.pumpAndSettle();

      // Verify contract is restored
      expect(LegalClausesService().getActiveContractsForCountry('EG').length, equals(initialActiveCount));
      expect(LegalClausesService().getDeletedContractsForCountry('EG'), isEmpty);
    });
  });
}
