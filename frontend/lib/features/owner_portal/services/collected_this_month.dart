import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Methods recordManualPayment stores (backend/payments.js MANUAL_METHODS). They aren't
/// electronic collections.
const Set<String> manualPaymentMethods = {'cash', 'bank_transfer'};

/// A paid invoice that wasn't recorded as a manual payment: what "Paid electronically" means on
/// owner financials (TAQ-189, and its filter chip and row badge).
bool isPaidElectronically(RentInvoiceModel inv) => inv.status == 'paid' && !manualPaymentMethods.contains(inv.paymentMethod);

/// What the "Collected electronically this month" card shows (TAQ-189): paid invoices whose
/// payment date (or due date, when none is stored) falls in [now]'s calendar month, minus
/// manual payments.
double collectedElectronicallyThisMonth(Iterable<RentInvoiceModel> invoices, DateTime now) {
  var total = 0.0;
  for (final inv in invoices) {
    if (!isPaidElectronically(inv)) continue;
    final day = inv.paidAt ?? inv.dueDate;
    if (day.year != now.year || day.month != now.month) continue;
    total += inv.totalAmountDue;
  }
  return total;
}
