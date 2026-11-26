import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

import '../models/portfolio_models.dart';
import 'portfolio_controller.dart';

/// Turns the real leases, payments (`Transactions`) and receipts (`Invoices`) into the monthly
/// rent rows the Rent Collection and Financials screens show. Nothing here is invented: a row
/// exists because an active lease owes that month, or because the server recorded a payment for it.
///
/// - The month an active lease owes follows the lease: from its start month (at most the last 12
///   months) up to the current month, plus next month once it is within 30 days of falling due.
/// - A month is paid only when `Transactions/{leaseId}_{YYYY-MM}` says `paid`.
/// - Ended leases keep their paid months as history and owe nothing.
/// - There is no late penalty: the server charges none, so none is shown.
class RentScheduleBuilder {
  RentScheduleBuilder._();

  static const int historyMonths = 12;
  static const int upcomingWindowDays = 30;
  static const int graceDays = 5;

  static String periodOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime? _parseDay(String raw) {
    if (raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static DateTime _dueDate(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  static List<RentInvoiceModel> build(PortfolioSnapshot snapshot, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final txByKey = <String, PortfolioTransaction>{};
    for (final tx in snapshot.transactions) {
      if (tx.leaseId.isEmpty || tx.period.isEmpty) continue;
      final key = '${tx.leaseId}_${tx.period}';
      final seen = txByKey[key];
      if (seen == null || (tx.isPaid && !seen.isPaid)) txByKey[key] = tx;
    }
    final receiptByTx = <String, PortfolioInvoice>{};
    for (final inv in snapshot.invoices) {
      if (inv.transactionId.isNotEmpty) receiptByTx[inv.transactionId] = inv;
    }

    final out = <RentInvoiceModel>[];
    for (final lease in snapshot.leases) {
      if (!lease.isActive && !lease.isEnded) continue;
      final start = _parseDay(lease.startDate);
      if (start == null || lease.monthlyRent <= 0) continue;
      final end = _parseDay(lease.endDate);
      final dueDay = start.day;

      final periods = <String>{};
      if (lease.isActive) {
        final earliest = DateTime(today.year, today.month - (historyMonths - 1), 1);
        var cursor = DateTime(start.year, start.month, 1);
        if (cursor.isBefore(earliest)) cursor = earliest;
        final nextMonth = DateTime(today.year, today.month + 1, 1);
        while (!cursor.isAfter(nextMonth)) {
          final due = _dueDate(cursor.year, cursor.month, dueDay);
          final afterEnd = end != null && DateTime(cursor.year, cursor.month, 1).isAfter(DateTime(end.year, end.month, 1));
          final tooFarAhead = due.isAfter(today.add(const Duration(days: upcomingWindowDays)));
          if (!afterEnd && !tooFarAhead) periods.add(periodOf(cursor));
          cursor = DateTime(cursor.year, cursor.month + 1, 1);
        }
      }
      for (final entry in txByKey.entries) {
        if (entry.value.leaseId == lease.id && entry.value.isPaid) periods.add(entry.value.period);
      }

      for (final period in periods) {
        final year = int.tryParse(period.substring(0, 4));
        final month = int.tryParse(period.substring(5, 7));
        if (year == null || month == null) continue;
        final tx = txByKey['${lease.id}_$period'];
        final paidTx = (tx != null && tx.isPaid) ? tx : null;
        final paid = paidTx != null;
        final receipt = paidTx == null ? null : receiptByTx[paidTx.id];
        final due = _dueDate(year, month, dueDay);
        final overdue = !paid && today.isAfter(due.add(const Duration(days: graceDays)));
        final base = paidTx != null && paidTx.amount > 0 ? paidTx.amount : lease.monthlyRent;
        final deductedPercent = receipt != null && receipt.amount > 0
            ? ((receipt.amount - receipt.ownerPayout) / receipt.amount * 100).clamp(0, 100).toDouble()
            : 0.0;

        out.add(RentInvoiceModel(
          id: 'inv_${lease.id}_$period',
          invoiceNumber: paidTx != null && paidTx.invoiceNumber.isNotEmpty
              ? paidTx.invoiceNumber
              : (receipt != null && receipt.invoiceNumber.isNotEmpty ? receipt.invoiceNumber : 'TASHIL-INV-${lease.id}_$period'),
          contractNumber: lease.id,
          countryCode: lease.countryCode,
          unitTitle: lease.propertyTitle,
          unitNumber: '',
          buildingName: '',
          district: '',
          tenant: TenantInfo(name: lease.tenantName, phone: '', email: '', idNumber: ''),
          owner: const OwnerPayoutInfo(name: '', bankName: '', iban: '', accountNumber: ''),
          baseAmount: base,
          dueDate: due,
          gracePeriodDays: graceDays,
          dailyPenaltyRate: 0,
          propertyId: lease.propertyId,
          monthKey: period,
          status: paid ? 'paid' : (overdue ? 'overdue' : 'due_soon'),
          paidAt: paidTx == null ? null : (paidTx.paidAt ?? due),
          paymentMethod: paidTx != null && paidTx.method.isNotEmpty ? paidTx.method : null,
          transactionReference: paidTx != null && paidTx.reference.isNotEmpty ? paidTx.reference : null,
          platformFeePercent: deductedPercent,
          payoutStatus: paid ? 'transferred_to_owner' : 'pending',
        ));
      }
    }
    out.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return out;
  }
}
