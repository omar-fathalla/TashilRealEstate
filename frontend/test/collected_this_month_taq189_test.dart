// TAQ-189: the "collected this month" card counts this month's electronic payments only.
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/owner_portal/services/collected_this_month.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

RentInvoiceModel invoice(String id, {required String status, DateTime? paidAt, DateTime? due, String? method, double amount = 1000}) => RentInvoiceModel(
      id: id,
      invoiceNumber: id,
      contractNumber: 'L1',
      countryCode: 'AE',
      unitTitle: 'Unit',
      unitNumber: '',
      buildingName: '',
      district: '',
      tenant: const TenantInfo(name: 'T', phone: '', email: '', idNumber: ''),
      owner: const OwnerPayoutInfo(name: '', bankName: '', iban: '', accountNumber: ''),
      baseAmount: amount,
      dueDate: due ?? DateTime(2026, 11, 1),
      status: status,
      paidAt: paidAt,
      paymentMethod: method,
    );

void main() {
  final now = DateTime(2026, 11, 27);

  test('counts only paid electronic invoices of the current month', () {
    final total = collectedElectronicallyThisMonth([
      invoice('nov-card', status: 'paid', paidAt: DateTime(2026, 11, 3), method: 'card'),
      invoice('nov-none', status: 'paid', paidAt: DateTime(2026, 11, 20), amount: 500),
      invoice('oct-card', status: 'paid', paidAt: DateTime(2026, 10, 30), method: 'card', amount: 7000),
      invoice('nov-last-year', status: 'paid', paidAt: DateTime(2025, 11, 5), amount: 9000),
      invoice('nov-cash', status: 'paid', paidAt: DateTime(2026, 11, 4), method: 'cash', amount: 3000),
      invoice('nov-wire', status: 'paid', paidAt: DateTime(2026, 11, 4), method: 'bank_transfer', amount: 3000),
      invoice('nov-due', status: 'due_soon', due: DateTime(2026, 11, 28)),
    ], now);
    expect(total, 1500);
  });

  test('a paid invoice with no payment date counts by its due month', () {
    expect(collectedElectronicallyThisMonth([invoice('a', status: 'paid', due: DateTime(2026, 11, 1))], now), 1000);
    expect(collectedElectronicallyThisMonth([invoice('b', status: 'paid', due: DateTime(2026, 10, 1))], now), 0);
  });
}
