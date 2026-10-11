import '../models/executive_report_model.dart';

class AiExecutiveReportingService {
  static final AiExecutiveReportingService _instance =
      AiExecutiveReportingService._internal();
  factory AiExecutiveReportingService() => _instance;
  AiExecutiveReportingService._internal();

  /// Generate a comprehensive AI Executive Financial Report with Gemini structured insights
  Future<ExecutiveFinancialReport> generateExecutiveReport({
    required String countryCode,
    String period = 'Q3 2026',
  }) async {
    // Simulate Gemini Pro structured analysis latency
    await Future.delayed(const Duration(milliseconds: 800));

    final isAE = countryCode == 'AE';
    final currency = isAE ? 'AED' : 'EGP';

    if (isAE) {
      return _generateUaeReport(period, currency);
    } else {
      return _generateEgyptReport(period, currency);
    }
  }

  ExecutiveFinancialReport _generateUaeReport(String period, String currency) {
    return ExecutiveFinancialReport(
      reportId: 'EXEC_RPT_AE_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      periodLabel: period,
      countryCode: 'AE',
      currencyCode: currency,
      totalPortfolioValuation: 38500000.0, // 38.5M AED
      grossRentalIncome: 860000.0, // 860k AED / quarter
      operatingExpenses: 115000.0, // 115k AED (Management, Service charges, Maintenance)
      netOperatingIncome: 745000.0, // 745k AED (NOI)
      capRatePercentage: 8.7, // 8.7% Cap Rate
      cashOnCashReturnPercentage: 11.4, // 11.4%
      occupancyRatePercentage: 97.2, // 97.2% Occupancy
      rentCollectionEfficiencyPercentage: 99.6, // 99.6%
      totalManagedUnits: 24,
      activeLeasesCount: 23,
      executiveSummary: {
        'ar': 'حقق أداء المحفظة العقارية في دولة الإمارات خلال هذا الربع نمواً استثنائياً؛ حيث ارتفع صافي الدخل التشغيلي (NOI) بنسبة 14.2% مدفوعاً بزيادة الطلب في دبي مارينا ودبي هيلز. بلغت كفاءة التحصيل 99.6% مع نسبة إشغال قياسية 97.2% واستقرار كامل في التدفقات النقدية.',
        'en': 'The UAE real estate portfolio achieved outstanding performance this quarter, with Net Operating Income (NOI) surging by 14.2% driven by strong demand across Dubai Marina and Dubai Hills. Collection efficiency reached 99.6% with record 97.2% occupancy.',
        'hi': 'यूएई रियल एस्टेट पोर्टफोलियो ने इस तिमाही में उत्कृष्ट प्रदर्शन हासिल किया, जिसमें दुबई मरीना और दुबई हिल्स में मजबूत मांग के कारण शुद्ध परिचालन आय (NOI) में 14.2% की वृद्धि हुई।',
      },
      cashFlowOutlook: {
        'ar': 'توقعات التدفقات النقدية للربعين القادمين مستقرة جداً؛ حيث من المتوقع تحصيل 1.84 مليون درهم بفضل دخول موسم السياحة الشتوي وتطبيق خوارزمية التسعير الديناميكي التي تضمن مضاعف عائد +22%.',
        'en': 'Cash flow outlook for upcoming quarters remains robust with projected collections of AED 1.84M, bolstered by winter tourism influx and dynamic yield surge pricing delivering +22% yields.',
        'hi': 'आगामी तिमाहियों के लिए नकदी प्रवाह का दृष्टिकोण बहुत मजबूत है, जिसमें 1.84 मिलियन दिरहम के अनुमानित संग्रह की उम्मीद है।',
      },
      leaseExpirationRisks: [
        LeaseExpirationRiskItem(
          propertyId: 'ae_prop_01',
          propertyTitle: {
            'ar': 'بنتهاوس فاخر - دبي مارينا ووترفرونت',
            'en': 'Luxury Penthouse - Dubai Marina Waterfront',
            'hi': 'लक्जरी पेंटहाउस - दुबई मरीना वाटरफ्रंट',
          },
          tenantName: 'ألكسندر سميث',
          expirationDate: DateTime.now().add(const Duration(days: 42)),
          daysRemaining: 42,
          currentMonthlyRent: 28000.0,
          renewalProbability: 0.88,
          actionRecommendation: {
            'ar': 'إرسال عرض تجديد بعقد سنوي مع زيادة 7% متوافقة مع مؤشر ريرا (RERA Index)',
            'en': 'Send 1-year renewal notice with 7% rent escalation compliant with RERA Index',
            'hi': 'रेरा इंडेक्स के अनुपालन में 7% किराया वृद्धि के साथ 1 साल का नवीनीकरण नोटिस भेजें',
          },
        ),
        LeaseExpirationRiskItem(
          propertyId: 'ae_prop_02',
          propertyTitle: {
            'ar': 'شقة دوبلكس عائلية - دبي هيلز إستيت',
            'en': 'Family Duplex - Dubai Hills Estate',
            'hi': 'फैमिली डुप्लेक्स - दुबई हिल्स एस्टेट',
          },
          tenantName: 'طارق المنصوري',
          expirationDate: DateTime.now().add(const Duration(days: 75)),
          daysRemaining: 75,
          currentMonthlyRent: 22500.0,
          renewalProbability: 0.94,
          actionRecommendation: {
            'ar': 'تثبيت العقد لمدة سنتين مع الحفاظ على المستأجر الممتاز لتقليل الشغور لـ 0%',
            'en': 'Lock 2-year lease extension to secure top-tier tenant and eliminate vacancy',
            'hi': 'शीर्ष किरायेदार को बनाए रखने और रिक्ति को खत्म करने के लिए 2 साल का पट्टा विस्तार करें',
          },
        ),
      ],
      strategicGrowthRecommendations: const [
        StrategicGrowthRecommendationItem(
          titleAr: 'الاستحواذ على شقق استوديو مفروشة في دبي مارينا',
          titleEn: 'Acquisition of Turnkey Studio Apartments in Dubai Marina',
          titleHi: 'दुबई मरीना में फर्निश्ड स्टूडियो अपार्टमेंट का अधिग्रहण',
          descriptionAr: 'فرصة توسعية لشراء وحدتين استوديو جاهزتين بعائد إيجاري متوقع 9.8% مع تشغيل فندقي قصير ومتوسط الأجل.',
          descriptionEn: 'Strategic opportunity to acquire 2 turnkey studios with projected 9.8% rental yield under flexible short-term management.',
          descriptionHi: 'लचीले प्रबंधन के तहत 9.8% अनुमानित किराये की उपज के साथ 2 स्टूडियो प्राप्त करने का अवसर।',
          targetRegion: 'Dubai Marina & JBR',
          projectedRoiPercentage: 9.8,
          estimatedCapitalRequired: '1,750,000 AED',
          urgencyLevel: 'high',
        ),
        StrategicGrowthRecommendationItem(
          titleAr: 'إعادة استثمار فوائض السيولة في وحدات تجارية بـ Downtown',
          titleEn: 'Reinvest Surplus Liquidity in Downtown Commercial Suites',
          titleHi: 'डाउनटाउन वाणिज्यिक सुइट्स में अधिशेष तरलता का पुनर्निवेश',
          descriptionAr: 'عقود إيجار طويلة الأجل لمدة 5 سنوات للشركات متعددة الجنسيات تضمن تدفقات نقدية خالية من المخاطر.',
          descriptionEn: 'Long-term 5-year corporate leases for multinational tenants securing risk-free cash flows.',
          descriptionHi: 'बहुराष्ट्रीय किरायेदारों के लिए दीर्घकालिक 5-वर्षीय कॉर्पोरेट पट्टे।',
          targetRegion: 'Downtown Dubai / Business Bay',
          projectedRoiPercentage: 8.5,
          estimatedCapitalRequired: '3,200,000 AED',
          urgencyLevel: 'strategic',
        ),
      ],
      monthlyTrends: const [
        MonthlyFinancialTrendItem(
          monthLabelAr: 'مايو 2026',
          monthLabelEn: 'May 2026',
          monthLabelHi: 'मई 2026',
          grossIncome: 275000.0,
          expenses: 36000.0,
          netIncome: 239000.0,
        ),
        MonthlyFinancialTrendItem(
          monthLabelAr: 'يونيو 2026',
          monthLabelEn: 'Jun 2026',
          monthLabelHi: 'जून 2026',
          grossIncome: 288000.0,
          expenses: 39000.0,
          netIncome: 249000.0,
        ),
        MonthlyFinancialTrendItem(
          monthLabelAr: 'يوليو 2026',
          monthLabelEn: 'Jul 2026',
          monthLabelHi: 'जुलाई 2026',
          grossIncome: 297000.0,
          expenses: 40000.0,
          netIncome: 257000.0,
        ),
      ],
    );
  }

