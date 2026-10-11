import 'package:flutter/foundation.dart';
import '../../../core/localization/country_controller.dart';
import '../../investor_dashboard/models/investor_portfolio_model.dart';
import '../../investor_dashboard/services/investor_analytics_service.dart';
import '../models/dynamic_pricing_model.dart';

class DynamicPricingOptimizerService {
  static final DynamicPricingOptimizerService _instance =
      DynamicPricingOptimizerService._internal();
  factory DynamicPricingOptimizerService() => _instance;
  DynamicPricingOptimizerService._internal();

  final _analyticsService = InvestorAnalyticsService();

  final ValueNotifier<PortfolioYieldOptimizationSummary?> _summaryNotifier =
      ValueNotifier<PortfolioYieldOptimizationSummary?>(null);

  final Set<String> _appliedAssetIds = {};
  bool isAssetPriceApplied(String assetId) => _appliedAssetIds.contains(assetId);

  void reset() {
    _appliedAssetIds.clear();
    _summaryNotifier.value = null;
  }

  ValueListenable<PortfolioYieldOptimizationSummary?> get summaryNotifier =>
      _summaryNotifier;

  /// Generate or fetch dynamic yield optimization recommendations
  Future<PortfolioYieldOptimizationSummary> generateOptimizationSummary({
    String? countryCode,
    bool forceRefresh = false,
  }) async {
    final code = countryCode ?? CountryController.countryCode;

    if (!forceRefresh &&
        _summaryNotifier.value != null &&
        _summaryNotifier.value!.countryCode == code) {
      return _summaryNotifier.value!;
    }

    final investorSummary = _analyticsService.getSummaryForCountry(code);
    final assets = investorSummary.assets;

    final recommendations = <AssetDynamicPricingItem>[];

    for (final asset in assets) {
      final item = _computeAssetDynamicPricing(asset, code);
      recommendations.add(item);
    }

    double totalCurrentRent = 0;
    double totalOptimizedRent = 0;
    int totalVacancySaved = 0;
    double totalYieldDiff = 0;

    for (final r in recommendations) {
      totalCurrentRent += (r.currentBaseRent * 12);
      totalOptimizedRent += (r.recommendedDynamicRent * 12);
      totalVacancySaved += r.projectedVacancyReductionDays;
      totalYieldDiff += r.projectedYieldIncreasePct;
    }

    final summary = PortfolioYieldOptimizationSummary(
      countryCode: code,
      totalManagedAssets: assets.length,
      totalCurrentAnnualRent: totalCurrentRent,
      totalOptimizedAnnualRent: totalOptimizedRent,
      netAnnualRevenueGain: totalOptimizedRent - totalCurrentRent,
      averageYieldIncreasePct:
          assets.isNotEmpty ? (totalYieldDiff / assets.length) : 1.8,
      totalVacancyDaysSaved: totalVacancySaved,
      assetRecommendations: recommendations,
    );

    _summaryNotifier.value = summary;
    return summary;
  }

