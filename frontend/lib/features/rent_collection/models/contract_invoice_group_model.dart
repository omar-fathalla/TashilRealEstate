import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Contract Invoice Group Model.
///
/// Encapsulates all monthly rent installments belonging to a single lease agreement / property unit.
/// Enables accordion grouping, progress tracking, and current-month spotlight identification.
class ContractInvoiceGroup {
  final String groupId;
  final String contractNumber;
  final String propertyId;
  final String unitTitle;
  final String unitNumber;
  final String buildingName;
  final String district;
  final String propertyTypeCode;
  final String countryCode;
  final TenantInfo tenant;
  final OwnerPayoutInfo owner;
  final List<RentInvoiceModel> invoices;

  const ContractInvoiceGroup({
    required this.groupId,
    required this.contractNumber,
    required this.propertyId,
    required this.unitTitle,
    required this.unitNumber,
    required this.buildingName,
    required this.district,
    required this.propertyTypeCode,
    required this.countryCode,
    required this.tenant,
    required this.owner,
    required this.invoices,
  });

  /// Total sum of all invoices under this lease contract
  double get totalContractAmount =>
      invoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

  /// Total collected amount for paid invoices
  double get totalCollectedAmount => invoices
      .where((inv) => inv.status == 'paid')
      .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

  /// Total remaining amount to be collected
  double get totalRemainingAmount => invoices
      .where((inv) => inv.status != 'paid')
      .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

  /// Count of paid installments
  int get paidCount => invoices.where((inv) => inv.status == 'paid').length;

  /// Count of due soon installments
  int get dueSoonCount => invoices.where((inv) => inv.status == 'due_soon').length;

  /// Count of overdue installments
  int get overdueCount => invoices.where((inv) => inv.status == 'overdue').length;

  /// Total count of installments
  int get totalCount => invoices.length;

  /// Progress ratio (0.0 to 1.0)
  double get progressRatio =>
      totalCount > 0 ? (paidCount / totalCount).clamp(0.0, 1.0) : 0.0;

  /// Earliest installment due date
  DateTime? get startDate => invoices.isNotEmpty ? invoices.first.dueDate : null;

  /// Latest installment due date
  DateTime? get endDate => invoices.isNotEmpty ? invoices.last.dueDate : null;

  /// Formatted date range string (e.g. "2026-10-11 - 2027-09-11")
  String get dateRangeFormatted {
    if (startDate == null || endDate == null) return '';
    final s = startDate!;
    final e = endDate!;
    final sStr = '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
    final eStr = '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    return '$sStr - $eStr';
  }

  /// Whether any invoice in this contract matches the current active month
  bool get hasCurrentMonthInvoice =>
      invoices.any((inv) => isCurrentMonth(inv.dueDate));

  /// The specific invoice that corresponds to the current active month
  RentInvoiceModel? get currentMonthInvoice {
    for (final inv in invoices) {
      if (isCurrentMonth(inv.dueDate)) return inv;
    }
    return null;
  }

  /// Static helper to determine if a given due date falls in the current calendar month
  static bool isCurrentMonth(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.year == now.year && dueDate.month == now.month;
  }

  /// Group a flat list of [RentInvoiceModel] into chronologically sorted [ContractInvoiceGroup] objects.
  static List<ContractInvoiceGroup> groupInvoices(List<RentInvoiceModel> invoices) {
    if (invoices.isEmpty) return const [];

    final Map<String, List<RentInvoiceModel>> map = {};
    for (final inv in invoices) {
      final key = (inv.propertyId != null && inv.propertyId!.isNotEmpty)
          ? inv.propertyId!
          : (inv.contractNumber.isNotEmpty ? inv.contractNumber : inv.unitTitle);
      map.putIfAbsent(key, () => []).add(inv);
    }

    final List<ContractInvoiceGroup> groups = [];
    for (final entry in map.entries) {
      final sortedInvoices = List<RentInvoiceModel>.from(entry.value)
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final first = sortedInvoices.first;

      groups.add(
        ContractInvoiceGroup(
          groupId: entry.key,
          contractNumber: first.contractNumber,
          propertyId: first.propertyId ?? '',
          unitTitle: first.unitTitle,
          unitNumber: first.unitNumber,
          buildingName: first.buildingName,
          district: first.district,
          propertyTypeCode: first.propertyTypeCode,
          countryCode: first.countryCode,
          tenant: first.tenant,
          owner: first.owner,
          invoices: sortedInvoices,
        ),
      );
    }

    return groups;
  }
}
