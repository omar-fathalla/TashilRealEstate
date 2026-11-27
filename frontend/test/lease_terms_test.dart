import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/rent_schedule_builder.dart';

// TAQ-164: the optional lease terms reach the rent rows: tenant phone, payout bank, and the flat
// late fee once a month is past its grace days (0 by default, so nothing changes without it).
void main() {
  PortfolioLease withTerms(Map<String, dynamic> extra) => PortfolioLease.fromMap('l1', {
        'status': 'active',
        'property_id': 'p1',
        'property_title': 'Flat 1',
        'tenant_name': 'Sara',
        'monthly_rent': 5000,
        'country_code': 'AE',
        'start_date': '2026-10-10',
        'end_date': '2099-10-09',
        ...extra,
      });

  List<RentInvoiceModel> rows(PortfolioLease lease, DateTime now) =>
      RentScheduleBuilder.build(PortfolioSnapshot(load: PortfolioLoad.ready, leases: [lease]), now: now);

  test('the lease parses the optional terms with safe defaults', () {
    final plain = withTerms({});
    expect(plain.lateFeeAmount, 0);
    expect(plain.lateFeeGraceDays, 5);
    expect(plain.tenantPhone, '');
    final full = withTerms({'late_fee_amount': 250, 'late_fee_grace_days': 2, 'tenant_phone': '+971501234567', 'payout_bank_name': 'FAB', 'payout_iban': 'AE070331234567890123456'});
    expect(full.lateFeeAmount, 250);
    expect(full.lateFeeGraceDays, 2);
    expect(withTerms({'late_fee_amount': -3, 'late_fee_grace_days': 99}).lateFeeAmount, 0);
    expect(withTerms({'late_fee_grace_days': 99}).lateFeeGraceDays, 5);
  });

  test('rows carry the tenant phone and the payout bank', () {
    final r = rows(withTerms({'tenant_phone': '+971501234567', 'payout_bank_name': 'FAB', 'payout_iban': 'AE070331234567890123456'}), DateTime(2026, 11, 26));
    expect(r.first.tenant.phone, '+971501234567');
    expect(r.first.owner.bankName, 'FAB');
    expect(r.first.owner.iban, 'AE070331234567890123456');
  });

  test('the flat fee is added after the grace days, never without a fee, never on a paid month', () {
    final lease = withTerms({'late_fee_amount': 250, 'late_fee_grace_days': 5});
    // November is due on the 10th; grace to the 15th; the fee from the 16th.
    final on15 = rows(lease, DateTime(2026, 11, 15, 12)).singleWhere((r) => r.monthKey == '2026-11');
    expect(on15.latePenaltyAmount, 0);
    final on16 = rows(lease, DateTime(2026, 11, 16, 12)).singleWhere((r) => r.monthKey == '2026-11');
    expect(on16.latePenaltyAmount, 250);
    expect(on16.totalAmountDue, 5250);
    final none = rows(withTerms({}), DateTime(2027, 3, 1)).where((r) => r.status == 'overdue');
    expect(none, isNotEmpty);
    expect(none.every((r) => r.latePenaltyAmount == 0), isTrue);
    final paid = RentScheduleBuilder.build(
      PortfolioSnapshot(load: PortfolioLoad.ready, leases: [lease], transactions: [
        PortfolioTransaction(id: 'l1_2026-10', leaseId: 'l1', period: '2026-10', amount: 5250, status: 'paid', paidAt: DateTime(2026, 10, 20)),
      ]),
      now: DateTime(2026, 11, 26),
    ).singleWhere((r) => r.monthKey == '2026-10');
    expect(paid.latePenaltyAmount, 0);
  });

  test('the late-fee and IBAN refusals map to their messages', () {
    expect(leaseCreateErrorKey('late_fee_invalid'), 'ldLateFeeInvalid');
    expect(leaseCreateErrorKey('iban_invalid'), 'ldIbanInvalid');
  });
}
