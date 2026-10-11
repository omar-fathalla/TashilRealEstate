import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/investor_dashboard/models/investor_portfolio_model.dart';

class InvestmentSimulationResult {
  final double purchasePrice;
  final double downPayment;
  final double loanAmount;
  final double expectedMonthlyRent;
  final double annualGrossRent;
  final double annualEstimatedExpenses;
  final double netOperatingIncome;
  final double capRatePercentage;
  final double cashOnCashReturnPercentage;
  final double paybackPeriodYears;
  final double fiveYearProjectedValue;
  final double totalEstimated5YearProfit;

  const InvestmentSimulationResult({
    required this.purchasePrice,
    required this.downPayment,
    required this.loanAmount,
    required this.expectedMonthlyRent,
    required this.annualGrossRent,
    required this.annualEstimatedExpenses,
    required this.netOperatingIncome,
    required this.capRatePercentage,
    required this.cashOnCashReturnPercentage,
    required this.paybackPeriodYears,
    required this.fiveYearProjectedValue,
    required this.totalEstimated5YearProfit,
  });
}

class InvestorAnalyticsService {
  static final InvestorAnalyticsService _instance = InvestorAnalyticsService._internal();
  factory InvestorAnalyticsService() => _instance;
  InvestorAnalyticsService._internal() {
    _initData();
  }

  final ValueNotifier<InvestorPortfolioSummary> _egSummaryNotifier =
      ValueNotifier<InvestorPortfolioSummary>(_initialEGSummary);
  final ValueNotifier<InvestorPortfolioSummary> _aeSummaryNotifier =
      ValueNotifier<InvestorPortfolioSummary>(_initialAESummary);

  ValueListenable<InvestorPortfolioSummary> get currentSummaryNotifier {
    return CountryController.isUAE ? _aeSummaryNotifier : _egSummaryNotifier;
  }

  InvestorPortfolioSummary get currentSummary {
    return CountryController.isUAE ? _aeSummaryNotifier.value : _egSummaryNotifier.value;
  }

  InvestorPortfolioSummary getSummaryForCountry(String countryCode) {
    return countryCode == 'AE' ? _aeSummaryNotifier.value : _egSummaryNotifier.value;
  }

  void _initData() {
    // Recompute initial summaries
    _recomputeSummary('EG');
    _recomputeSummary('AE');
  }

  void addAsset(PortfolioAssetItem asset) {
    if (asset.countryCode == 'AE') {
      final updatedList = List<PortfolioAssetItem>.from(_aeSummaryNotifier.value.assets)..add(asset);
      _updateSummaryList('AE', updatedList);
    } else {
      final updatedList = List<PortfolioAssetItem>.from(_egSummaryNotifier.value.assets)..add(asset);
      _updateSummaryList('EG', updatedList);
    }
  }

  void removeAsset(String assetId, String countryCode) {
    if (countryCode == 'AE') {
      final updatedList = _aeSummaryNotifier.value.assets.where((a) => a.id != assetId).toList();
      _updateSummaryList('AE', updatedList);
    } else {
      final updatedList = _egSummaryNotifier.value.assets.where((a) => a.id != assetId).toList();
      _updateSummaryList('EG', updatedList);
    }
  }