  /// Compute asset dynamic pricing forecast based on market seasonality
  AssetDynamicPricingItem _computeAssetDynamicPricing(
    PortfolioAssetItem asset,
    String countryCode,
  ) {
    final locAr = asset.location['ar']?.toLowerCase() ?? '';
    final locEn = asset.location['en']?.toLowerCase() ?? '';
    final isAE = countryCode == 'AE';

    PricingSeasonType season;
    double multiplier;
    int vacancySaved;
    double yieldInc;
    Map<String, String> strategy;
    List<String> driversAr;
    List<String> driversEn;
    List<String> driversHi;

    final currentMonth = DateTime.now().month;

    if (isAE) {
      // UAE Seasonality (Winter Tourism Peak vs Summer Shoulder)
      if (currentMonth >= 10 || currentMonth <= 3) {
        // High Winter Tourism Peak
        season = PricingSeasonType.tourismPeak;
        multiplier = (locEn.contains('marina') || locEn.contains('palm') || locEn.contains('downtown'))
            ? 1.22
            : 1.15;
        vacancySaved = 38;
        yieldInc = 2.4;
        strategy = {
          'ar': 'زيادة سعر الإيجار بنسبة 22% للاستفادة من ذروة الموسم السياحي والمعارض العالمية في دبي مع ضمان إشغال 96%.',
          'en': 'Increase rent by 22% to capitalize on the high winter tourism & global expo season in Dubai with 96% target occupancy.',
          'hi': 'दुबई में उच्च शीतकालीन पर्यटन और वैश्विक एक्सपो सीजन का लाभ उठाने के लिए किराए में 22% की वृद्धि करें।',
        };
        driversAr = ['ذروة السياحة الشتوية في دبي', 'معارض ومؤتمرات عالمية', 'طلب عالي على الإيجار قصير ومرن'];
        driversEn = ['Dubai Winter Tourism Peak', 'Global Conferences & Expos', 'High Short-term & Flexible Demand'];
        driversHi = ['दुबई शीतकालीन पर्यटन शिखर', 'वैश्विक सम्मेलन और एक्सपो', 'उच्च अल्पकालिक और लचीली मांग'];
      } else if (currentMonth >= 6 && currentMonth <= 8) {
        // Summer Shoulder
        season = PricingSeasonType.shoulderOffPeak;
        multiplier = 0.95;
        vacancySaved = 25;
        yieldInc = 1.2;
        strategy = {
          'ar': 'تقديم مرونة في الدفعات (4-6 شيكات) أو خصم رمزي 5% لتجنب شغور الوحدة نهائياً خلال فترة الصيف.',
          'en': 'Offer payment flexibility (4-6 cheques) or a 5% promotional incentive to prevent summer vacancy.',
          'hi': 'गर्मियों में रिक्ति को रोकने के लिए भुगतान लचीलापन (4-6 चेक) या 5% प्रचार प्रोत्साहन प्रदान करें।',
        };
        driversAr = ['فترة الصيف الهادئة', 'الحفاظ على استمرارية الإشغال', 'جذب مستأجرين بعقود سنوية'];
        driversEn = ['Summer Shoulder Period', 'Sustaining Continuous Occupancy', 'Attracting Long-term Annual Tenants'];
        driversHi = ['ग्रीष्मकालीन सामान्य अवधि', 'निरंतर अधिभोग बनाए रखना', 'दीर्घकालिक वार्षिक किरायेदारों को आकर्षित करना'];
      } else {
        season = PricingSeasonType.shoulderOffPeak;
        multiplier = 1.08;
        vacancySaved = 30;
        yieldInc = 1.6;
        strategy = {
          'ar': 'تعديل الإيجار بزيادة 8% بالتوافق مع مؤشر حاسبة زيادة الإيجار لمؤسسة التنظيم العقاري (RERA).',
          'en': 'Adjust rent upward by 8% in accordance with RERA rental increase index guidelines.',
          'hi': 'रेरा रेंटल इंडेक्स दिशानिर्देशों के अनुसार किराए में 8% की वृद्धि करें।',
        };
        driversAr = ['مؤشر ريرا المحدث', 'نمو مطرد في الطلب', 'تجديد عقود الإيجار السنوية'];
        driversEn = ['Updated RERA Index', 'Steady Inflow Demand', 'Annual Tenancy Renewals'];
        driversHi = ['अद्यतन रेरा सूचकांक', 'स्थिर प्रवाह मांग', 'वार्षिक किरायेदारी नवीनीकरण'];
      }
    } else {
      // Egypt Seasonality (Student Academic AUC vs Summer Coast vs General)
      if (locAr.contains('ساحل') || locAr.contains('إسكندرية') || locEn.contains('coast') || locEn.contains('alexandria')) {
        if (currentMonth >= 5 && currentMonth <= 9) {
          season = PricingSeasonType.summerCoast;
          multiplier = 1.45;
          vacancySaved = 45;
          yieldInc = 3.8;
          strategy = {
            'ar': 'تطبيق تسعير مرن مضاعف (+45%) لموسم المصايف والساحل الشمالي لتوليد 70% من العائد السنوي في 4 أشهر.',
            'en': 'Apply surge summer pricing (+45%) for North Coast & Alex vacation season generating 70% of annual yield.',
            'hi': 'उत्तर तट और एलेक्स वेकेशन सीजन के लिए ग्रीष्मकालीन वृद्धि मूल्य (+45%) लागू करें।',
          };
          driversAr = ['ذروة موسم الصيف والمصايف', 'إيجارات أسبوعية وشهرية متميزة', 'إقبال عائلي وسياحي واسع'];
          driversEn = ['Summer Coast Vacation Peak', 'Premium Weekly & Monthly Yields', 'High Domestic & Tourism Inflow'];
          driversHi = ['ग्रीष्मकालीन तटीय अवकाश शिखर', 'प्रीमियम साप्ताहिक और मासिक प्रतिफल', 'उच्च घरेलू और पर्यटन प्रवाह'];
        } else {
          season = PricingSeasonType.shoulderOffPeak;
          multiplier = 0.85;
          vacancySaved = 20;
          yieldInc = 1.0;
          strategy = {
            'ar': 'إيجار شتوي طويل الأجل للعاملين أو الطلاب بتكلفة تشغيلية منخفضة وصيانة مؤمنة.',
            'en': 'Long-term winter tenancy for remote workers or students with minimized maintenance costs.',
            'hi': 'कम रखरखाव लागत के साथ रिमोट श्रमिकों या छात्रों के लिए दीर्घकालिक शीतकालीन किरायेदारी।',
          };
          driversAr = ['إشغال شتوي منخفض التكلفة', 'الحفاظ على صيانة الوحدة', 'عقود مؤقتة مرنة'];
          driversEn = ['Low-overhead Winter Occupancy', 'Asset Maintenance Protection', 'Flexible Temporary Leases'];
          driversHi = ['कम ओवरहेड शीतकालीन अधिभोग', 'संपत्ति रखरखाव संरक्षण', 'लचीले अस्थायी पट्टे'];
        }
      } else if (locAr.contains('تجمع') || locAr.contains('قاهرة جديدة') || locEn.contains('cairo') || locEn.contains('auc')) {
        season = PricingSeasonType.academicSurge;
        multiplier = 1.18;
        vacancySaved = 35;
        yieldInc = 2.1;
        strategy = {
          'ar': 'رفع الإيجار بنسبة 18% للوحدات المفروشة بالتزامن مع موسم طلاب الجامعة الأمريكية والجامعة الألمانية والشركات الدولية.',
          'en': 'Elevate furnished rent by 18% catering to AUC/GUC students and multinational corporate expats.',
          'hi': 'एयूसी/जीयूसी छात्रों और बहुराष्ट्रीय कॉर्पोरेट प्रवासियों के लिए सुसज्जित किराए में 18% की वृद्धि करें।',
        };
        driversAr = ['موسم طلاب الجامعات الدولية', 'طلب مرتفع على الشقق المفروشة', 'عقود سنوية مضمونة السداد'];
        driversEn = ['International Universities Influx', 'High Demand for Modern Furnished', 'Guaranteed Annual Contracts'];
        driversHi = ['अंतर्राष्ट्रीय विश्वविद्यालय प्रवाह', 'आधुनिक सुसज्जित की उच्च मांग', 'गारंटीकृत वार्षिक अनुबंध'];
      } else {
        season = PricingSeasonType.shoulderOffPeak;
        multiplier = 1.12;
        vacancySaved = 28;
        yieldInc = 1.5;
        strategy = {
          'ar': 'تعديل السعر بنسبة +12% لمواكبة معدل التضخم السنوي ومتوسط عقود المنطقة في الشيخ زايد وأكتوبر.',
          'en': 'Adjust price upward by 12% matching local inflation benchmark and Sheikh Zayed area average.',
          'hi': 'स्थानीय मुद्रास्फीति बेंचमार्क और शेख जायद क्षेत्र के औसत से मेल खाते हुए मूल्य में 12% की वृद्धि करें।',
        };
        driversAr = ['مواكبة التضخم السنوي', 'طلب عائلي مستقر', 'ارتفاع أسعار السوق العام'];
        driversEn = ['Annual Inflation Tracking', 'Stable Family Residency', 'General Market Rental Growth'];
        driversHi = ['वार्षिक मुद्रास्फीति ट्रैकिंग', 'स्थिर पारिवारिक निवास', 'सामान्य बाजार किराये में वृद्धि'];
      }
    }

    final isApplied = _appliedAssetIds.contains(asset.id);
    final originalBaseRent = asset.monthlyRent;
    final recommendedPrice = (asset.monthlyRent * multiplier).roundToDouble();
    final currentRent = isApplied ? recommendedPrice : asset.monthlyRent;
    final netGain = (recommendedPrice - asset.monthlyRent) * 12;

    final forecastCurve = _generate12MonthForecastCurve(
      baseRent: asset.monthlyRent,
      seasonType: season,
      countryCode: countryCode,
    );

    return AssetDynamicPricingItem(
      asset: asset,
      currentBaseRent: currentRent,
      recommendedDynamicRent: recommendedPrice,
      originalBaseRent: originalBaseRent,
      dynamicMultiplier: multiplier,
      projectedAnnualNetGain: netGain,
      projectedYieldIncreasePct: yieldInc,
      projectedVacancyReductionDays: vacancySaved,
      currentSeasonType: season,
      strategyRecommendation: strategy,
      demandDriversAr: driversAr,
      demandDriversEn: driversEn,
      demandDriversHi: driversHi,
      monthlyForecastCurve: forecastCurve,
      isApplied: isApplied,
    );
  }

