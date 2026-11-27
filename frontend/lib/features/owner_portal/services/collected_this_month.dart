import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Methods recordManualPayment stores (backend/payments.js MANUAL_METHODS). They aren't
/// electronic collections.
const Set<String> manualPaymentMethods = {'cash', 'bank_transfer'};

/// What the "Collected electronically this month" card shows (TAQ-189): paid invoices whose
/// payment date (or due date, when none is stored) falls in [now]'s calendar month, minus
/// manual payments.
double collectedElectronicallyThisMonth(Iterable<RentInvoiceModel> invoices, DateTime now) {
  var total = 0.0;
  for (final inv in invoices) {
    if (inv.status != 'paid' || manualPaymentMethods.contains(inv.paymentMethod)) continue;
    final day = inv.paidAt ?? inv.dueDate;
    if (day.year != now.year || day.month != now.month) continue;
    total += inv.totalAmountDue;
  }
  return total;
}