  ExecutiveFinancialReport _generateEgyptReport(String period, String currency) {
    return ExecutiveFinancialReport(
      reportId: 'EXEC_RPT_EG_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      periodLabel: period,
      countryCode: 'EG',
      currencyCode: currency,
      totalPortfolioValuation: 145000000.0, // 145M EGP
      grossRentalIncome: 3450000.0, // 3.45M EGP / quarter
      operatingExpenses: 420000.0, // 420k EGP
      netOperatingIncome: 3030000.0, // 3.03M EGP (NOI)
      capRatePercentage: 9.4, // 9.4% Cap Rate
      cashOnCashReturnPercentage: 12.8, // 12.8%
      occupancyRatePercentage: 96.5, // 96.5% Occupancy
      rentCollectionEfficiencyPercentage: 99.2, // 99.2%
      totalManagedUnits: 38,
      activeLeasesCount: 36,
      executiveSummary: {
        'ar': 'أظهرت المحفظة العقارية في السوق المصري مرونة استثمارية فائقة، مع نمو صافي العائد التشغيلي (NOI) بنسبة 18.5% بفضل ارتفاع الطلب على الشقق الفاخرة في القاهرة الجديدة (التجمع الخامس) والشيخ زايد والساحل الشمالي. بلغت كفاءة التحصيل 99.2% ومعدل الإشغال 96.5%.',
        'en': 'The Egyptian real estate portfolio exhibited strong resilience, with Net Operating Income (NOI) rising by 18.5% driven by high demand for luxury units in New Cairo (Fifth Settlement), Sheikh Zayed, and North Coast.',
        'hi': 'मिस्र के रियल एस्टेट पोर्टफोलियो ने मजबूत लचीलापन दिखाया, जिसमें न्यू काहिरा और शेख जायद में उच्च मांग के कारण शुद्ध परिचालन आय (NOI) में 18.5% की वृद्धि हुई।',
      },
      cashFlowOutlook: {
        'ar': 'التدفقات النقدية المتوقعة للربع القادم تقدر بحوالي 3.85 مليون ج.م مع بدء موسم استقبال طلاب الجامعة الأمريكية والمغتربين، مما يتيح تطبيق زيادات إيجارية بنسبة 15% إلى 18% على الوحدات المفروشة.',
        'en': 'Projected cash flow for the upcoming quarter is estimated at EGP 3.85M with university student intake, enabling 15-18% rent adjustments on furnished assets.',
        'hi': 'विश्वविद्यालय के छात्रों के आगमन के साथ आगामी तिमाही के लिए अनुमानित नकदी प्रवाह 3.85 मिलियन ईजीपी होने का अनुमान है।',
      },
      leaseExpirationRisks: [
        LeaseExpirationRiskItem(
          propertyId: 'eg_prop_01',
          propertyTitle: {
            'ar': 'فيلا مستقلة بحمام سباحة - التجمع الخامس',
            'en': 'Standalone Villa with Pool - Fifth Settlement',
            'hi': 'पूल के साथ स्टैंडअलोन विला - फिफ्थ सेटलमेंट',
          },
          tenantName: 'د. خالد عبد الرحمن',
          expirationDate: DateTime.now().add(const Duration(days: 35)),
          daysRemaining: 35,
          currentMonthlyRent: 65000.0,
          renewalProbability: 0.91,
          actionRecommendation: {
            'ar': 'إبرام عقد تجديد سنوي مع تعديل القيمة الإيجارية بنسبة 12% وفق معدل التضخم السنوي',
            'en': 'Execute 1-year lease renewal with 12% inflation adjustment',
            'hi': 'वार्षिक मुद्रास्फीति दर के अनुसार 12% समायोजन के साथ नवीनीकरण करें',
          },
        ),
        LeaseExpirationRiskItem(
          propertyId: 'eg_prop_02',
          propertyTitle: {
            'ar': 'شقة فندقية مودرن - بالم هيلز الشيخ زايد',
            'en': 'Modern Hotel Apartment - Palm Hills Sheikh Zayed',
            'hi': 'मॉडर्न होटल अपार्टमेंट - पाम हिल्स शेख जायद',
          },
          tenantName: 'م. كريم الشناوي',
          expirationDate: DateTime.now().add(const Duration(days: 60)),
          daysRemaining: 60,
          currentMonthlyRent: 38000.0,
          renewalProbability: 0.85,
          actionRecommendation: {
            'ar': 'تأكيد التجديد قبل 45 يوماً مع تقديم خيار سداد 6 أشهر مقدماً لضمان السيولة',
            'en': 'Confirm renewal 45 days early with 6-month upfront payment option',
            'hi': 'तरलता सुरक्षित करने के लिए 6 महीने के अग्रिम भुगतान विकल्प के साथ नवीनीकरण करें',
          },
        ),
      ],
      strategicGrowthRecommendations: const [
        StrategicGrowthRecommendationItem(
          titleAr: 'الاستثمار في مكاتب إدارية بالعاصمة الإدارية والتجمع',
          titleEn: 'Invest in Prime Commercial & Admin Offices in New Capital & New Cairo',
          titleHi: 'न्यू कैपिटल और न्यू काहिरा में प्राइम कमर्शियल और एडमिन ऑफिस में निवेश',
          descriptionAr: 'الوحدات الإدارية تحقق عوائد إيجارية صافية تتراوح بين 14% إلى 16% بعقود إيجار إلزامية مدتها 3 إلى 9 سنوات.',
          descriptionEn: 'Administrative office suites generate net yields between 14-16% with mandatory 3-to-9 year institutional corporate leases.',
          descriptionHi: 'प्रशासनिक कार्यालय 14-16% के बीच शुद्ध उपज उत्पन्न करते हैं।',
          targetRegion: 'New Administrative Capital & Golden Square',
          projectedRoiPercentage: 15.2,
          estimatedCapitalRequired: '8,500,000 EGP',
          urgencyLevel: 'high',
        ),
        StrategicGrowthRecommendationItem(
          titleAr: 'شراء شقق فندقية في الساحل الشمالي للاستثمار الصيفي',
          titleEn: 'Acquisition of North Coast Chalets for Peak Summer Rentals',
          titleHi: 'पीक समर रेंटल के लिए नॉर्थ कोस्ट शैले का अधिग्रहण',
          descriptionAr: 'تحقيق عوائد سياحية مرتفعة في أشهر الصيف (مايو - سبتمبر) تعادل دخل عام كامل للشقق التقليدية.',
          descriptionEn: 'Generate massive summer tourism yields (May-Sep) matching annual standard rental yields in 4 months.',
          descriptionHi: 'गर्मियों के महीनों (मई - सितंबर) में उच्च पर्यटन उपज उत्पन्न करें।',
          targetRegion: 'Ras El Hekma & Sidi Abdel Rahman',
          projectedRoiPercentage: 18.0,
          estimatedCapitalRequired: '12,000,000 EGP',
          urgencyLevel: 'strategic',
        ),
      ],
      monthlyTrends: const [
        MonthlyFinancialTrendItem(
          monthLabelAr: 'مايو 2026',
          monthLabelEn: 'May 2026',
          monthLabelHi: 'मई 2026',
          grossIncome: 1100000.0,
          expenses: 135000.0,
          netIncome: 965000.0,
        ),
        MonthlyFinancialTrendItem(
          monthLabelAr: 'يونيو 2026',
          monthLabelEn: 'Jun 2026',
          monthLabelHi: 'जून 2026',
          grossIncome: 1150000.0,
          expenses: 140000.0,
          netIncome: 1010000.0,
        ),
        MonthlyFinancialTrendItem(
          monthLabelAr: 'يوليو 2026',
          monthLabelEn: 'Jul 2026',
          monthLabelHi: 'जुलाई 2026',
          grossIncome: 1200000.0,
          expenses: 145000.0,
          netIncome: 1055000.0,
        ),
      ],
    );
  }

