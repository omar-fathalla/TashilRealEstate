import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rent Collection and Property Lifecycle Two-Way Synchronization', () {
    late PropertyLifecycleService propertyService;
    late RentCollectionService rentService;

    setUp(() {
      propertyService = PropertyLifecycleService();
      rentService = RentCollectionService();
    });

    test('Properties from PropertyLifecycleService generate live invoices in RentCollectionService', () {
      // 1. Trigger sync
      rentService.syncFromProperties();

      final invoices = rentService.invoicesNotifier.value;
      final properties = propertyService.propertiesNotifier.value;

      // Filter properties that have installments
      final occupiedProps = properties.where((p) => p.isOccupied && p.installments.isNotEmpty);

      for (final prop in occupiedProps) {
        for (final inst in prop.installments) {
          final matchingInvoice = invoices.firstWhere(
            (inv) => inv.propertyId == prop.id && inv.monthKey == inst.monthKey,
            orElse: () => throw Exception('Missing invoice for ${prop.id} - ${inst.monthKey}'),
          );

          expect(matchingInvoice.baseAmount, equals(inst.amount));
          expect(matchingInvoice.countryCode, equals(prop.countryCode));
          expect(matchingInvoice.unitNumber, isNotEmpty);
        }
      }
    });

    test('Paying an installment in PropertyLifecycleService syncs to RentCollectionService invoice', () async {
      final properties = propertyService.propertiesNotifier.value;
      final rentedProp = properties.firstWhere(
        (p) => p.isOccupied && p.installments.any((i) => !i.isPaid),
      );
      final unpaidInst = rentedProp.installments.firstWhere((i) => !i.isPaid);

      // Record payment in PropertyLifecycleService
      await propertyService.recordInstallmentPayment(
        propertyId: rentedProp.id,
        monthKey: unpaidInst.monthKey,
        status: InstallmentPaymentStatus.paidOnline,
        paymentMethod: 'visa',
        notes: 'سداد تجريبي سريع',
      );

      // Verify that RentCollectionService invoice is now paid
      final updatedInvoices = rentService.invoicesNotifier.value;
      final invoice = updatedInvoices.firstWhere(
        (inv) => inv.propertyId == rentedProp.id && inv.monthKey == unpaidInst.monthKey,
      );

      expect(invoice.status, equals('paid'));
      expect(invoice.paymentMethod, equals('visa'));
      expect(invoice.payoutStatus, equals('transferred_to_owner'));
      expect(invoice.paidAt, isNotNull);
    });

    test('Paying an invoice in RentCollectionService syncs back to PropertyLifecycleService installment', () async {
      // Find or create an invoice with propertyId and monthKey
      final now = DateTime.now();
      final monthKey = '${now.year}-${(now.month + 2).toString().padLeft(2, '0')}';
      const testPropId = 'prop-eg-101';

      final newInvoice = RentInvoiceModel(
        id: 'test_inv_sync_100',
        invoiceNumber: 'INV-EG-2026-TEST100',
        contractNumber: 'EG-2026-CAI-9988',
        countryCode: 'EG',
        unitTitle: 'وحدة التجمع للاختبار',
        unitNumber: '505',
        buildingName: 'برج النرجس',
        district: 'التجمع الخامس',
        propertyId: testPropId,
        monthKey: monthKey,
        tenant: const TenantInfo(
          name: 'محمد عبد الله',
          phone: '+201099887766',
          email: 'mohamed@test.com',
          idNumber: '29001011234567',
        ),
        owner: const OwnerPayoutInfo(
          name: 'م. عمر طارق فتح الله',
          bankName: 'البنك الأهلي المصري (NBE)',
          iban: 'EG380003000012345678901234567',
          accountNumber: '10994821',
          walletOrVpa: 'omar.fathalla@instapay',
        ),
        baseAmount: 18000,
        dueDate: now.add(const Duration(days: 10)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 50,
        status: 'due_soon',
        platformFeePercent: 1.5,
        payoutStatus: 'pending',
      );

      rentService.addInvoice(newInvoice);

      // Verify that installment was added to PropertyLifecycleService
      final prop = propertyService.propertiesNotifier.value.firstWhere((p) => p.id == testPropId);
      final inst = prop.installments.firstWhere((i) => i.monthKey == monthKey);
      expect(inst.amount, equals(18000));
      expect(inst.isPaid, isFalse);

      // Now pay the invoice through RentCollectionService
      await rentService.payInvoice(
        invoiceId: newInvoice.id,
        paymentMethod: 'meeza_card',
        transactionReference: 'REF-TX-SYNC-777',
      );

      // Verify that PropertyLifecycleService updated the installment to paid
      final updatedProp = propertyService.propertiesNotifier.value.firstWhere((p) => p.id == testPropId);
      final updatedInst = updatedProp.installments.firstWhere((i) => i.monthKey == monthKey);
      expect(updatedInst.isPaid, isTrue);
      expect(updatedInst.paymentMethod, equals('meeza_card'));
      expect(updatedInst.notes, contains('REF-TX-SYNC-777'));
    });
  });
}
