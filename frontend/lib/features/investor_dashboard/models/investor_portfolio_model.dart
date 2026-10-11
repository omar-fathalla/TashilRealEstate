enum AssetType {
  apartment,
  villa,
  penthouse,
  commercial,
  office,
}

enum AssetStatus {
  occupied,
  vacant,
  underMaintenance,
}

class PortfolioAssetItem {
  final String id;
  final Map<String, String> name;
  final Map<String, String> location;
  final AssetType assetType;
  final AssetStatus status;
  final double purchasePrice;
  final double currentMarketValue;
  final double monthlyRent;
  final double annualMaintenanceCost;
  final double annualServiceCharges;
  final double annualPropertyTax;
  final String? tenantName;
  final String leaseEndDate;
  final String countryCode; // 'EG' or 'AE'
  final String imageUrl;

  const PortfolioAssetItem({
    required this.id,
    required this.name,
    required this.location,
    required this.assetType,
    required this.status,
    required this.purchasePrice,
    required this.currentMarketValue,
    required this.monthlyRent,
    this.annualMaintenanceCost = 0.0,
    this.annualServiceCharges = 0.0,
    this.annualPropertyTax = 0.0,
    this.tenantName,
    required this.leaseEndDate,
    required this.countryCode,
    required this.imageUrl,
  });

  /// Gross Annual Rental Income
  double get grossAnnualRent => monthlyRent * 12;

  /// Total Annual Operating Expenses
  double get totalAnnualExpenses =>
      annualMaintenanceCost + annualServiceCharges + annualPropertyTax;

  /// Net Operating Income (NOI)
  double get netOperatingIncome => grossAnnualRent - totalAnnualExpenses;

  /// Gross Rental Yield (%)
  double get grossYieldPercentage =>
      currentMarketValue > 0 ? (grossAnnualRent / currentMarketValue) * 100 : 0;

  /// Net Cap Rate / ROI (%)
  double get netRoiPercentage =>
      currentMarketValue > 0 ? (netOperatingIncome / currentMarketValue) * 100 : 0;

  /// Capital Appreciation Amount
  double get capitalGainAmount => currentMarketValue - purchasePrice;

  /// Capital Appreciation Percentage (%)
  double get capitalGainPercentage =>
      purchasePrice > 0 ? ((currentMarketValue - purchasePrice) / purchasePrice) * 100 : 0;

  /// Total ROI (Net Income + Capital Gain on Purchase Price)
  double get totalReturnPercentage =>
      purchasePrice > 0 ? ((netOperatingIncome + capitalGainAmount) / purchasePrice) * 100 : 0;
}

class MonthlyCashFlowItem {
  final String monthKey; // e.g. "2026-01"
  final Map<String, String> monthName;
  final double grossRentalInflow;
  final double operatingExpensesOutflow;
  final double maintenanceOutflow;
  final double netCashFlow;

  const MonthlyCashFlowItem({
    required this.monthKey,
    required this.monthName,
    required this.grossRentalInflow,
    required this.operatingExpensesOutflow,
    required this.maintenanceOutflow,
    required this.netCashFlow,
  });
}

class InvestorPortfolioSummary {
  final String countryCode;
  final double totalPortfolioValue;
  final double totalPurchaseCost;
  final double grossAnnualRentalIncome;
  final double annualOperatingExpenses;
  final double netAnnualCashFlow;
  final double portfolioGrossYield;
  final double portfolioNetRoi;
  final double portfolioCapitalGrowthRate;
  final double occupancyRate;
  final int totalUnitsCount;
  final int occupiedUnitsCount;
  final int vacantUnitsCount;
  final List<PortfolioAssetItem> assets;
  final List<MonthlyCashFlowItem> cashFlowHistory;

  const InvestorPortfolioSummary({
    required this.countryCode,
    required this.totalPortfolioValue,
    required this.totalPurchaseCost,
    required this.grossAnnualRentalIncome,
    required this.annualOperatingExpenses,
    required this.netAnnualCashFlow,
    required this.portfolioGrossYield,
    required this.portfolioNetRoi,
    required this.portfolioCapitalGrowthRate,
    required this.occupancyRate,
    required this.totalUnitsCount,
    required this.occupiedUnitsCount,
    required this.vacantUnitsCount,
    required this.assets,
    required this.cashFlowHistory,
  });
}
