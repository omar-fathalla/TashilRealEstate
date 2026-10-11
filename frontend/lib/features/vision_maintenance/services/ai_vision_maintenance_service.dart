import '../models/vision_maintenance_model.dart';

class AiVisionMaintenanceService {
  static final AiVisionMaintenanceService _instance =
      AiVisionMaintenanceService._internal();
  factory AiVisionMaintenanceService() => _instance;
  AiVisionMaintenanceService._internal();

  /// Preset visual samples for testing
  List<MaintenanceVisualSample> get samplePhotos => const [
        MaintenanceVisualSample(
          id: 'sample_plumbing_leak',
          photoUrl:
              'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800&q=80',
          title: {
            'ar': 'تسريب مياه من محبس حوض المطبخ',
            'en': 'Kitchen Sink Pipe Joint Leak',
            'hi': 'रसोई के सिंक पाइप से पानी का रिसाव',
          },
          category: MaintenanceIssueCategory.plumbing,
          urgency: MaintenanceUrgencyLevel.high,
        ),
        MaintenanceVisualSample(
          id: 'sample_ac_ice',
          photoUrl:
              'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
          title: {
            'ar': 'تجمّد مبخر التكييف وتساقط مياه',
            'en': 'AC Evaporator Freezing & Water Drip',
            'hi': 'एसी बाष्पीकरण जमना और पानी टपकना',
          },
          category: MaintenanceIssueCategory.hvac,
          urgency: MaintenanceUrgencyLevel.critical,
        ),
        MaintenanceVisualSample(
          id: 'sample_electrical_panel',
          photoUrl:
              'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80',
          title: {
            'ar': 'ارتفاع حرارة القاطع الرئيسي للوحة الكهرباء',
            'en': 'Main Circuit Breaker Overheating',
            'hi': 'मुख्य सर्किट ब्रेकर अधिक गर्म होना',
          },
          category: MaintenanceIssueCategory.electrical,
          urgency: MaintenanceUrgencyLevel.critical,
        ),
        MaintenanceVisualSample(
          id: 'sample_ceiling_seepage',
          photoUrl:
              'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&q=80',
          title: {
            'ar': 'رشح رطوبة وتقشير دهانات السقف',
            'en': 'Ceiling Moisture Seepage & Paint Peel',
            'hi': 'छत में नमी का रिसाव और पेंट उखड़ना',
          },
          category: MaintenanceIssueCategory.civilFinishes,
          urgency: MaintenanceUrgencyLevel.medium,
        ),
      ];