  void _updateSummaryList(String countryCode, List<PortfolioAssetItem> assets) {
    final double totalValue = assets.fold(0.0, (sum, a) => sum + a.currentMarketValue);
    final double totalCost = assets.fold(0.0, (sum, a) => sum + a.purchasePrice);
    final double grossRent = assets.fold(0.0, (sum, a) => sum + a.grossAnnualRent);
    final double totalExpenses = assets.fold(0.0, (sum, a) => sum + a.totalAnnualExpenses);
    final double netCashFlow = grossRent - totalExpenses;

    final double grossYield = totalValue > 0 ? (grossRent / totalValue) * 100 : 0;
    final double netRoi = totalValue > 0 ? (netCashFlow / totalValue) * 100 : 0;
    final double capitalGrowth =
        totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0;

    final int totalUnits = assets.length;
    final int occupied = assets.where((a) => a.status == AssetStatus.occupied).length;
    final int vacant = totalUnits - occupied;
    final double occupancy = totalUnits > 0 ? (occupied / totalUnits) * 100 : 0;

    final cashHistory = countryCode == 'AE' ? _sampleCashFlowAE : _sampleCashFlowEG;

    final summary = InvestorPortfolioSummary(
      countryCode: countryCode,
      totalPortfolioValue: totalValue,
      totalPurchaseCost: totalCost,
      grossAnnualRentalIncome: grossRent,
      annualOperatingExpenses: totalExpenses,
      netAnnualCashFlow: netCashFlow,
      portfolioGrossYield: grossYield,
      portfolioNetRoi: netRoi,
      portfolioCapitalGrowthRate: capitalGrowth,
      occupancyRate: occupancy,
      totalUnitsCount: totalUnits,
      occupiedUnitsCount: occupied,
      vacantUnitsCount: vacant,
      assets: assets,
      cashFlowHistory: cashHistory,
    );

    if (countryCode == 'AE') {
      _aeSummaryNotifier.value = summary;
    } else {
      _egSummaryNotifier.value = summary;
    }
  }

  void _recomputeSummary(String countryCode) {
    if (countryCode == 'AE') {
      _updateSummaryList('AE', _sampleAssetsAE);
    } else {
      _updateSummaryList('EG', _sampleAssetsEG);
    }
  }

  InvestmentSimulationResult simulateInvestment({
    required double purchasePrice,
    required double downPaymentPercentage, // e.g. 20%
    required double expectedMonthlyRent,
    required double annualMaintenanceEstimate,
    required double annualServiceFeeEstimate,
    double annualAppreciationRate = 8.0, // e.g. 8% annual growth
  }) {
    final downPayment = purchasePrice * (downPaymentPercentage / 100);
    final loanAmount = purchasePrice - downPayment;
    final annualGrossRent = expectedMonthlyRent * 12;
    final annualExpenses = annualMaintenanceEstimate + annualServiceFeeEstimate;
    final netOperatingIncome = annualGrossRent - annualExpenses;

    final capRate = purchasePrice > 0 ? (netOperatingIncome / purchasePrice) * 100 : 0.0;
    final cashOnCash = downPayment > 0 ? (netOperatingIncome / downPayment) * 100 : 0.0;
    final paybackPeriod = netOperatingIncome > 0 ? (purchasePrice / netOperatingIncome) : 0.0;

    // 5-Year compound projection
    double projectedValue = purchasePrice;
    for (int i = 0; i < 5; i++) {
      projectedValue *= (1 + (annualAppreciationRate / 100));
    }
    final capitalGain5Years = projectedValue - purchasePrice;
    final cumulative5YearRent = netOperatingIncome * 5;
    final total5YearProfit = capitalGain5Years + cumulative5YearRent;

    return InvestmentSimulationResult(
      purchasePrice: purchasePrice,
      downPayment: downPayment,
      loanAmount: loanAmount,
      expectedMonthlyRent: expectedMonthlyRent,
      annualGrossRent: annualGrossRent,
      annualEstimatedExpenses: annualExpenses,
      netOperatingIncome: netOperatingIncome,
      capRatePercentage: capRate,
      cashOnCashReturnPercentage: cashOnCash,
      paybackPeriodYears: paybackPeriod,
      fiveYearProjectedValue: projectedValue,
      totalEstimated5YearProfit: total5YearProfit,
    );
  }