  /// Generate 12-Month forward time-series price forecast curve
  List<MonthlyPriceForecast> _generate12MonthForecastCurve({
    required double baseRent,
    required PricingSeasonType seasonType,
    required String countryCode,
  }) {
    final months = <MonthlyPriceForecast>[];
    final now = DateTime.now();

    final monthNamesAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final monthNamesEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthNamesHi = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final mIndex = date.month - 1;
      final mKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      double mMultiplier = 1.0;
      double occupancy = 90.0;
      PricingSeasonType mSeason = PricingSeasonType.shoulderOffPeak;

      final m = date.month;
      if (countryCode == 'AE') {
        if (m >= 11 || m <= 3) {
          mMultiplier = 1.25;
          occupancy = 97.0;
          mSeason = PricingSeasonType.tourismPeak;
        } else if (m >= 6 && m <= 8) {
          mMultiplier = 0.94;
          occupancy = 84.0;
          mSeason = PricingSeasonType.shoulderOffPeak;
        } else {
          mMultiplier = 1.08;
          occupancy = 91.0;
          mSeason = PricingSeasonType.shoulderOffPeak;
        }
      } else {
        if (seasonType == PricingSeasonType.summerCoast && (m >= 6 && m <= 8)) {
          mMultiplier = 1.60;
          occupancy = 98.0;
          mSeason = PricingSeasonType.summerCoast;
        } else if (m == 8 || m == 9 || m == 1 || m == 2) {
          mMultiplier = 1.20;
          occupancy = 96.0;
          mSeason = PricingSeasonType.academicSurge;
        } else {
          mMultiplier = 1.06;
          occupancy = 88.0;
          mSeason = PricingSeasonType.shoulderOffPeak;
        }
      }

      final recPrice = (baseRent * mMultiplier).roundToDouble();
      final highPrice = (recPrice * 1.12).roundToDouble();
      final floorPrice = (recPrice * 0.92).roundToDouble();

      months.add(
        MonthlyPriceForecast(
          monthKey: mKey,
          monthName: {
            'ar': monthNamesAr[mIndex],
            'en': monthNamesEn[mIndex],
            'hi': monthNamesHi[mIndex],
          },
          basePrice: baseRent,
          recommendedPrice: recPrice,
          highSurgePrice: highPrice,
          floorPrice: floorPrice,
          occupancyRatePct: occupancy,
          seasonType: mSeason,
        ),
      );
    }

