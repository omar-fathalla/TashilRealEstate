import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/rent_schedule_builder.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

class FinancialKpiService {
  static final FinancialKpiService _instance = FinancialKpiService._internal();
  factory FinancialKpiService() => _instance;
  FinancialKpiService._internal();

  static const List<Map<String, String>> _monthNames = [
    {'ar': 'يناير', 'en': 'Jan', 'hi': 'जनवरी'},
    {'ar': 'فبراير', 'en': 'Feb', 'hi': 'फरवरी'},
    {'ar': 'مارس', 'en': 'Mar', 'hi': 'मार्च'},
    {'ar': 'أبريل', 'en': 'Apr', 'hi': 'अप्रैल'},
    {'ar': 'مايو', 'en': 'May', 'hi': 'मई'},
    {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
    {'ar': 'يوليو', 'en': 'Jul', 'hi': 'जुलाई'},
    {'ar': 'أغسطس', 'en': 'Aug', 'hi': 'अगस्त'},
    {'ar': 'سبتمبر', 'en': 'Sep', 'hi': 'सितंबर'},
    {'ar': 'أكتوبر', 'en': 'Oct', 'hi': 'अक्टूबर'},
    {'ar': 'نوفمبر', 'en': 'Nov', 'hi': 'नवंबर'},
    {'ar': 'ديسمبر', 'en': 'Dec', 'hi': 'दिसंबर'},
  ];

  /// How many invoices the real-data summary would be built from, for the empty state.
  static int realInvoiceCount(PortfolioSnapshot snapshot, String countryCode, {DateTime? now}) =>
      RentScheduleBuilder.build(snapshot, now: now).where((i) => i.countryCode == countryCode).length;

  /// The summary for a manager's own leases and payments. Every figure is computed from the real
  /// rows; deductions are what the server withheld from paid rent (platform and agency fees).
  FinancialKpiSummary summaryFromPortfolio({
    required FinancialPortalRole role,
    required String countryCode,
    required PortfolioSnapshot snapshot,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final rows = RentScheduleBuilder.build(snapshot, now: today).where((i) => i.countryCode == countryCode).toList();
    final paid = rows.where((i) => i.status == 'paid').toList();
    final pending = rows.where((i) => i.status == 'due_soon').toList();
    final overdue = rows.where((i) => i.status == 'overdue').toList();
    double sum(Iterable<RentInvoiceModel> l, double Function(RentInvoiceModel) f) => l.fold(0.0, (a, b) => a + f(b));

    final invoiced = sum(rows, (i) => i.baseAmount);
    final collected = sum(paid, (i) => i.baseAmount);
    final owed = sum(overdue, (i) => i.baseAmount);
    final pendingAmount = sum(pending, (i) => i.baseAmount);
    final toOwners = sum(paid, (i) => i.netPayoutToOwner);
    double pct(double part, double whole) => whole > 0 ? part / whole * 100 : 0.0;

    final history = <MonthlyCashFlowPoint>[];
    final propertiesWithLeases = snapshot.leases.where((l) => l.isActive || l.isEnded).map((l) => l.propertyId).where((id) => id.isNotEmpty).toSet();
    for (var back = 5; back >= 0; back--) {
      final monthStart = DateTime(today.year, today.month - back, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      final inMonth = paid.where((i) => i.paidAt != null && i.paidAt!.year == monthStart.year && i.paidAt!.month == monthStart.month).toList();
      final gross = sum(inMonth, (i) => i.baseAmount);
      final deductions = gross - sum(inMonth, (i) => i.netPayoutToOwner);
      final occupied = snapshot.leases.where((l) {
        if (!l.isActive && !l.isEnded) return false;
        final start = DateTime.tryParse(l.startDate.length >= 10 ? l.startDate.substring(0, 10) : '');
        final end = DateTime.tryParse(l.endDate.length >= 10 ? l.endDate.substring(0, 10) : '');
        if (start == null || start.isAfter(monthEnd)) return false;
        return end == null || !end.isBefore(monthStart);
      }).map((l) => l.propertyId).where((id) => id.isNotEmpty).toSet();
      history.add(MonthlyCashFlowPoint(
        localizedMonth: _monthNames[monthStart.month - 1],
        grossIncome: gross,
        operationalExpenses: deductions,
        netProfit: gross - deductions,
        occupancyRate: pct(occupied.length.toDouble(), propertiesWithLeases.length.toDouble()),
      ));
    }

    int daysLate(RentInvoiceModel i) => today.difference(i.dueDate).inDays;
    ArrearsAgingBucket bucket(Map<String, String> label, bool Function(int) test) {
      final inBucket = overdue.where((i) => test(daysLate(i))).toList();
      final amount = sum(inBucket, (i) => i.baseAmount);
      return ArrearsAgingBucket(
        localizedRange: label,
        amount: amount,
        invoiceCount: inBucket.length,
        accumulatedPenalties: 0,
        percentageOfTotalArrears: pct(amount, owed),
      );
    }

    return FinancialKpiSummary(
      role: role,
      countryCode: countryCode,
      totalGrossInvoiced: invoiced,
      totalCollectedNet: toOwners,
      totalOverdueArrears: owed,
      collectionEfficiencyRate: pct(collected, invoiced),
      grossRentalYield: null,
      netProfitMargin: pct(toOwners, collected),
      cashFlowHistory: history,
      statusDistribution: InvoiceStatusDistribution(
        paidAmount: collected,
        paidCount: paid.length,
        paidPercentage: pct(collected, invoiced),
        pendingAmount: pendingAmount,
        pendingCount: pending.length,
        pendingPercentage: pct(pendingAmount, invoiced),
        overdueAmount: owed,
        overdueCount: overdue.length,
        overduePercentage: pct(owed, invoiced),
      ),
      arrearsAging: [
        bucket({'ar': '1 - 15 يوم', 'en': '1 - 15 Days', 'hi': '1 - 15 दिन'}, (d) => d <= 15),
        bucket({'ar': '16 - 30 يوم', 'en': '16 - 30 Days', 'hi': '16 - 30 दिन'}, (d) => d > 15 && d <= 30),
        bucket({'ar': 'أكثر من 30 يوم', 'en': '30+ Days', 'hi': '30+ दिन'}, (d) => d > 30),
      ],
      invoiceCount: rows.length,
    );
  }

  FinancialKpiSummary getFinancialSummary({
    required FinancialPortalRole role,
    required String countryCode,
  }) {
    final isUAE = countryCode == 'AE';

    switch (role) {
      case FinancialPortalRole.owner:
        return _buildOwnerSummary(isUAE, countryCode);
      case FinancialPortalRole.agency:
        return _buildAgencySummary(isUAE, countryCode);
      case FinancialPortalRole.superAdmin:
        return _buildSuperAdminSummary(isUAE, countryCode);
    }
  }

  FinancialKpiSummary _buildOwnerSummary(bool isUAE, String countryCode) {
    final currencyMultiplier = isUAE ? 1.0 : 1.8;

    return FinancialKpiSummary(
      role: FinancialPortalRole.owner,
      countryCode: countryCode,
      totalGrossInvoiced: 480000 * currencyMultiplier,
      totalCollectedNet: 456000 * currencyMultiplier,
      totalOverdueArrears: 24000 * currencyMultiplier,
      collectionEfficiencyRate: 95.0,
      grossRentalYield: isUAE ? 8.6 : 11.2,
      netProfitMargin: 84.5,
      cashFlowHistory: [
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يناير', 'en': 'Jan', 'hi': 'जनवरी'},
          grossIncome: 38000 * currencyMultiplier,
          operationalExpenses: 4500 * currencyMultiplier,
          netProfit: 33500 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'فبراير', 'en': 'Feb', 'hi': 'फरवरी'},
          grossIncome: 38000 * currencyMultiplier,
          operationalExpenses: 3200 * currencyMultiplier,
          netProfit: 34800 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مارس', 'en': 'Mar', 'hi': 'मार्च'},
          grossIncome: 38000 * currencyMultiplier,
          operationalExpenses: 6800 * currencyMultiplier,
          netProfit: 31200 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'أبريل', 'en': 'Apr', 'hi': 'अप्रैल'},
          grossIncome: 42000 * currencyMultiplier,
          operationalExpenses: 3900 * currencyMultiplier,
          netProfit: 38100 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مايو', 'en': 'May', 'hi': 'मई'},
          grossIncome: 42000 * currencyMultiplier,
          operationalExpenses: 4100 * currencyMultiplier,
          netProfit: 37900 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
          grossIncome: 42000 * currencyMultiplier,
          operationalExpenses: 8500 * currencyMultiplier,
          netProfit: 33500 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يوليو', 'en': 'Jul', 'hi': 'जुलाई'},
          grossIncome: 42000 * currencyMultiplier,
          operationalExpenses: 3000 * currencyMultiplier,
          netProfit: 39000 * currencyMultiplier,
          occupancyRate: 100,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'أغسطس', 'en': 'Aug', 'hi': 'अगस्त'},
          grossIncome: 42000 * currencyMultiplier,
          operationalExpenses: 4400 * currencyMultiplier,
          netProfit: 37600 * currencyMultiplier,
          occupancyRate: 100,
        ),
      ],
      statusDistribution: InvoiceStatusDistribution(
        paidAmount: 432000 * currencyMultiplier,
        paidCount: 18,
        paidPercentage: 90.0,
        pendingAmount: 24000 * currencyMultiplier,
        pendingCount: 2,
        pendingPercentage: 5.0,
        overdueAmount: 24000 * currencyMultiplier,
        overdueCount: 1,
        overduePercentage: 5.0,
      ),
      arrearsAging: [
        ArrearsAgingBucket(
          localizedRange: {'ar': '1 - 15 يوم', 'en': '1 - 15 Days', 'hi': '1 - 15 दिन'},
          amount: 14000 * currencyMultiplier,
          invoiceCount: 1,
          accumulatedPenalties: 700 * currencyMultiplier,
          percentageOfTotalArrears: 58.3,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': '16 - 30 يوم', 'en': '16 - 30 Days', 'hi': '16 - 30 दिन'},
          amount: 10000 * currencyMultiplier,
          invoiceCount: 1,
          accumulatedPenalties: 1200 * currencyMultiplier,
          percentageOfTotalArrears: 41.7,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': 'أكثر من 30 يوم', 'en': '30+ Days', 'hi': '30+ दिन'},
          amount: 0,
          invoiceCount: 0,
          accumulatedPenalties: 0,
          percentageOfTotalArrears: 0.0,
        ),
      ],
    );
  }

  FinancialKpiSummary _buildAgencySummary(bool isUAE, String countryCode) {
    final currencyMultiplier = isUAE ? 1.0 : 2.5;

    return FinancialKpiSummary(
      role: FinancialPortalRole.agency,
      countryCode: countryCode,
      totalGrossInvoiced: 2400000 * currencyMultiplier,
      totalCollectedNet: 2310000 * currencyMultiplier,
      totalOverdueArrears: 90000 * currencyMultiplier,
      collectionEfficiencyRate: 96.2,
      grossRentalYield: isUAE ? 8.9 : 12.0,
      netProfitMargin: 88.0,
      cashFlowHistory: [
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يناير', 'en': 'Jan', 'hi': 'जनवरी'},
          grossIncome: 280000 * currencyMultiplier,
          operationalExpenses: 28000 * currencyMultiplier,
          netProfit: 252000 * currencyMultiplier,
          occupancyRate: 96,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'فبراير', 'en': 'Feb', 'hi': 'फरवरी'},
          grossIncome: 290000 * currencyMultiplier,
          operationalExpenses: 26000 * currencyMultiplier,
          netProfit: 264000 * currencyMultiplier,
          occupancyRate: 97,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مارس', 'en': 'Mar', 'hi': 'मार्च'},
          grossIncome: 310000 * currencyMultiplier,
          operationalExpenses: 35000 * currencyMultiplier,
          netProfit: 275000 * currencyMultiplier,
          occupancyRate: 98,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'أبريل', 'en': 'Apr', 'hi': 'अप्रैल'},
          grossIncome: 315000 * currencyMultiplier,
          operationalExpenses: 30000 * currencyMultiplier,
          netProfit: 285000 * currencyMultiplier,
          occupancyRate: 98,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مايو', 'en': 'May', 'hi': 'मई'},
          grossIncome: 320000 * currencyMultiplier,
          operationalExpenses: 32000 * currencyMultiplier,
          netProfit: 288000 * currencyMultiplier,
          occupancyRate: 99,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
          grossIncome: 330000 * currencyMultiplier,
          operationalExpenses: 38000 * currencyMultiplier,
          netProfit: 292000 * currencyMultiplier,
          occupancyRate: 99,
        ),
      ],
      statusDistribution: InvoiceStatusDistribution(
        paidAmount: 2160000 * currencyMultiplier,
        paidCount: 84,
        paidPercentage: 90.0,
        pendingAmount: 150000 * currencyMultiplier,
        pendingCount: 6,
        pendingPercentage: 6.25,
        overdueAmount: 90000 * currencyMultiplier,
        overdueCount: 4,
        overduePercentage: 3.75,
      ),
      arrearsAging: [
        ArrearsAgingBucket(
          localizedRange: {'ar': '1 - 15 يوم', 'en': '1 - 15 Days', 'hi': '1 - 15 दिन'},
          amount: 50000 * currencyMultiplier,
          invoiceCount: 2,
          accumulatedPenalties: 2500 * currencyMultiplier,
          percentageOfTotalArrears: 55.5,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': '16 - 30 يوم', 'en': '16 - 30 Days', 'hi': '16 - 30 दिन'},
          amount: 30000 * currencyMultiplier,
          invoiceCount: 1,
          accumulatedPenalties: 3600 * currencyMultiplier,
          percentageOfTotalArrears: 33.3,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': 'أكثر من 30 يوم', 'en': '30+ Days', 'hi': '30+ दिन'},
          amount: 10000 * currencyMultiplier,
          invoiceCount: 1,
          accumulatedPenalties: 2400 * currencyMultiplier,
          percentageOfTotalArrears: 11.2,
        ),
      ],
    );
  }

  FinancialKpiSummary _buildSuperAdminSummary(bool isUAE, String countryCode) {
    final currencyMultiplier = isUAE ? 1.0 : 3.0;

    return FinancialKpiSummary(
      role: FinancialPortalRole.superAdmin,
      countryCode: countryCode,
      totalGrossInvoiced: 18500000 * currencyMultiplier,
      totalCollectedNet: 17800000 * currencyMultiplier,
      totalOverdueArrears: 700000 * currencyMultiplier,
      collectionEfficiencyRate: 96.2,
      grossRentalYield: isUAE ? 8.7 : 11.8,
      netProfitMargin: 94.0,
      cashFlowHistory: [
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يناير', 'en': 'Jan', 'hi': 'जनवरी'},
          grossIncome: 2100000 * currencyMultiplier,
          operationalExpenses: 120000 * currencyMultiplier,
          netProfit: 1980000 * currencyMultiplier,
          occupancyRate: 95,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'فبراير', 'en': 'Feb', 'hi': 'फरवरी'},
          grossIncome: 2250000 * currencyMultiplier,
          operationalExpenses: 135000 * currencyMultiplier,
          netProfit: 2115000 * currencyMultiplier,
          occupancyRate: 96,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مارس', 'en': 'Mar', 'hi': 'मार्च'},
          grossIncome: 2400000 * currencyMultiplier,
          operationalExpenses: 140000 * currencyMultiplier,
          netProfit: 2260000 * currencyMultiplier,
          occupancyRate: 97,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'أبريل', 'en': 'Apr', 'hi': 'अप्रैल'},
          grossIncome: 2550000 * currencyMultiplier,
          operationalExpenses: 148000 * currencyMultiplier,
          netProfit: 2402000 * currencyMultiplier,
          occupancyRate: 98,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'مايو', 'en': 'May', 'hi': 'मई'},
          grossIncome: 2680000 * currencyMultiplier,
          operationalExpenses: 152000 * currencyMultiplier,
          netProfit: 2528000 * currencyMultiplier,
          occupancyRate: 98,
        ),
        MonthlyCashFlowPoint(
          localizedMonth: {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
          grossIncome: 2800000 * currencyMultiplier,
          operationalExpenses: 160000 * currencyMultiplier,
          netProfit: 2640000 * currencyMultiplier,
          occupancyRate: 99,
        ),
      ],
      statusDistribution: InvoiceStatusDistribution(
        paidAmount: 16650000 * currencyMultiplier,
        paidCount: 620,
        paidPercentage: 90.0,
        pendingAmount: 1150000 * currencyMultiplier,
        pendingCount: 42,
        pendingPercentage: 6.2,
        overdueAmount: 700000 * currencyMultiplier,
        overdueCount: 26,
        overduePercentage: 3.8,
      ),
      arrearsAging: [
        ArrearsAgingBucket(
          localizedRange: {'ar': '1 - 15 يوم', 'en': '1 - 15 Days', 'hi': '1 - 15 दिन'},
          amount: 380000 * currencyMultiplier,
          invoiceCount: 15,
          accumulatedPenalties: 19000 * currencyMultiplier,
          percentageOfTotalArrears: 54.3,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': '16 - 30 يوم', 'en': '16 - 30 Days', 'hi': '16 - 30 दिन'},
          amount: 220000 * currencyMultiplier,
          invoiceCount: 8,
          accumulatedPenalties: 26400 * currencyMultiplier,
          percentageOfTotalArrears: 31.4,
        ),
        ArrearsAgingBucket(
          localizedRange: {'ar': 'أكثر من 30 يوم', 'en': '30+ Days', 'hi': '30+ दिन'},
          amount: 100000 * currencyMultiplier,
          invoiceCount: 3,
          accumulatedPenalties: 24000 * currencyMultiplier,
          percentageOfTotalArrears: 14.3,
        ),
      ],
    );
  }
}