  /// Generate CSV formatted spreadsheet
  String generateCsvSpreadsheet(ExecutiveFinancialReport report, String lang) {
    final buffer = StringBuffer();
    buffer.writeln('Tashil Real Estate - Executive Financial Report (${report.periodLabel})');
    buffer.writeln('Country,${report.countryCode}');
    buffer.writeln('Currency,${report.currencyCode}');
    buffer.writeln('Generated At,${report.generatedAt.toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Metric,Value,Unit');
    buffer.writeln('Total Portfolio Valuation,${report.totalPortfolioValuation},${report.currencyCode}');
    buffer.writeln('Gross Rental Income,${report.grossRentalIncome},${report.currencyCode}');
    buffer.writeln('Operating Expenses,${report.operatingExpenses},${report.currencyCode}');
    buffer.writeln('Net Operating Income (NOI),${report.netOperatingIncome},${report.currencyCode}');
    buffer.writeln('Cap Rate,${report.capRatePercentage},%');
    buffer.writeln('Cash-on-Cash Return,${report.cashOnCashReturnPercentage},%');
    buffer.writeln('Occupancy Rate,${report.occupancyRatePercentage},%');
    buffer.writeln('Rent Collection Efficiency,${report.rentCollectionEfficiencyPercentage},%');
    buffer.writeln('Managed Units,${report.totalManagedUnits},Units');
    buffer.writeln('Active Leases,${report.activeLeasesCount},Leases');
    buffer.writeln('');
    buffer.writeln('Monthly Trends Breakdown:');
    buffer.writeln('Month,Gross Income,Operating Expenses,Net Income');
    for (final item in report.monthlyTrends) {
      buffer.writeln('${item.getMonthLabel(lang)},${item.grossIncome},${item.expenses},${item.netIncome}');
    }
    return buffer.toString();
  }

  /// Generate WhatsApp / Shareable Executive Digest
  String generateWhatsAppDigest(ExecutiveFinancialReport report, String lang) {
    final currency = report.currencyCode;
    return '''📊 *تقرير الأداء المالي والتنفيذي - تسهيل العقارية (${report.periodLabel})*
🏢 *قيمة المحفظة:* ${report.totalPortfolioValuation.toInt()} $currency
💵 *إجمالي الدخل الإيجاري:* ${report.grossRentalIncome.toInt()} $currency
📈 *صافي الدخل التشغيلي (NOI):* ${report.netOperatingIncome.toInt()} $currency
🎯 *معدل الرسملة (Cap Rate):* ${report.capRatePercentage}%
🤝 *كفاءة التحصيل:* ${report.rentCollectionEfficiencyPercentage}% | *نسبة الإشغال:* ${report.occupancyRatePercentage}%

💡 *الملخص التنفيذي:*
${report.getExecutiveSummary(lang)}

⚡ تم التوليد آلياً بواسطة محرك التقارير التنفيذية لمنصة تسهيل العقارية.''';
  }
}