  // --- Seed Data for Egypt 🇪🇬 ---
  static const List<PortfolioAssetItem> _sampleAssetsEG = [
    PortfolioAssetItem(
      id: 'EG-AST-001',
      name: {
        'ar': 'شقة فاخرة - التجمع الخامس (النرجس)',
        'en': 'Luxury Apartment - 5th Settlement (El Narges)',
        'hi': 'लक्जरी अपार्टमेंट - 5वां सेटलमेंट (अल नरगिस)',
      },
      location: {
        'ar': 'القاهرة الجديدة، التجمع الخامس',
        'en': 'New Cairo, 5th Settlement',
        'hi': 'न्यू काहिरा, 5वां सेटलमेंट',
      },
      assetType: AssetType.apartment,
      status: AssetStatus.occupied,
      purchasePrice: 4200000,
      currentMarketValue: 5600000,
      monthlyRent: 26000,
      annualMaintenanceCost: 12000,
      annualServiceCharges: 14000,
      annualPropertyTax: 6000,
      tenantName: 'م. كريم الشناوي',
      leaseEndDate: '2027-04-30',
      countryCode: 'EG',
      imageUrl:
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'EG-AST-002',
      name: {
        'ar': 'فيلا مستقلة - بيفرلي هيلز الشيخ زايد',
        'en': 'Standalone Villa - Beverly Hills Zayed',
        'hi': 'विला - बेवर्ली हिल्स शेख जायद',
      },
      location: {
        'ar': 'الشيخ زايد، الجيزة',
        'en': 'Sheikh Zayed, Giza',
        'hi': 'शेख जायद, गीज़ा',
      },
      assetType: AssetType.villa,
      status: AssetStatus.occupied,
      purchasePrice: 9500000,
      currentMarketValue: 12800000,
      monthlyRent: 55000,
      annualMaintenanceCost: 28000,
      annualServiceCharges: 32000,
      annualPropertyTax: 15000,
      tenantName: 'د. طارق المنشاوي',
      leaseEndDate: '2027-08-31',
      countryCode: 'EG',
      imageUrl:
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'EG-AST-003',
      name: {
        'ar': 'شقة نيلية عريقة - جاردن سيتي',
        'en': 'Historic Nile View Flat - Garden City',
        'hi': 'नाइल व्यू अपार्टमेंट - गार्डन सिटी',
      },
      location: {
        'ar': 'جاردن سيتي، وسط البلد، القاهرة',
        'en': 'Garden City, Downtown Cairo',
        'hi': 'गार्डन सिटी, डाउनटाउन काहिरा',
      },
      assetType: AssetType.apartment,
      status: AssetStatus.occupied,
      purchasePrice: 6000000,
      currentMarketValue: 7900000,
      monthlyRent: 35000,
      annualMaintenanceCost: 15000,
      annualServiceCharges: 18000,
      annualPropertyTax: 10000,
      tenantName: 'السيد ألكسندر مارتن',
      leaseEndDate: '2026-12-31',
      countryCode: 'EG',
      imageUrl:
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'EG-AST-004',
      name: {
        'ar': 'مكتب إداري تجاري - كايرو فيستيفال سيتي',
        'en': 'Commercial Office - Cairo Festival City',
        'hi': 'व्यावसायिक कार्यालय - काहिरा फेस्टिवल सिटी',
      },
      location: {
        'ar': 'التجمع الخامس، القاهرة الجديدة',
        'en': '5th Settlement, New Cairo',
        'hi': '5वां सेटलमेंट, न्यू काहिरा',
      },
      assetType: AssetType.office,
      status: AssetStatus.vacant,
      purchasePrice: 5500000,
      currentMarketValue: 6900000,
      monthlyRent: 42000,
      annualMaintenanceCost: 10000,
      annualServiceCharges: 25000,
      annualPropertyTax: 12000,
      tenantName: null,
      leaseEndDate: '2026-06-30',
      countryCode: 'EG',
      imageUrl:
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&auto=format&fit=crop&q=80',
    ),
  ];