    return months;
  }

  /// Apply Dynamic Price to an asset and refresh state
  Future<bool> applyDynamicPrice({
    required String assetId,
    required double newMonthlyRent,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final currentSummary = _summaryNotifier.value;
    if (currentSummary == null) return false;

    _appliedAssetIds.add(assetId);

    final updatedRecommendations = currentSummary.assetRecommendations.map((r) {
      if (r.asset.id == assetId) {
        return AssetDynamicPricingItem(
          asset: r.asset,
          currentBaseRent: newMonthlyRent,
          recommendedDynamicRent: newMonthlyRent,
          originalBaseRent: r.originalBaseRent,
          dynamicMultiplier: r.dynamicMultiplier,
          projectedAnnualNetGain: r.projectedAnnualNetGain,
          projectedYieldIncreasePct: r.projectedYieldIncreasePct,
          projectedVacancyReductionDays: r.projectedVacancyReductionDays,
          currentSeasonType: r.currentSeasonType,
          strategyRecommendation: r.strategyRecommendation,
          demandDriversAr: r.demandDriversAr,
          demandDriversEn: r.demandDriversEn,
          demandDriversHi: r.demandDriversHi,
          monthlyForecastCurve: r.monthlyForecastCurve,
          isAutoPilotEnabled: r.isAutoPilotEnabled,
          isApplied: true,
        );
      }
      return r;
    }).toList();

    double totalCur = 0;
    double totalOpt = 0;
    for (final item in updatedRecommendations) {
      totalCur += item.currentBaseRent * 12;
      totalOpt += item.recommendedDynamicRent * 12;
    }

    _summaryNotifier.value = PortfolioYieldOptimizationSummary(
      countryCode: currentSummary.countryCode,
      totalManagedAssets: currentSummary.totalManagedAssets,
      totalCurrentAnnualRent: totalCur,
      totalOptimizedAnnualRent: totalOpt,
      netAnnualRevenueGain: totalOpt - totalCur,
      averageYieldIncreasePct: currentSummary.averageYieldIncreasePct,
      totalVacancyDaysSaved: currentSummary.totalVacancyDaysSaved,
      assetRecommendations: updatedRecommendations,
    );

    return true;
  }

  /// Toggle Auto-Pilot Dynamic Yield for an asset
  void toggleAutoPilot(String assetId) {
    final currentSummary = _summaryNotifier.value;
    if (currentSummary == null) return;

    for (final r in currentSummary.assetRecommendations) {
      if (r.asset.id == assetId) {
        r.isAutoPilotEnabled = !r.isAutoPilotEnabled;
        break;
      }
    }
    _summaryNotifier.value = PortfolioYieldOptimizationSummary(
      countryCode: currentSummary.countryCode,
      totalManagedAssets: currentSummary.totalManagedAssets,
      totalCurrentAnnualRent: currentSummary.totalCurrentAnnualRent,
      totalOptimizedAnnualRent: currentSummary.totalOptimizedAnnualRent,
      netAnnualRevenueGain: currentSummary.netAnnualRevenueGain,
      averageYieldIncreasePct: currentSummary.averageYieldIncreasePct,
      totalVacancyDaysSaved: currentSummary.totalVacancyDaysSaved,
      assetRecommendations: List.from(currentSummary.assetRecommendations),
    );
  }
}
