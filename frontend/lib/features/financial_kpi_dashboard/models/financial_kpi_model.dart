enum FinancialPortalRole {
  owner,      // مالك العقار
  agency,     // وكالة عقارية ووسيط
  superAdmin, // الإدارة العامة للمنصة
}

class MonthlyCashFlowPoint {
  final Map<String, String> localizedMonth;
  final double grossIncome;
  final double operationalExpenses;
  final double netProfit;
  final double occupancyRate;

  const MonthlyCashFlowPoint({
    required this.localizedMonth,
    required this.grossIncome,
    required this.operationalExpenses,
    required this.netProfit,
    required this.occupancyRate,
  });
}

class InvoiceStatusDistribution {
  final double paidAmount;
  final int paidCount;
  final double paidPercentage;

  final double pendingAmount;
  final int pendingCount;
  final double pendingPercentage;

  final double overdueAmount;
  final int overdueCount;
  final double overduePercentage;

  const InvoiceStatusDistribution({
    required this.paidAmount,
    required this.paidCount,
    required this.paidPercentage,
    required this.pendingAmount,
    required this.pendingCount,
    required this.pendingPercentage,
    required this.overdueAmount,
    required this.overdueCount,
    required this.overduePercentage,
  });
}

class ArrearsAgingBucket {
  final Map<String, String> localizedRange;
  final double amount;
  final int invoiceCount;
  final double accumulatedPenalties;
  final double percentageOfTotalArrears;

  const ArrearsAgingBucket({
    required this.localizedRange,
    required this.amount,
    required this.invoiceCount,
    required this.accumulatedPenalties,
    required this.percentageOfTotalArrears,
  });
}

class FinancialKpiSummary {
  final FinancialPortalRole role;
  final String countryCode;
  final double totalGrossInvoiced;
  final double totalCollectedNet;
  final double totalOverdueArrears;
  final double collectionEfficiencyRate; // e.g. 96.5%
  final double grossRentalYield;          // e.g. 8.4%
  final double netProfitMargin;           // e.g. 82.0%
  final List<MonthlyCashFlowPoint> cashFlowHistory;
  final InvoiceStatusDistribution statusDistribution;
  final List<ArrearsAgingBucket> arrearsAging;

  const FinancialKpiSummary({
    required this.role,
    required this.countryCode,
    required this.totalGrossInvoiced,
    required this.totalCollectedNet,
    required this.totalOverdueArrears,
    required this.collectionEfficiencyRate,
    required this.grossRentalYield,
    required this.netProfitMargin,
    required this.cashFlowHistory,
    required this.statusDistribution,
    required this.arrearsAging,
  });
}