  static const List<MonthlyCashFlowItem> _sampleCashFlowEG = [
    MonthlyCashFlowItem(
      monthKey: '2026-06',
      monthName: {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
      grossRentalInflow: 116000,
      operatingExpensesOutflow: 8500,
      maintenanceOutflow: 2000,
      netCashFlow: 105500,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-07',
      monthName: {'ar': 'يوليو', 'en': 'Jul', 'hi': 'जुलाई'},
      grossRentalInflow: 116000,
      operatingExpensesOutflow: 8500,
      maintenanceOutflow: 4500,
      netCashFlow: 103000,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-08',
      monthName: {'ar': 'أغسطس', 'en': 'Aug', 'hi': 'अगस्त'},
      grossRentalInflow: 116000,
      operatingExpensesOutflow: 8500,
      maintenanceOutflow: 1500,
      netCashFlow: 106000,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-09',
      monthName: {'ar': 'سبتمبر', 'en': 'Sep', 'hi': 'सितंबर'},
      grossRentalInflow: 116000,
      operatingExpensesOutflow: 8500,
      maintenanceOutflow: 3000,
      netCashFlow: 104500,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-10',
      monthName: {'ar': 'أكتوبر', 'en': 'Oct', 'hi': 'अक्टूबर'},
      grossRentalInflow: 158000, // Office leased
      operatingExpensesOutflow: 11000,
      maintenanceOutflow: 2000,
      netCashFlow: 145000,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-11',
      monthName: {'ar': 'نوفمبر', 'en': 'Nov', 'hi': 'नवंबर'},
      grossRentalInflow: 158000,
      operatingExpensesOutflow: 11000,
      maintenanceOutflow: 2500,
      netCashFlow: 144500,
    ),
  ];

  // --- Seed Data for UAE 🇦🇪 ---
  static const List<PortfolioAssetItem> _sampleAssetsAE = [
    PortfolioAssetItem(
      id: 'AE-AST-001',
      name: {
        'ar': 'شقة فاخرة - دبي مارينا (مارينا كراون)',
        'en': 'Luxury Apartment - Dubai Marina Crown',
        'hi': 'लक्जरी अपार्टमेंट - दुबई मरीना क्राउन',
      },
      location: {
        'ar': 'دبي مارينا، دبي',
        'en': 'Dubai Marina, Dubai',
        'hi': 'दुबई मरीना, दुबई',
      },
      assetType: AssetType.apartment,
      status: AssetStatus.occupied,
      purchasePrice: 2200000,
      currentMarketValue: 2850000,
      monthlyRent: 16500,
      annualMaintenanceCost: 6000,
      annualServiceCharges: 18000,
      annualPropertyTax: 0,
      tenantName: 'David H. Sterling',
      leaseEndDate: '2027-03-31',
      countryCode: 'AE',
      imageUrl:
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'AE-AST-002',
      name: {
        'ar': 'بنتهاوس إطلالة برج خليفة - داون تاون دبي',
        'en': 'Burj Khalifa View Penthouse - Downtown Dubai',
        'hi': 'बुर्ज खलीफा व्यू पेंटहाउस - डाउनटाउन दुबई',
      },
      location: {
        'ar': 'داون تاون دبي، إعمار بوليفارد',
        'en': 'Downtown Dubai, Emaar Blvd',
        'hi': 'डाउनटाउन दुबई, एम्मार बुलेवार्ड',
      },
      assetType: AssetType.penthouse,
      status: AssetStatus.occupied,
      purchasePrice: 4800000,
      currentMarketValue: 6200000,
      monthlyRent: 32000,
      annualMaintenanceCost: 12000,
      annualServiceCharges: 35000,
      annualPropertyTax: 0,
      tenantName: 'Sophie Van Der Bilt',
      leaseEndDate: '2027-06-30',
      countryCode: 'AE',
      imageUrl:
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'AE-AST-003',
      name: {
        'ar': 'فيلا شاطئية خاصة - نخلة جميرا',
        'en': 'Private Beachfront Villa - Palm Jumeirah',
        'hi': 'प्राइवेट बीचफ्रंट विला - पाम जुमेराह',
      },
      location: {
        'ar': 'سعفة K، نخلة جميرا، دبي',
        'en': 'Frond K, Palm Jumeirah, Dubai',
        'hi': 'फ्रॉन्ड के, पाम जुमेराह, दुबई',
      },
      assetType: AssetType.villa,
      status: AssetStatus.occupied,
      purchasePrice: 11500000,
      currentMarketValue: 15400000,
      monthlyRent: 75000,
      annualMaintenanceCost: 25000,
      annualServiceCharges: 48000,
      annualPropertyTax: 0,
      tenantName: 'Lord Arthur Pendelton',
      leaseEndDate: '2027-11-30',
      countryCode: 'AE',
      imageUrl:
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&auto=format&fit=crop&q=80',
    ),
    PortfolioAssetItem(
      id: 'AE-AST-004',
      name: {
        'ar': 'مكتب إداري مجهز - الخليج التجاري (Business Bay)',
        'en': 'Fitted Commercial Office - Business Bay',
        'hi': 'फिटेड व्यावसायिक कार्यालय - बिजनेस बे',
      },
      location: {
        'ar': 'أبراج باي جيت، الخليج التجاري، دبي',
        'en': 'Bay Gate Towers, Business Bay, Dubai',
        'hi': 'बे गेट टावर्स, बिजनेस बे, दुबई',
      },
      assetType: AssetType.office,
      status: AssetStatus.vacant,
      purchasePrice: 3100000,
      currentMarketValue: 3950000,
      monthlyRent: 24000,
      annualMaintenanceCost: 8000,
      annualServiceCharges: 22000,
      annualPropertyTax: 0,
      tenantName: null,
      leaseEndDate: '2026-07-31',
      countryCode: 'AE',
      imageUrl:
          'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&auto=format&fit=crop&q=80',
    ),
  ];

  static const List<MonthlyCashFlowItem> _sampleCashFlowAE = [
    MonthlyCashFlowItem(
      monthKey: '2026-06',
      monthName: {'ar': 'يونيو', 'en': 'Jun', 'hi': 'जून'},
      grossRentalInflow: 123500,
      operatingExpensesOutflow: 8250,
      maintenanceOutflow: 3000,
      netCashFlow: 112250,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-07',
      monthName: {'ar': 'يوليو', 'en': 'Jul', 'hi': 'जुलाई'},
      grossRentalInflow: 123500,
      operatingExpensesOutflow: 8250,
      maintenanceOutflow: 2000,
      netCashFlow: 113250,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-08',
      monthName: {'ar': 'أغسطس', 'en': 'Aug', 'hi': 'अगस्त'},
      grossRentalInflow: 123500,
      operatingExpensesOutflow: 8250,
      maintenanceOutflow: 4000,
      netCashFlow: 111250,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-09',
      monthName: {'ar': 'سبتمبر', 'en': 'Sep', 'hi': 'सितंबर'},
      grossRentalInflow: 123500,
      operatingExpensesOutflow: 8250,
      maintenanceOutflow: 2500,
      netCashFlow: 112750,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-10',
      monthName: {'ar': 'أكتوبر', 'en': 'Oct', 'hi': 'अक्टूबर'},
      grossRentalInflow: 147500,
      operatingExpensesOutflow: 9500,
      maintenanceOutflow: 3000,
      netCashFlow: 135000,
    ),
    MonthlyCashFlowItem(
      monthKey: '2026-11',
      monthName: {'ar': 'نوفمبر', 'en': 'Nov', 'hi': 'नवंबर'},
      grossRentalInflow: 147500,
      operatingExpensesOutflow: 9500,
      maintenanceOutflow: 2000,
      netCashFlow: 136000,
    ),
  ];

  static const InvestorPortfolioSummary _initialEGSummary = InvestorPortfolioSummary(
    countryCode: 'EG',
    totalPortfolioValue: 33200000,
    totalPurchaseCost: 25200000,
    grossAnnualRentalIncome: 1896000,
    annualOperatingExpenses: 160000,
    netAnnualCashFlow: 1736000,
    portfolioGrossYield: 5.71,
    portfolioNetRoi: 5.23,
    portfolioCapitalGrowthRate: 31.75,
    occupancyRate: 75.0,
    totalUnitsCount: 4,
    occupiedUnitsCount: 3,
    vacantUnitsCount: 1,
    assets: _sampleAssetsEG,
    cashFlowHistory: _sampleCashFlowEG,
  );

  static const InvestorPortfolioSummary _initialAESummary = InvestorPortfolioSummary(
    countryCode: 'AE',
    totalPortfolioValue: 28400000,
    totalPurchaseCost: 21600000,
    grossAnnualRentalIncome: 1770000,
    annualOperatingExpenses: 166000,
    netAnnualCashFlow: 1604000,
    portfolioGrossYield: 6.23,
    portfolioNetRoi: 5.65,
    portfolioCapitalGrowthRate: 31.48,
    occupancyRate: 75.0,
    totalUnitsCount: 4,
    occupiedUnitsCount: 3,
    vacantUnitsCount: 1,
    assets: _sampleAssetsAE,
    cashFlowHistory: _sampleCashFlowAE,
  );
}