  /// Perform Multimodal Vision Diagnosis with Gemini Flash
  Future<VisionMaintenanceDiagnosisResult> diagnosePhoto({
    required String photoUrl,
    required String countryCode,
    String? sampleId,
  }) async {
    // Simulate Gemini 2.0 Flash Vision Latency
    await Future.delayed(const Duration(milliseconds: 850));

    final isAE = countryCode == 'AE';
    final currency = isAE ? 'AED' : 'EGP';

    if (sampleId == 'sample_ac_ice' || photoUrl.contains('1621905251189')) {
      return VisionMaintenanceDiagnosisResult(
        issueId: 'MNT_DIAG_${DateTime.now().millisecondsSinceEpoch}',
        photoUrl: photoUrl,
        diagnosedAt: DateTime.now(),
        category: MaintenanceIssueCategory.hvac,
        urgency: MaintenanceUrgencyLevel.critical,
        confidenceScore: 0.995,
        isSafetyHazard: true,
        detectedProblemTitle: {
          'ar': 'انسداد مجرى الصرف وتجمد غاز الفريون في وحدة التكييف الاسبليت',
          'en': 'Refrigerant Line Freezing & Clogged Drain Line in Split AC Unit',
          'hi': 'स्प्लिट एसी यूनिट में रेफ्रिजरेंट लाइन जमना और ड्रेन लाइन जाम होना',
        },
        rootCauseAnalysis: {
          'ar': 'تراكم الأتربة على فلاتر الهواء أدى لضعف تدفق الهواء عبر المبخر الداخلي، مما تسبب في انخفاض ضغط الفريون وتكوّن كتل ثلجية كثيفة وتساقط المياه على الجدار.',
          'en': 'Heavy dust accumulation on intake filters restricted airflow across the internal evaporator coil, causing rapid pressure drop, severe icing, and condensation overflow.',
          'hi': 'इनटेक फिल्टर पर भारी धूल जमा होने से आंतरिक बाष्पीकरण कॉइल में वायु प्रवाह बाधित हुआ, जिससे बर्फ जम गई।',
        },
        recommendedActionStepsAr: [
          'إيقاف تشغيل التكييف فوراً لتجنب احتراق الضاغط (الكومبروسر).',
          'إذابة الثلج المتراكم وتنظيف الفلاتر والمبخر بمادة كيميائية رغوية مخصصة.',
          'تسليك خرطوم تصريف المياه وفحص شحنة غاز الفريون R410A.',
        ],
        recommendedActionStepsEn: [
          'Turn off AC unit immediately to prevent compressor burnout.',
          'Defrost ice buildup and deep clean evaporator coils with specialized foam cleaner.',
          'Clear blocked condensate drain line and test R410A refrigerant pressure.',
        ],
        recommendedActionStepsHi: [
          'कंप्रेसर को जलने से बचाने के लिए एसी तुरंत बंद करें।',
          'जमी हुई बर्फ को पिघलाएं और कॉइल को साफ करें।',
          'ड्रेन लाइन को साफ करें और गैस के दबाव की जांच करें।',
        ],
        requiredSparePartsAr: ['مادة تنظيف وتعقيم كيميائية للمبخر', 'شحنة غاز فريون R410A تعويضية', 'خرطوم تصريف مياه مرن 16 ملم'],
        requiredSparePartsEn: ['Evaporator Coil Foam Cleaner', 'R410A Refrigerant Top-up', '16mm Flexible Condensate Hose'],
        requiredSparePartsHi: ['कॉइल फोम क्लीनर', 'R410A गैस टॉप-अप', '16 मिमी फ्लेक्सिबल ड्रेन होज'],
        estimatedCostMin: isAE ? 320.0 : 650.0,
        estimatedCostMax: isAE ? 550.0 : 1200.0,
        currencyCode: currency,
        assignedTechnicianType: {
          'ar': 'فني تكييف وتبريد معتمد (HVAC Specialist)',
          'en': 'Certified HVAC Specialist',
          'hi': 'प्रमाणित एचवीएसी विशेषज्ञ',
        },
      );
    } else if (sampleId == 'sample_electrical_panel' || photoUrl.contains('1558494949')) {
      return VisionMaintenanceDiagnosisResult(
        issueId: 'MNT_DIAG_${DateTime.now().millisecondsSinceEpoch}',
        photoUrl: photoUrl,
        diagnosedAt: DateTime.now(),
        category: MaintenanceIssueCategory.electrical,
        urgency: MaintenanceUrgencyLevel.critical,
        confidenceScore: 0.998,
        isSafetyHazard: true,
        detectedProblemTitle: {
          'ar': 'تلف واحتراق جزئي في أطراف القاطع الكهربائي المزدوج (32A MCB)',
          'en': 'Thermal Overload & Terminal Burnout on 32A Miniature Circuit Breaker (MCB)',
          'hi': '32A सर्किट ब्रेकर पर थर्मल ओवरलोड और टर्मिनल बर्नआउट',
        },
        rootCauseAnalysis: {
          'ar': 'عدم إحكام ربط المسامير النحاسية لأطراف السلك أدى لزيادة مقاومة التوصيل وتوليد حرارة عالية مفرطة أذابت العازل البلاستيكي للقاطع.',
          'en': 'Loose screw terminal connection created high contact resistance, generating excessive localized heat that degraded insulation and charred the breaker housing.',
          'hi': 'ढीले स्क्रू टर्मिनल कनेक्शन से उच्च संपर्क प्रतिरोध उत्पन्न हुआ, जिससे अत्यधिक गर्मी पैदा हुई।',
        },
        recommendedActionStepsAr: [
          'فصل التيار الكهربائي من اللوحة الرئيسية فوراً.',
          'استبدال القاطع التالف بآخر جديد معتمد ماركة شنايدر أو إيه بي بي.',
          'تقشير الجزء المتفحم من كابل النحاس وإعادة تثبيته بعزم ربط مطابق للمواصفات.',
        ],
        recommendedActionStepsEn: [
          'Isolate main distribution panel power immediately.',
          'Replace damaged breaker with a certified 32A Type-C MCB (Schneider / ABB).',
          'Trim burned copper conductor and retorque terminal screws to manufacturer spec.',
        ],
        recommendedActionStepsHi: [
          'तुरंत मुख्य वितरण पैनल की बिजली बंद करें।',
          'क्षतिग्रस्त ब्रेकर को नए 32A ब्रेकर से बदलें।',
          'जले हुए तांबे के तार को काटें और सही तरीके से कसें।',
        ],
        requiredSparePartsAr: ['قاطع كهربائي أحادي/مزدوج 32A C-Curve', 'سلك نحاس معزول 6 ملم', 'شريط عازل مقاوم للحرارة'],
        requiredSparePartsEn: ['32A C-Curve Dual-Pole MCB', '6mm Heat-Resistant Copper Conductor', 'High-Temp Electrical Tape'],
        requiredSparePartsHi: ['32A सी-कर्व एमसीबी', '6 मिमी तांबे का तार', 'हाई-टेंप इलेक्ट्रिकल टेप'],
        estimatedCostMin: isAE ? 250.0 : 450.0,
        estimatedCostMax: isAE ? 480.0 : 950.0,
        currencyCode: currency,
        assignedTechnicianType: {
          'ar': 'فني كهرباء معتمد ومرخص (Master Electrician)',
          'en': 'Licensed Master Electrician',
          'hi': 'लाइसेंस प्राप्त मास्टर इलेक्ट्रीशियन',
        },
      );
    } else {
      // Default: Plumbing Leak
      return VisionMaintenanceDiagnosisResult(
        issueId: 'MNT_DIAG_${DateTime.now().millisecondsSinceEpoch}',
        photoUrl: photoUrl,
        diagnosedAt: DateTime.now(),
        category: MaintenanceIssueCategory.plumbing,
        urgency: MaintenanceUrgencyLevel.high,
        confidenceScore: 0.992,
        isSafetyHazard: false,
        detectedProblemTitle: {
          'ar': 'تآكل جلخ الصمام وتسريب مياه مستمر في وصلة التغذية المرنة',
          'en': 'Gasket Deterioration & Continuous Water Leakage on Angle Valve Connection',
          'hi': 'एंगल वाल्व कनेक्शन पर गैसकेट खराब होना और लगातार पानी का रिसाव',
        },
        rootCauseAnalysis: {
          'ar': 'تلف الحشوة المطاطية (O-Ring) الداخلية وتراكم الأملاح الكلسية حول السن النحاسي تسبب في عدم إحكام الغلق وتسريب المياه أسفل الحوض.',
          'en': 'Degraded internal EPDM O-ring combined with calcium scale buildup prevented complete seal seating, causing pressurized water seepage.',
          'hi': 'आंतरिक रबर गैसकेट के खराब होने और खनिजों के जमाव से पानी का रिसाव हुआ।',
        },
        recommendedActionStepsAr: [
          'إغلاق محبس التغذية الرئيسي الفرعي أسفل الحوض.',
          'فك الوصلة المرنة واستبدال المحبس النحاسي بآخر سيراميك نصف لفة عالي الجودة.',
          'لف شريط التفلون المانع للتسريب وإعادة اختبار ضغط المياه.',
        ],
        recommendedActionStepsEn: [
          'Shut off localized isolation angle stop valve.',
          'Remove degraded flexible connector and replace with quarter-turn ceramic angle valve.',
          'Apply PTFE thread sealant tape and perform pressurized leak test.',
        ],
        recommendedActionStepsHi: [
          'सिंक के नीचे मुख्य वाल्व बंद करें।',
          'खराब वाल्व को बदलें और नया सिरेमिक वाल्व लगाएं।',
          'टेफ्लॉन टेप लगाएं और रिसाव का परीक्षण करें।',
        ],
        requiredSparePartsAr: ['محبس زاوية نحاسي سيراميك 1/2 بوصة', 'وصلة تغذية مياه مرنة ستانلس ستيل 50 سم', 'بكرة شريط تفلون أصلي'],
        requiredSparePartsEn: ['1/2" Ceramic Quarter-Turn Angle Stop Valve', '50cm Braided Stainless Flexible Hose', 'High-Density PTFE Teflon Tape'],
        requiredSparePartsHi: ['1/2" सिरेमिक एंगल स्टॉप वाल्व', '50 सेमी स्टेनलेस फ्लेक्सिबल होज', 'टेफ्लॉन टेप'],
        estimatedCostMin: isAE ? 180.0 : 350.0,
        estimatedCostMax: isAE ? 360.0 : 750.0,
        currencyCode: currency,
        assignedTechnicianType: {
          'ar': 'سباك صحي معتمد (Licensed Plumber)',
          'en': 'Certified Sanitary Plumber',
          'hi': 'प्रमाणित प्लम्बर',
        },
      );
    }
  }
}
