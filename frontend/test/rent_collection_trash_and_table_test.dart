import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';

void main() {
  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.setLocale(const Locale('ar'));
    RentCollectionService().resetToDefaults();
  });

  tearDown(() {
    RentCollectionService().resetToDefaults();
  });

  group('RentInvoiceModel Trash & 7-Day Retention Tests', () {
    test('Defaults to not deleted with null deletedAt', () {
      final inv = RentInvoiceModel(
        id: 'INV-TEST-001',
        invoiceNumber: 'INV-EG-2026-9901',
        contractNumber: 'EG-2026-CAI-9901',
        unitNumber: '101',
        unitTitle: 'شقة تجريبية',
        buildingName: 'برج النيل',
        district: 'المعادي',
        tenant: const TenantInfo(
          name: 'أحمد علي',
          phone: '01000000000',
          email: 'ahmed@test.com',
          idNumber: '29001011234567',
        ),
        owner: const OwnerPayoutInfo(
          name: 'عمر طارق',
          bankName: 'البنك الأهلي',
          iban: 'EG00000',
          accountNumber: '123456',
        ),
        baseAmount: 5000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'due_soon',
        countryCode: 'EG',
      );

      expect(inv.isDeleted, isFalse);
      expect(inv.deletedAt, isNull);
      expect(inv.remainingDaysBeforePermanentDelete, 7);
      expect(inv.permanentDeleteAt, isNull);
    });

    test('Computes remaining days correctly when deleted', () {
      final deletedTwoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final inv = RentInvoiceModel(
        id: 'INV-TEST-002',
        invoiceNumber: 'INV-EG-2026-9902',
        contractNumber: 'EG-2026-CAI-9902',
        unitNumber: '102',
        unitTitle: 'شقة اختبار',
        buildingName: 'برج النيل',
        district: 'المعادي',
        tenant: const TenantInfo(
          name: 'محمود حسن',
          phone: '01111111111',
          email: 'mahmoud@test.com',
          idNumber: '29001011234568',
        ),
        owner: const OwnerPayoutInfo(
          name: 'عمر طارق',
          bankName: 'البنك الأهلي',
          iban: 'EG00000',
          accountNumber: '123456',
        ),
        baseAmount: 6000,
        dueDate: DateTime.now(),
        status: 'paid',
        countryCode: 'EG',
        isDeleted: true,
        deletedAt: deletedTwoDaysAgo,
      );

      expect(inv.isDeleted, isTrue);
      expect(inv.deletedAt, equals(deletedTwoDaysAgo));
      expect(inv.permanentDeleteAt, isNotNull);
      // 7 - 2 = 5 days remaining
      expect(inv.remainingDaysBeforePermanentDelete, inInclusiveRange(4, 5));
    });
  });

  group('RentCollectionService Soft-Delete, Restore & Auto-Purge Tests', () {
    test('Soft delete moves invoice to trash and updates counts', () {
      final service = RentCollectionService();
      final initialActive = service.getInvoicesForCountry('EG');
      expect(initialActive.isNotEmpty, isTrue);
      final initialCount = initialActive.length;

      final targetId = initialActive.first.id;
      service.softDeleteInvoice(targetId);

      final activeAfter = service.getInvoicesForCountry('EG');
      expect(activeAfter.length, initialCount - 1);
      expect(activeAfter.any((inv) => inv.id == targetId), isFalse);

      final trash = service.getDeletedInvoicesForCountry('EG');
      expect(trash.any((inv) => inv.id == targetId), isTrue);
    });

    test('Restore returns soft-deleted invoice to active collection', () {
      final service = RentCollectionService();
      final activeBefore = service.getInvoicesForCountry('EG');
      final targetId = activeBefore.first.id;

      service.softDeleteInvoice(targetId);
      expect(service.getInvoicesForCountry('EG').any((inv) => inv.id == targetId), isFalse);

      service.restoreInvoice(targetId);

      final activeAfter = service.getInvoicesForCountry('EG');
      expect(activeAfter.any((inv) => inv.id == targetId), isTrue);
      final trashAfter = service.getDeletedInvoicesForCountry('EG');
      expect(trashAfter.any((inv) => inv.id == targetId), isFalse);
    });

    test('Permanently delete removes invoice from system entirely', () {
      final service = RentCollectionService();
      final activeBefore = service.getInvoicesForCountry('EG');
      final targetId = activeBefore.first.id;

      service.softDeleteInvoice(targetId);
      service.permanentlyDeleteInvoice(targetId);

      expect(service.getInvoicesForCountry('EG').any((inv) => inv.id == targetId), isFalse);
      expect(service.getDeletedInvoicesForCountry('EG').any((inv) => inv.id == targetId), isFalse);
    });

    test('Empty trash purges all soft-deleted invoices', () {
      final service = RentCollectionService();
      final active = service.getInvoicesForCountry('EG');
      service.softDeleteInvoice(active[0].id);
      service.softDeleteInvoice(active[1].id);

      expect(service.getDeletedInvoicesForCountry('EG').length, 2);

      service.emptyTrash(countryCode: 'EG');
      expect(service.getDeletedInvoicesForCountry('EG').isEmpty, isTrue);
    });

    test('Auto-purge removes invoices older than 7 days and preserves newer ones', () {
      final service = RentCollectionService();
      final active = service.getInvoicesForCountry('EG');
      final recentId = active[0].id;
      final oldId = active[1].id;

      // Soft delete recent (now)
      service.softDeleteInvoice(recentId);

      // Soft delete old (simulated 8 days ago)
      service.softDeleteInvoice(oldId);
      final list = List<RentInvoiceModel>.from(service.invoicesNotifier.value);
      final oldIndex = list.indexWhere((inv) => inv.id == oldId);
      list[oldIndex] = list[oldIndex].copyWith(
        deletedAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      service.invoicesNotifier.value = list;

      // Run auto-purge
      service.purgeExpiredDeletedInvoices();

      // Old invoice is gone
      expect(service.invoicesNotifier.value.any((inv) => inv.id == oldId), isFalse);
      // Recent invoice remains in trash
      expect(service.getDeletedInvoicesForCountry('EG').any((inv) => inv.id == recentId), isTrue);
    });

    test('Update invoice modifies base amount, due date and notes', () {
      final service = RentCollectionService();
      final active = service.getInvoicesForCountry('EG');
      final targetId = active.first.id;
      final newDueDate = DateTime(2027, 5, 1);

      service.updateInvoice(
        invoiceId: targetId,
        baseAmount: 9500,
        dueDate: newDueDate,
        notes: 'ملاحظة تم تعديلها تجريبياً',
      );

      final inv = service.invoicesNotifier.value.firstWhere((i) => i.id == targetId);
      expect(inv.baseAmount, 9500);
      expect(inv.dueDate, newDueDate);
      expect(inv.notes, 'ملاحظة تم تعديلها تجريبياً');
    });

    test('Soft-deleted invoices persist in LocalStorage and remain in trash across sync', () {
      final service = RentCollectionService();
      final active = service.getInvoicesForCountry('EG');
      final target = active.first;

      // Soft delete
      service.softDeleteInvoice(target.id);
      expect(service.getDeletedInvoicesForCountry('EG').any((i) => i.id == target.id), isTrue);
      expect(service.getInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);

      // Re-trigger sync (simulating page reload or property changes)
      service.syncFromProperties();

      // Must remain soft-deleted
      expect(service.getDeletedInvoicesForCountry('EG').any((i) => i.id == target.id), isTrue);
      expect(service.getInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);
    });

    test('Permanently deleted invoices persist in LocalStorage and do not resurrect on sync', () {
      final service = RentCollectionService();
      final active = service.getInvoicesForCountry('EG');
      final target = active.first;

      // Permanently delete
      service.permanentlyDeleteInvoice(target.id);
      expect(service.getInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);
      expect(service.getDeletedInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);

      // Re-trigger sync (simulating page reload or property updates)
      service.syncFromProperties();

      // Must NOT resurrect
      expect(service.getInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);
      expect(service.getDeletedInvoicesForCountry('EG').any((i) => i.id == target.id), isFalse);
    });
  });

  group('Rent Collection UI - Trash & Merged Column Tests', () {
    Widget buildTestApp({Locale locale = const Locale('ar')}) {
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
          ),
        ),
        home: const Scaffold(
          body: RentCollectionView(),
        ),
      );
    }

    testWidgets('Merged column displays Unit title on top and Invoice No. below', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify merged column header exists
      expect(find.text('الوحدة ورقم الفاتورة'), findsOneWidget);

      // Verify both unit title and invoice Number are rendered
      final service = RentCollectionService();
      final firstInv = service.getInvoicesForCountry('EG').first;

      expect(find.text(firstInv.unitTitle), findsWidgets);
      expect(find.text(firstInv.invoiceNumber), findsWidgets);
    });

    testWidgets('Header displays Trash button and toggles to Trash View', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Soft delete one invoice first
      final service = RentCollectionService();
      final firstInv = service.getInvoicesForCountry('EG').first;
      service.softDeleteInvoice(firstInv.id);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Trash button should be visible in header with badge (1)
      final trashBtn = find.text('المحذوفات (1)');
      expect(trashBtn, findsOneWidget);

      // Tap trash button to open Trash View
      await tester.tap(trashBtn);
      await tester.pumpAndSettle();

      // Trash view should show deleted invoice title and 7-day auto-delete badge
      expect(find.text('المحذوفات'), findsWidgets);
      expect(find.text('إفراغ المحذوفات'), findsOneWidget);
      expect(find.text('العودة إلى التحصيلات'), findsWidgets);
      expect(find.text(firstInv.unitTitle), findsOneWidget);
      expect(find.textContaining(firstInv.invoiceNumber), findsWidgets);

      // Verify restore button exists
      expect(find.text('استعادة'), findsOneWidget);

      // Tap restore button
      await tester.tap(find.text('استعادة'));
      await tester.pumpAndSettle();

      // Trash is now empty
      expect(find.text('المحذوفات فارغة'), findsOneWidget);

      // Tap back to rent collection
      await tester.tap(find.text('العودة إلى التحصيلات').first);
      await tester.pumpAndSettle();

      // Back on active table view
      expect(find.text('الوحدة ورقم الفاتورة'), findsOneWidget);
    });

    testWidgets('Trash view and merged columns render cleanly in English', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocaleController.setLocale(const Locale('ar'));
      });

      // Soft delete one invoice
      final service = RentCollectionService();
      final firstInv = service.getInvoicesForCountry('EG').first;
      service.softDeleteInvoice(firstInv.id);

      // Test English
      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Unit & Invoice No.'), findsOneWidget);
      expect(find.text('Trash & Deleted Invoices (1)'), findsOneWidget);

      await tester.tap(find.text('Trash & Deleted Invoices (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Trash & Deleted Invoices'), findsWidgets);
      expect(find.text('Empty Trash'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('Trash view and merged columns render cleanly in Hindi', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocaleController.setLocale(const Locale('ar'));
      });

      // Soft delete one invoice
      final service = RentCollectionService();
      final firstInv = service.getInvoicesForCountry('EG').first;
      service.softDeleteInvoice(firstInv.id);

      // Test Hindi
      await tester.pumpWidget(buildTestApp(locale: const Locale('hi')));
      await tester.pumpAndSettle();
      expect(find.text('इकाई और चालान संख्या'), findsOneWidget);
      expect(find.text('हटाए गए चालान (1)'), findsOneWidget);

      await tester.tap(find.text('हटाए गए चालान (1)'));
      await tester.pumpAndSettle();
      expect(find.text('हटाए गए चालान'), findsWidgets);
      expect(find.text('कचरा खाली करें'), findsOneWidget);
      expect(find.byIcon(Icons.restore_rounded), findsOneWidget);
    });
  });
}
