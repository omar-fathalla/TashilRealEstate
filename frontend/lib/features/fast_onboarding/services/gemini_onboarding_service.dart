import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tashil_real_estate/core/config/ai_config.dart';
import 'package:tashil_real_estate/core/services/ai_quota_manager.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/models/ai_model_definition.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/services/ai_engine_config_controller.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';

class GeminiOnboardingService {
  static final GeminiOnboardingService _instance = GeminiOnboardingService._internal();
  factory GeminiOnboardingService() => _instance;
  GeminiOnboardingService._internal();

  static String get _apiKey => AiConfig.geminiApiKey;

  String _buildEndpoint(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';

  String get _propertyIngestionModel =>
      AiEngineConfigController().getModelName(AiServiceType.propertyIngestion);

  String get _copywritingModel =>
      AiEngineConfigController().getModelName(AiServiceType.marketingCopywriting);

  /// Converts Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩) to standard Western digits (0-9)
  static String normalizeArabicDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';
    var output = input;
    for (int i = 0; i < arabic.length; i++) {
      output = output.replaceAll(arabic[i], english[i]);
    }
    return output;
  }

  /// Synchronous heuristic parsing for real-time live preview & guidance in voice modal
  FastPropertyDraft parseVoiceHeuristically(String text, String countryCode) {
    return _fallbackParseVoice(text, countryCode == 'EG');
  }

  /// Parses spoken/voice input text into the 5 structured property sections
  Future<FastPropertyDraft> parseVoiceTranscriptionToDraft({
    required String voiceTranscription,
    required String countryCode,
  }) async {
    final quotaManager = AiQuotaManager();
    final isEgypt = countryCode == 'EG';

    if (quotaManager.hasAvailableQuota) {
      try {
        final prompt = '''
You are a senior PropTech AI Agent for Tashil Real Estate.
Extract all structured property listing parameters across 5 key sections from the user's voice dictation.

CRITICAL PARSING RULES:
1. Always output city and district in Arabic for Egypt (EG) and UAE (AE) (e.g. city: "الإسكندرية", district: "بحري").
2. "streetAddress": Extract explicit street name, road, or street number (e.g. "37 شارع الجمرك القديم", "شارع التسعين").
   - CRITICAL: Never put street names or addresses into "buildingName"! They MUST be placed in "streetAddress".
3. "buildingName": Strictly for named towers, buildings, or compounds (e.g. "برج الصفا", "كمبوند ميفيدا"). If only a street address is mentioned, return null for "buildingName".
4. "ايجار شهري 44000" or raw digits => monthlyRent: 44000.
5. "وساحه 140 م" or "مساحه 140" => areaSqm: 140.
6. "بدون فرش" => furnishingStatus: "unfurnished".
7. "بدون تكييف" => hasCentralAc: false.
8. "تامين شهرين" => securityDeposit: 88000 (monthlyRent * 2).
9. "unitNumber": If a unit, apartment, flat, or villa number is mentioned (e.g. "وحدة 304", "شقة 12", "فيلا 4", "مكتب 201", "رقم 15"), extract the exact number as string (e.g. "304", "12", "4", "201"). If not mentioned, return null.

Voice Transcription: "$voiceTranscription"
Country: $countryCode

Output STRICT JSON matching this 5-section schema:
{
  "section1_location": {
    "city": "اسم المدينة بالعربية (e.g. الإسكندرية, القاهرة, دبي)",
    "district": "اسم الحي أو المنطقة بالعربية (e.g. بحري, العجمي, التجمع الخامس)",
    "streetAddress": "اسم الشارع ورقم العقار الدقيق (e.g. 37 شارع الجمرك القديم) or null",
    "buildingName": "اسم البرج أو المبنى أو الكمبوند فقط (e.g. برج الصفا, كمبوند هايد بارك) or null",
    "unitNumber": "string or null",
    "latitude": number,
    "longitude": number
  },
  "section2_financials": {
    "monthlyRent": number,
    "currency": "EGP" | "AED" | "USD",
    "paymentFrequency": "monthly" | "quarterly" | "semiAnnual" | "annual",
    "securityDeposit": number or null,
    "isBillsIncluded": boolean,
    "isNegotiable": boolean
  },
  "section3_technical": {
    "propertyType": "apartment" | "villa" | "studio" | "office" | "chalet" | "penthouse",
    "areaSqm": number,
    "bedrooms": number,
    "bathrooms": number,
    "floor": number or null,
    "buildingAge": "brandNew" | "oneToFive" | "older" | null,
    "hasMaidsRoom": boolean
  },
  "section4_amenities": {
    "furnishingStatus": "fullyFurnished" | "semiFurnished" | "unfurnished",
    "hasParking": boolean,
    "hasCentralAc": boolean,
    "hasPoolGym": boolean,
    "hasSecurity": boolean,
    "hasBalconyView": boolean,
    "isPetFriendly": boolean
  },
  "section5_media": {
    "titleAr": "عنوان جذاب بالعربية",
    "titleEn": "Attractive English title",
    "titleHi": "Attractive Hindi title",
    "videoTourUrl": "url or null"
  }
}
Only output the raw JSON object without markdown fences.
''';

        final response = await http.post(
          Uri.parse(_buildEndpoint(_propertyIngestionModel)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'responseMimeType': 'application/json',
            }
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (content != null) {
            quotaManager.recordUsage();
            final parsedJson = jsonDecode(content.trim());
            return _jsonToDraft(parsedJson, countryCode);
          }
        }
      } catch (e) {
        debugPrint('Gemini Voice Parsing Error: $e');
      }
    }

    // Heuristic Localized Fallback Parser
    return _fallbackParseVoice(voiceTranscription, isEgypt);
  }

  /// Automatically generates high-converting marketing descriptions across 3 languages
  Future<Map<String, String>> generateMarketingDescriptions({
    required FastPropertyDraft draft,
    required PropertyMarketingTone tone,
  }) async {
    final quotaManager = AiQuotaManager();
    final currency = draft.currency;

    if (quotaManager.hasAvailableQuota) {
      try {
        final toneName = tone == PropertyMarketingTone.luxuryExecutive
            ? 'Luxury, prestigious, VIP executive tone'
            : tone == PropertyMarketingTone.cozyFamily
                ? 'Warm, family-friendly, comfortable and safe neighborhood tone'
                : 'High-yield investment, prime expat location, turnkey rental tone';

        final amenitiesList = <String>[];
        if (draft.hasParking) amenitiesList.add('Private Parking');
        if (draft.hasCentralAc) amenitiesList.add('Central AC');
        if (draft.hasPoolGym) amenitiesList.add('Pool and Gym');
        if (draft.hasSecurity) amenitiesList.add('24/7 Security');
        if (draft.hasBalconyView) amenitiesList.add('Balcony / Scenic View');
        if (draft.isPetFriendly) amenitiesList.add('Pet Friendly');

        final amenitiesSummary = amenitiesList.isNotEmpty
            ? amenitiesList.join(', ')
            : 'NONE (User selected NO additional amenities. STRICT INSTRUCTION: DO NOT mention, claim, or invent any amenities, parking, AC, pool, security, balcony, or pets)';

        final furnishingDesc = switch (draft.furnishingStatus) {
          FurnishingStatus.fullyFurnished => 'Fully Furnished',
          FurnishingStatus.semiFurnished => 'Semi Furnished',
          FurnishingStatus.unfurnished => 'Unfurnished',
        };

        final prompt = '''
You are an expert real estate copywriter.
Generate 3 distinct marketing descriptions for this property in Arabic (فصحى راقية وجذابة), English, and Hindi.
Tone: $toneName

Specs:
- Title: ${draft.titleAr} / ${draft.titleEn}
- Type: ${draft.propertyType}
- Location: ${draft.district}, ${draft.city} ${draft.buildingName != null && draft.buildingName!.isNotEmpty ? "(${draft.buildingName})" : ""}
- Area: ${draft.areaSqm} m²
- Bedrooms: ${draft.bedrooms}, Bathrooms: ${draft.bathrooms}, Floor: ${draft.floor ?? "Ground"}
- Furnishing: $furnishingDesc
- Rent: ${draft.monthlyRent} $currency / month (${draft.paymentFrequency.name})
- Bills Included: ${draft.isBillsIncluded ? "Yes" : "No"}, Negotiable: ${draft.isNegotiable ? "Yes" : "No"}
- Available Amenities: $amenitiesSummary

STRICT AMENITIES RULE:
Only mention the amenities explicitly listed as Available above. If 'NONE' is indicated, or an amenity is not in the list, you are strictly FORBIDDEN from inventing or mentioning unlisted amenities (such as parking, central air conditioning, pool, security, balcony, or pets). Reflect ONLY what is explicitly provided.

Output STRICT JSON:
{
  "ar": "الوصف العقاري التسويقي باللغة العربية مع إبراز المميزات ونقاط القوة ودعوة للتواصل...",
  "en": "Engaging English real estate description highlighting prime features and call to action...",
  "hi": "आकर्षक हिंदी रियल एस्टेट विवरण जो प्रमुख विशेषताओं और संपर्क करने के आह्वान को उजागर करता है..."
}
Do not mix languages inside each field.
''';

        final response = await http.post(
          Uri.parse(_buildEndpoint(_copywritingModel)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'responseMimeType': 'application/json',
            }
          }),
        ).timeout(const Duration(milliseconds: 4000));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (content != null) {
            quotaManager.recordUsage();
            final parsed = jsonDecode(content.trim());
            return {
              'ar': parsed['ar'] ?? '',
              'en': parsed['en'] ?? '',
              'hi': parsed['hi'] ?? '',
            };
          }
        }
      } catch (e) {
        debugPrint('Gemini Copywriting Error: $e');
      }
    }

    // High quality heuristic fallback descriptions
    return _generateFallbackDescriptions(draft, tone);
  }

  FastPropertyDraft _jsonToDraft(Map<String, dynamic> json, String countryCode) {
    final s1 = (json['section1_location'] as Map<String, dynamic>?) ?? {};
    final s2 = (json['section2_financials'] as Map<String, dynamic>?) ?? {};
    final s3 = (json['section3_technical'] as Map<String, dynamic>?) ?? {};
    final s4 = (json['section4_amenities'] as Map<String, dynamic>?) ?? {};
    final s5 = (json['section5_media'] as Map<String, dynamic>?) ?? {};

    // Payment Frequency parsing
    PaymentFrequency freq = PaymentFrequency.monthly;
    final freqStr = s2['paymentFrequency']?.toString().toLowerCase();
    if (freqStr == 'quarterly') freq = PaymentFrequency.quarterly;
    if (freqStr == 'semiannual') freq = PaymentFrequency.semiAnnual;
    if (freqStr == 'annual') freq = PaymentFrequency.annual;

    // Furnishing Status parsing
    FurnishingStatus furnishing = FurnishingStatus.unfurnished;
    final furnStr = s4['furnishingStatus']?.toString().toLowerCase();
    if (furnStr == 'fullyfurnished') furnishing = FurnishingStatus.fullyFurnished;
    if (furnStr == 'semifurnished') furnishing = FurnishingStatus.semiFurnished;
    if (furnStr == 'unfurnished') furnishing = FurnishingStatus.unfurnished;

    // Building age
    BuildingAge? age = BuildingAge.brandNew;
    final ageStr = s3['buildingAge']?.toString().toLowerCase();
    if (ageStr == 'onetofive') age = BuildingAge.oneToFive;
    if (ageStr == 'older') age = BuildingAge.older;

    // City & District normalization (ensure pure Arabic)
    String city = s1['city']?.toString() ?? '';
    final lowerCity = city.toLowerCase();
    if (lowerCity.contains('alexandria') || lowerCity.contains('alex') || lowerCity.contains('اسكندر') || lowerCity.contains('إسكندر')) {
      city = 'الإسكندرية';
    } else if (lowerCity.contains('cairo') || lowerCity.contains('قاهرة')) {
      city = 'القاهرة';
    } else if (lowerCity.contains('giza') || lowerCity.contains('جيزة')) {
      city = 'الجيزة';
    } else if (lowerCity.contains('dubai') || lowerCity.contains('دبي')) {
      city = 'دبي';
    } else if (lowerCity.contains('abu dhabi') || lowerCity.contains('أبوظبي')) {
      city = 'أبوظبي';
    }

    String district = s1['district']?.toString() ?? '';
    final lowerDistrict = district.toLowerCase();
    final allJsonText = json.toString().toLowerCase();
    if (lowerDistrict.contains('زراعيين') || allJsonText.contains('زراعيين')) {
      district = 'الكيلو 21 - الزراعيين';
    } else if (lowerDistrict.contains('agami') || lowerDistrict.contains('kilo 21') || lowerDistrict.contains('عجمي')) {
      district = 'العجمي - الكيلو 21';
    }

    double lat = (s1['latitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (s1['longitude'] as num?)?.toDouble() ?? 0.0;

    // Validate and correct coordinates if inaccurate or in desert
    if (district.contains('زراعيين') || allJsonText.contains('زراعيين')) {
      lat = 31.0860237;
      lng = 29.7130387;
    } else if (district.contains('21') && (lat < 31.07 || lat > 31.15)) {
      lat = 31.0860237;
      lng = 29.7130387;
    } else if (lat == 0.0 || lng == 0.0) {
      lat = countryCode == 'AE' ? 25.0772 : (city == 'الإسكندرية' ? 31.0860237 : 30.0131);
      lng = countryCode == 'AE' ? 55.1396 : (city == 'الإسكندرية' ? 29.7130387 : 31.4913);
    }

    final area = (s3['areaSqm'] as num?)?.toInt() ?? 0;
    String titleAr = s5['titleAr']?.toString() ?? '';
    if (titleAr.isEmpty || titleAr.contains('null') || titleAr == 'عنوان جذاب بالعربية') {
      final areaPart = area > 0 ? '$area م² ' : '';
      final districtPart = district.isNotEmpty ? 'في $district' : '';
      final cityPart = city.isNotEmpty ? '، $city' : '';
      titleAr = 'شقة فاخرة $areaPart$districtPart$cityPart بتشطيب سوبر لوكس';
    }

    // Extract street address and building name accurately
    String? streetAddress = s1['streetAddress']?.toString().trim();
    String? buildingName = s1['buildingName']?.toString().trim();
    if (streetAddress != null && (streetAddress.isEmpty || streetAddress == 'null')) {
      streetAddress = null;
    }
    if (buildingName != null && (buildingName.isEmpty || buildingName == 'null')) {
      buildingName = null;
    }
    // Safety check: if buildingName contains street terms (شارع, طريق) or starts with digits, move to streetAddress!
    if (buildingName != null) {
      if (buildingName.contains('شارع') || buildingName.contains('طريق') || RegExp(r'^\d+\s*').hasMatch(buildingName)) {
        streetAddress ??= buildingName;
        buildingName = null;
      }
    }
    String unitNumber = s1['unitNumber']?.toString().trim() ?? '';
    if (unitNumber == 'null') unitNumber = '';

    return FastPropertyDraft(
      // Section 1: Location
      latitude: lat,
      longitude: lng,
      city: city,
      district: district,
      streetAddress: streetAddress,
      buildingName: buildingName ?? '',
      unitNumber: unitNumber,
      photoUrls: [],

      // Section 2: Financials
      monthlyRent: (s2['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      currency: s2['currency']?.toString() ?? (countryCode == 'AE' ? 'AED' : 'EGP'),
      paymentFrequency: freq,
      securityDeposit: (s2['securityDeposit'] as num?)?.toDouble(),
      isBillsIncluded: s2['isBillsIncluded'] == true,
      isNegotiable: s2['isNegotiable'] != false,

      // Section 3: Technical Specs
      propertyType: s3['propertyType']?.toString() ?? 'apartment',
      areaSqm: area,
      bedrooms: (s3['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (s3['bathrooms'] as num?)?.toInt() ?? 0,
      floor: (s3['floor'] as num?)?.toInt(),
      buildingAge: age,
      hasMaidsRoom: s3['hasMaidsRoom'] == true,

      // Section 4: Amenities
      furnishingStatus: furnishing,
      hasParking: s4['hasParking'] == true,
      hasCentralAc: s4['hasCentralAc'] == true,
      hasPoolGym: s4['hasPoolGym'] == true,
      hasSecurity: s4['hasSecurity'] == true,
      hasBalconyView: s4['hasBalconyView'] == true,
      isPetFriendly: s4['isPetFriendly'] == true,

      // Section 5: Media
      titleAr: titleAr,
      titleEn: s5['titleEn']?.toString() ?? '',
      titleHi: s5['titleHi']?.toString() ?? '',
      videoTourUrl: s5['videoTourUrl']?.toString(),
      countryCode: countryCode,
    );
  }

  FastPropertyDraft _fallbackParseVoice(String rawText, bool isEgypt) {
    final text = normalizeArabicDigits(rawText);
    final lower = text.toLowerCase();

    // 1. Property Type
    String propertyType = 'apartment';
    if (lower.contains('فيلا') || lower.contains('villa')) {
      propertyType = 'villa';
    } else if (lower.contains('دوبلكس') || lower.contains('duplex')) {
      propertyType = 'villa';
    } else if (lower.contains('استوديو') || lower.contains('studio')) {
      propertyType = 'studio';
    } else if (lower.contains('شاليه') || lower.contains('chalet')) {
      propertyType = 'chalet';
    } else if (lower.contains('بنتهاوس') || lower.contains('penthouse') || lower.contains('روف')) {
      propertyType = 'penthouse';
    } else if (lower.contains('مكتب') || lower.contains('office')) {
      propertyType = 'office';
    }

    // 2. Area in Sqm
    int area = 0;
    final areaMatch1 = RegExp(r'(?:مساح[ةه]|وساح[ةه]|area)\s*(?:بالمتر\s*(?:المربع)?)?\s*[:=]?\s*(\d+)', caseSensitive: false).firstMatch(text);
    if (areaMatch1 != null) {
      area = int.tryParse(areaMatch1.group(1) ?? '') ?? 0;
    } else {
      final areaMatch2 = RegExp(r'(\d+)\s*(?:متر\s*(?:مربع)?|m2|sqm|م²|قدم|م\b)', caseSensitive: false).firstMatch(text);
      if (areaMatch2 != null) {
        area = int.tryParse(areaMatch2.group(1) ?? '') ?? 0;
      }
    }

    // 3. Bedrooms
    int beds = 0;
    if (propertyType == 'studio' || lower.contains('استوديو') || lower.contains('studio')) {
      beds = 0;
    } else if (lower.contains('غرفة واحدة') || lower.contains('غرفة نوم واحدة') || lower.contains('1 غرفة') || lower.contains('1 غرف') || lower.contains('1 bed') || lower.contains('1 bhk')) {
      beds = 1;
    } else if (lower.contains('غرفتين') || lower.contains('غرفتان') || lower.contains('2 غرفة') || lower.contains('2 غرف') || lower.contains('2 غرفه') || lower.contains('اثنين غرف') || lower.contains('غرفتين نوم') || lower.contains('2 bed') || lower.contains('2 bhk')) {
      beds = 2;
    } else if (lower.contains('3 غرف') || lower.contains('3 غرفة') || lower.contains('ثلاث غرف') || lower.contains('ثلاثة غرف') || lower.contains('3 bed') || lower.contains('3 bhk')) {
      beds = 3;
    } else if (lower.contains('4 غرف') || lower.contains('4 غرفة') || lower.contains('أربع غرف') || lower.contains('أربعة غرف') || lower.contains('4 bed') || lower.contains('4 bhk')) {
      beds = 4;
    } else if (lower.contains('5 غرف') || lower.contains('5 غرفة') || lower.contains('خمس غرف') || lower.contains('خمسة غرف') || lower.contains('5 bed')) {
      beds = 5;
    } else {
      final bedMatch = RegExp(r'\b(\d+)\s*(?:غرف\s*نوم|غرفة\s*نوم|غرف(?:ة|ات)?|نوم|bed|bhk)\b', caseSensitive: false).firstMatch(text);
      if (bedMatch != null) {
        beds = int.tryParse(bedMatch.group(1) ?? '0') ?? 0;
      } else {
        final bedPrefixMatch = RegExp(r'(?:غرف\s*نوم|غرفة\s*نوم|غرف(?:ة|ات)?|نوم)\s*[:=]?\s*(\d+)', caseSensitive: false).firstMatch(text);
        if (bedPrefixMatch != null) {
          beds = int.tryParse(bedPrefixMatch.group(1) ?? '0') ?? 0;
        }
      }
    }

    // 4. Bathrooms
    int baths = 0;
    if (lower.contains('حمام واحد') || lower.contains('1 حمام') || lower.contains('1 bath')) {
      baths = 1;
    } else if (lower.contains('حمامين') || lower.contains('حمامان') || lower.contains('2 حمام') || lower.contains('اثنين حمام') || lower.contains('2 bath')) {
      baths = 2;
    } else if (lower.contains('3 حمام') || lower.contains('3 حمامات') || lower.contains('ثلاث حمامات') || lower.contains('ثلاثة حمامات') || lower.contains('3 bath')) {
      baths = 3;
    } else if (lower.contains('4 حمام') || lower.contains('4 حمامات') || lower.contains('أربع حمامات') || lower.contains('4 bath')) {
      baths = 4;
    } else {
      final bathMatch = RegExp(r'\b(\d+)\s*(?:حمامات|حمام|bath)\b', caseSensitive: false).firstMatch(text);
      if (bathMatch != null) {
        baths = int.tryParse(bathMatch.group(1) ?? '0') ?? 0;
      } else {
        final bathPrefixMatch = RegExp(r'(?:حمامات|حمام)\s*[:=]?\s*(\d+)', caseSensitive: false).firstMatch(text);
        if (bathPrefixMatch != null) {
          baths = int.tryParse(bathPrefixMatch.group(1) ?? '0') ?? 0;
        }
      }
    }
    // If text contains حمام or حمامات and baths is still 0, it means at least 1 bathroom was mentioned
    if (baths == 0 && (lower.contains('حمام') || lower.contains('bath'))) {
      baths = 1;
    }

    // 5. Floor Level
    int? floor;
    if (lower.contains('أرضي') || lower.contains('الارضي') || lower.contains('ground')) {
      floor = 0;
    } else if (lower.contains('الأول') || lower.contains('الاول') || lower.contains('طابق اول') || lower.contains('طابق الاول') || lower.contains('1st')) {
      floor = 1;
    } else if (lower.contains('الثاني') || lower.contains('2nd')) {
      floor = 2;
    } else if (lower.contains('الثالث') || lower.contains('3rd')) {
      floor = 3;
    } else if (lower.contains('الرابع') || lower.contains('4th')) {
      floor = 4;
    } else if (lower.contains('الخامس') || lower.contains('5th')) {
      floor = 5;
    } else {
      final floorMatch = RegExp(r'(الدور|طابق|floor)\s*(\d+)', caseSensitive: false).firstMatch(text);
      if (floorMatch != null) {
        floor = int.tryParse(floorMatch.group(2) ?? '');
      }
    }

    // 6. Monthly Rent
    double rent = 0;
    final rentRegex = RegExp(r'(?:[إا]يجار(?:ه|ها|ي|ية)?|سعر|قيمة\s*(?:[إا]يجاري[ةه])?|بـ|مبلغ)\s*(?:شهري[اً]?|هو|هي)?\s*[:=]?\s*(\d+(?:[.,]\d+)?)(?:\s*(ألف|الف|k))?', caseSensitive: false);
    final rm = rentRegex.firstMatch(text);
    if (rm != null) {
      final val = double.tryParse(rm.group(1)?.replaceAll(',', '') ?? '') ?? 0;
      final isThousand = rm.group(2) != null;
      rent = isThousand ? val * 1000 : val;
    } else {
      final currencyRentMatch = RegExp(r'\b(\d{3,7})\s*(?:جنيه|درهم|ج\.م|egp|aed|شهري[اً]?)\b', caseSensitive: false).firstMatch(text);
      if (currencyRentMatch != null) {
        rent = double.tryParse(currencyRentMatch.group(1) ?? '') ?? 0;
      } else {
        final rentThousandMatch = RegExp(r'(\d+)\s*(ألف|الف|k|k\b)', caseSensitive: false).firstMatch(text);
        if (rentThousandMatch != null) {
          final val = double.tryParse(rentThousandMatch.group(1) ?? '') ?? 0;
          rent = val * 1000;
        }
      }
    }
    // Word numbers for rent
    if (rent == 0) {
      if (lower.contains('خمسة آلاف') || lower.contains('خمس الاف') || lower.contains('خمس آلاف') || lower.contains('5 آلاف')) {
        rent = 5000;
      } else if (lower.contains('أربعة آلاف') || lower.contains('أربع الاف') || lower.contains('4 آلاف')) {
        rent = 4000;
      } else if (lower.contains('ثلاثة آلاف') || lower.contains('ثلاث الاف') || lower.contains('3 آلاف')) {
        rent = 3000;
      } else if (lower.contains('عشرة آلاف') || lower.contains('عشر الاف') || lower.contains('10 آلاف')) {
        rent = 10000;
      } else if (lower.contains('عشرين ألف') || lower.contains('عشرين الف') || lower.contains('20 ألف')) {
        rent = 20000;
      } else if (lower.contains('خمسة وعشرين ألف') || lower.contains('25 ألف')) {
        rent = 25000;
      } else if (lower.contains('ثلاثين ألف') || lower.contains('30 ألف')) {
        rent = 30000;
      }
    }
    // Standalone fallback: If rent is still 0, check for any 4-6 digit standalone number that is NOT area
    if (rent == 0) {
      final standaloneNumbers = RegExp(r'\b([1-9]\d{3,5})\b').allMatches(text);
      for (final m in standaloneNumbers) {
        final val = double.tryParse(m.group(1) ?? '') ?? 0;
        if (val > 0 && val != area.toDouble()) {
          rent = val;
          break;
        }
      }
    }

    // 7. Security Deposit
    double? deposit;
    if (lower.contains('تأمين شهرين') || lower.contains('شهرين تأمين') || lower.contains('تامين شهرين')) {
      deposit = rent > 0 ? rent * 2 : null;
    } else if (lower.contains('تأمين شهر') || lower.contains('شهر تأمين') || lower.contains('تامين شهر') || lower.contains('مقدم زائد تامين شهر')) {
      deposit = rent > 0 ? rent : null;
    } else if (lower.contains('بدون تأمين') || lower.contains('بدون تامين')) {
      deposit = 0;
    } else {
      final depositMatch = RegExp(r'ت[أا]مين\s*(\d+)\s*(ألف|الف|k)?', caseSensitive: false).firstMatch(text);
      if (depositMatch != null) {
        final val = double.tryParse(depositMatch.group(1) ?? '') ?? 0;
        final isThousand = depositMatch.group(2) != null;
        deposit = isThousand ? val * 1000 : val;
      }
    }

    // 8. Location: City, District, Street Address, Building/Compound, Unit Number
    String city = '';
    String district = '';
    String? streetAddress;
    String? buildingName;
    String? unitNumber;

    // Extract unit number: e.g. "وحدة 304", "شقة 12", "فيلا 5", "مكتب 201", "رقم الوحدة 304", "شقة رقم 14"
    final unitExplicitMatch = RegExp(
      r'(?:رقم\s*(?:الوحد[ةه]|الشّ?ق[ةه]|الفيلا|المكتب|العقار)|unit\s*(?:no\.?|number)?|apt\s*(?:no\.?|number)?)\s*[:=]?\s*([A-Za-z0-9\-_]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (unitExplicitMatch != null) {
      final candidate = unitExplicitMatch.group(1)?.trim();
      if (candidate != null && !['في', 'من', 'على', 'مع', 'أو', 'و'].contains(candidate)) {
        unitNumber = candidate;
      }
    }

    if (unitNumber == null) {
      final unitDirectMatch = RegExp(
        r'(?:وحد[ةه]|شّ?ق[ةه]|فيلّا?|مكتب)\s+(?:رقم\s*)?([A-Za-z0-9\-_]+)',
        caseSensitive: false,
      ).firstMatch(text);
      if (unitDirectMatch != null) {
        final candidate = unitDirectMatch.group(1)?.trim();
        if (candidate != null && RegExp(r'^\d+[A-Za-z]?$').hasMatch(candidate)) {
          unitNumber = candidate;
        }
      }
    }

    // Extract street address: e.g. "37 شارع الجمرك القديم"
    final fullStreetMatch = RegExp(r'(\d+\s*شارع\s+[^\s،,\n]+(?:\s+[^\s،,\n]+){0,3})', caseSensitive: false).firstMatch(text);
    if (fullStreetMatch != null) {
      var rawStreet = fullStreetMatch.group(1)?.trim() ?? '';
      final boundaryIdx = rawStreet.indexOf(RegExp(r'\s+(?:منطقة|حي|مدينة|محافظة|بجوار|أمام)(?:\s+|$)'));
      if (boundaryIdx != -1) {
        rawStreet = rawStreet.substring(0, boundaryIdx).trim();
      }
      streetAddress = rawStreet;
    } else {
      final streetMatch = RegExp(r'(شارع\s+[^\s،,\n]+(?:\s+[^\s،,\n]+){0,3})', caseSensitive: false).firstMatch(text);
      if (streetMatch != null) {
        var rawStreet = streetMatch.group(1)?.trim() ?? '';
        final boundaryIdx = rawStreet.indexOf(RegExp(r'\s+(?:منطقة|حي|مدينة|محافظة|بجوار|أمام)(?:\s+|$)'));
        if (boundaryIdx != -1) {
          rawStreet = rawStreet.substring(0, boundaryIdx).trim();
        }
        streetAddress = rawStreet;
      }
    }

    // Extract actual building/compound name
    // 1. Explicit label: اسم المبنى / اسم البرج / اسم الكمبوند / اسم العمارة
    final buildingExplicitMatch = RegExp(
      r'(?:اسم\s*)?(?:المبنى|البرج|الكمبوند|المجمع|العمارة|building|tower|compound)\s*[:=]?\s*([^\s،,\n]+(?:\s+[^\s،,\n]+){0,3})',
      caseSensitive: false,
    ).firstMatch(text);

    if (buildingExplicitMatch != null) {
      var bName = buildingExplicitMatch.group(1)?.trim();
      if (bName != null && !bName.startsWith('شارع') && !bName.startsWith('طريق') && !RegExp(r'^\d+\s*شارع').hasMatch(bName)) {
        final boundaryIdx = bName.indexOf(RegExp(r'\s+(?:في|بمنطقة|بحي|الدور|شقة|وحدة|مساحة|ايجار|إيجار)(?:\s+|$)'));
        if (boundaryIdx != -1) {
          bName = bName.substring(0, boundaryIdx).trim();
        }
        if (bName.isNotEmpty && !['هو', 'هي', 'في', 'من'].contains(bName)) {
          buildingName = bName;
        }
      }
    }

    // 2. Direct compound / tower prefix: كمبوند كذا / برج كذا / عمارة كذا / مجمع كذا
    if (buildingName == null) {
      final compoundMatch = RegExp(
        r'(?:كمبوند|مشروع|مجمع|منتجع)\s+([^\s،,\n\d]+(?:\s+[^\s،,\n\d]+){0,2})',
        caseSensitive: false,
      ).firstMatch(text);
      if (compoundMatch != null) {
        var cName = compoundMatch.group(1)?.trim();
        if (cName != null) {
          final bIdx = cName.indexOf(RegExp(r'\s+(?:شارع|طريق|في|بمنطقة|بحي|منطقة|حي|الدور|شقة|وحدة|مساحة|ايجار|إيجار)(?:\s+|$)'));
          if (bIdx != -1) cName = cName.substring(0, bIdx).trim();
          buildingName = 'كمبوند $cName';
        }
      } else {
        final towerMatch = RegExp(
          r'(?:برج|عمارة|مبنى)\s+([^\s،,\n\d]+(?:\s+[^\s،,\n\d]+){0,2})',
          caseSensitive: false,
        ).firstMatch(text);
        if (towerMatch != null) {
          final spaceIdx = text.indexOf(' ', towerMatch.start);
          final prefix = spaceIdx != -1 ? text.substring(towerMatch.start, spaceIdx).trim() : 'برج';
          var name = towerMatch.group(1)?.trim();
          if (name != null) {
            final bIdx = name.indexOf(RegExp(r'\s+(?:شارع|طريق|في|بمنطقة|بحي|منطقة|حي|الدور|شقة|وحدة|مساحة|ايجار|إيجار)(?:\s+|$)'));
            if (bIdx != -1) name = name.substring(0, bIdx).trim();
            if (!['قديم', 'قديمة', 'حديث', 'حديثة', 'جديد', 'جديدة', 'سكني', 'سكنية'].contains(name)) {
              buildingName = '$prefix $name';
            }
          }
        }
      }
    }

    // 3. Known signature compounds / developments
    if (buildingName == null) {
      if (lower.contains('هايد بارك') || lower.contains('hyde park')) {
        buildingName = 'كمبوند هايد بارك';
      } else if (lower.contains('ميفيدا') || lower.contains('mivida')) {
        buildingName = 'كمبوند ميفيدا';
      } else if (lower.contains('مدينتي') || lower.contains('madinaty')) {
        buildingName = 'مدينتي';
      } else if (lower.contains('الرحاب') || lower.contains('rehab')) {
        buildingName = 'مدينة الرحاب';
      } else if (lower.contains('بادية') || lower.contains('badya')) {
        buildingName = 'كمبوند بادية بالم هيلز';
      } else if (lower.contains('بالم هيلز') || lower.contains('palm hills')) {
        buildingName = 'كمبوند بالم هيلز';
      } else if (lower.contains('ماونتن فيو') || lower.contains('mountain view')) {
        buildingName = 'كمبوند ماونتن فيو';
      } else if (lower.contains('تاج سيتي') || lower.contains('taj city')) {
        buildingName = 'كمبوند تاج سيتي';
      } else if (lower.contains('برج خليفة') || lower.contains('burj khalifa')) {
        buildingName = 'برج خليفة';
      }
    }

    // Safety guard: NEVER allow street address to pollute buildingName
    if (buildingName != null) {
      if (buildingName.contains('شارع') || buildingName.contains('طريق') || RegExp(r'^\d+\s*').hasMatch(buildingName)) {
        streetAddress ??= buildingName;
        buildingName = null;
      }
    }

    if (isEgypt || lower.contains('مصر')) {
      if (lower.contains('زراعيين')) {
        city = 'الإسكندرية';
        district = 'الكيلو 21 - الزراعيين';
      } else if (lower.contains('اسكندر') || lower.contains('إسكندر') || lower.contains('عجمي') || lower.contains('alexandria') || lower.contains('بحري')) {
        city = 'الإسكندرية';
        if (lower.contains('بحري') || lower.contains('الجمرك') || lower.contains('الأنفوشي') || lower.contains('رأس التين')) {
          district = 'بحري';
        } else if (lower.contains('المنشية') || lower.contains('العطارين') || lower.contains('محطة الرمل') || lower.contains('كوم الدكة')) {
          district = 'المنشية';
        } else if (lower.contains('محرم بك')) {
          district = 'محرم بك';
        } else if (lower.contains('سيدي جابر') || lower.contains('سبورتنج') || lower.contains('كليوباترا') || lower.contains('الإبراهيمية') || lower.contains('كامب شيزار')) {
          district = 'سيدي جابر';
        } else if (lower.contains('رشدي') || lower.contains('ستانلي') || lower.contains('مصطفى كامل') || lower.contains('بولكلي')) {
          district = 'رشدي';
        } else if (lower.contains('لوران') || lower.contains('جليم') || lower.contains('سان ستيفانو') || lower.contains('ثروت') || lower.contains('زيزينيا') || lower.contains('سابا باشا') || lower.contains('جناكليس')) {
          district = 'لوران';
        } else if (lower.contains('ميامي') || lower.contains('سيدي بشر') || lower.contains('العصافرة') || lower.contains('المندرة') || lower.contains('المعمورة') || lower.contains('أبو قير')) {
          district = 'ميامي';
        } else if (lower.contains('سموحة') || lower.contains('جرين بلازا')) {
          district = 'سموحة';
        } else if (lower.contains('21') || lower.contains('عجمي') || lower.contains('البيطاش') || lower.contains('الهانوفيل') || lower.contains('الدخيلة')) {
          district = 'العجمي - الكيلو 21';
        } else {
          final alexDistrictMatch = RegExp(r'(?:منطقة|حي)\s+(?:اسكندرية\s+)?([^\s،,\n]+(?:\s+[^\s،,\n]+)?)', caseSensitive: false).firstMatch(text);
          if (alexDistrictMatch != null) {
            district = alexDistrictMatch.group(1)?.replaceAll('اسكندرية', '').trim() ?? '';
          }
        }
      } else if (lower.contains('شارع المساحة') || lower.contains('شارع مساحه') || (lower.contains('الدقي') && lower.contains('مساح'))) {
        city = 'الجيزة';
        district = 'الدقي - شارع المساحة';
      } else if (lower.contains('الدقي')) {
        city = 'الجيزة';
        district = 'الدقي';
      } else if (lower.contains('المهندسين')) {
        city = 'الجيزة';
        district = 'المهندسين';
      } else if (lower.contains('الشيخ زايد') || lower.contains('زايد')) {
        city = 'الجيزة';
        district = 'الشيخ زايد';
      } else if (lower.contains('المعادي')) {
        city = 'القاهرة';
        district = 'المعادي';
      } else if (lower.contains('مدينة نصر')) {
        city = 'القاهرة';
        district = 'مدينة نصر';
      } else if (lower.contains('الشروق')) {
        city = 'القاهرة';
        district = 'الشروق';
      } else if (lower.contains('مدينتي')) {
        city = 'القاهرة';
        district = 'مدينتي';
      } else if (lower.contains('أكتوبر') || lower.contains('اكتوبر')) {
        city = 'الجيزة';
        district = '6 أكتوبر';
      } else if (lower.contains('التجمع')) {
        city = 'القاهرة';
        district = 'التجمع الخامس';
      } else if (lower.contains('العاصمة الإدارية')) {
        city = 'القاهرة';
        district = 'العاصمة الإدارية';
      } else if (lower.contains('القاهرة')) {
        city = 'القاهرة';
      } else if (lower.contains('الجيزة')) {
        city = 'الجيزة';
      }

      if (district.isEmpty) {
        final districtMatch = RegExp(r'(?:حي|منطقة)\s+([^\s،,\n]+(?:\s+[^\s،,\n]+)?)', caseSensitive: false).firstMatch(text);
        if (districtMatch != null) {
          district = districtMatch.group(1)?.trim() ?? '';
        }
      }

      if (buildingName == null || buildingName.isEmpty) {
        if (lower.contains('هايد بارك')) {
          buildingName = 'كمبوند هايد بارك';
        } else if (lower.contains('ميفيدا')) {
          buildingName = 'كمبوند ميفيدا';
        }
      }
    } else {
      if (lower.contains('داون تاون') || lower.contains('downtown') || lower.contains('برج خليفة')) {
        city = 'دبي';
        district = 'وسط مدينة دبي';
      } else if (lower.contains('مارينا') || lower.contains('marina')) {
        city = 'دبي';
        district = 'دبي مارينا';
      } else if (lower.contains('الخليج التجاري') || lower.contains('business bay')) {
        city = 'دبي';
        district = 'الخليج التجاري';
      } else if (lower.contains('نخلة جميرا') || lower.contains('palm jumeirah')) {
        city = 'دبي';
        district = 'نخلة جميرا';
      } else if (lower.contains('jvc') || lower.contains('قرية جميرا')) {
        city = 'دبي';
        district = 'قرية جميرا الدائرية';
      } else if (lower.contains('أبوظبي') || lower.contains('سعديات')) {
        city = 'أبوظبي';
        district = 'جزيرة السعديات';
      }
    }

    // 9. Furnishing & Amenities
    final isUnfurnished = lower.contains('بدون فرش') || lower.contains('غير مفروش') || lower.contains('غير مفروشة') || lower.contains('unfurnished');
    final isFurnished = !isUnfurnished && (lower.contains('مفروش') || lower.contains('مفروشة') || lower.contains('furnished'));
    final furnishing = isUnfurnished
        ? FurnishingStatus.unfurnished
        : (isFurnished
            ? (lower.contains('نصف مفروش') || lower.contains('نصف مفروشة') || lower.contains('semi')
                ? FurnishingStatus.semiFurnished
                : FurnishingStatus.fullyFurnished)
            : FurnishingStatus.unfurnished);

    final isNoAc = lower.contains('بدون تكييف') || lower.contains('غير مكيف') || lower.contains('من غير تكييف');
    final hasAc = !isNoAc && (lower.contains('مكيف') || lower.contains('تكييف') || lower.contains('ac'));

    final isNoPark = lower.contains('بدون جراج') || lower.contains('بدون موقف') || lower.contains('بدون باركينج');
    final hasPark = !isNoPark && (lower.contains('موقف') || lower.contains('باركينج') || lower.contains('جراج') || lower.contains('parking'));

    final hasPool = lower.contains('مسبح') || lower.contains('حمام سباحة') || lower.contains('جيم') || lower.contains('pool') || lower.contains('gym');
    final hasBalcony = lower.contains('شرفة') || lower.contains('بلكونة') || lower.contains('إطلالة') || lower.contains('balcony') || lower.contains('view');
    final hasSecurity = lower.contains('أمن') || lower.contains('حراسة') || lower.contains('security');
    final isPet = lower.contains('حيوان') || lower.contains('كلاب') || lower.contains('قطط') || lower.contains('pet');

    final isNegotiable = lower.contains('تفاوض') || lower.contains('قابل للتفاوض') || lower.contains('قابلة للتفاوض') || lower.contains('negotiable');

    // 10. Listing Titles
    final areaPart = area > 0 ? '$area م² ' : '';
    final districtPart = district.isNotEmpty ? 'في $district' : '';
    final cityPart = city.isNotEmpty ? '، $city' : '';
    final buildingPart = (buildingName != null && buildingName.isNotEmpty) ? ' ($buildingName)' : '';

    final titleAr = 'شقة فاخرة $areaPart$districtPart$buildingPart$cityPart بتشطيب سوبر لوكس';
    final titleEn = 'Luxury ${areaPart}Apartment in $district$cityPart';
    final titleHi = '$district में शानदार $areaPartअपार्टमेंट';

    final isBahariGomrok = lower.contains('جمرك') || lower.contains('بحري') || lower.contains('أنفوشي');
    final double fallbackLat = (district.contains('زراعيين') || lower.contains('زراعيين') || district.contains('21'))
        ? 31.0860237
        : isBahariGomrok
            ? 31.2001
            : (city == 'الإسكندرية' ? 31.2156 : 30.0131);
    final double fallbackLng = (district.contains('زراعيين') || lower.contains('زراعيين') || district.contains('21'))
        ? 29.7130387
        : isBahariGomrok
            ? 29.8856
            : (city == 'الإسكندرية' ? 29.9489 : 31.4913);

    return FastPropertyDraft(
      latitude: fallbackLat,
      longitude: fallbackLng,
      city: city,
      district: district,
      streetAddress: streetAddress,
      buildingName: buildingName ?? '',
      unitNumber: unitNumber ?? '',
      photoUrls: [],
      propertyType: propertyType,
      areaSqm: area,
      bedrooms: beds,
      bathrooms: baths,
      floor: floor,
      monthlyRent: rent,
      currency: isEgypt ? 'EGP' : 'AED',
      paymentFrequency: PaymentFrequency.monthly,
      securityDeposit: deposit,
      isBillsIncluded: false,
      isNegotiable: isNegotiable,
      furnishingStatus: furnishing,
      hasParking: hasPark,
      hasCentralAc: hasAc,
      hasPoolGym: hasPool,
      hasSecurity: hasSecurity,
      hasBalconyView: hasBalcony,
      isPetFriendly: isPet,
      titleAr: titleAr,
      titleEn: titleEn,
      titleHi: titleHi,
      countryCode: isEgypt ? 'EG' : 'AE',
    );
  }

  Map<String, String> _generateFallbackDescriptions(FastPropertyDraft draft, PropertyMarketingTone tone) {
    final currency = draft.currency == 'AED' ? 'درهم' : draft.currency == 'USD' ? 'دولار' : 'جنيه';
    final currencyEn = draft.currency;

    final propTypeAr = switch (draft.propertyType.toLowerCase()) {
      'villa' => 'فيلا راقية',
      'studio' => 'استوديو عصري',
      'chalet' => 'شاليه متميز',
      'penthouse' => 'بنتهاوس فاخر',
      'office' => 'مكتب إداري مجهز',
      _ => 'شقة مصممة بعناية فائقة',
    };

    final propTypeEn = switch (draft.propertyType.toLowerCase()) {
      'villa' => 'luxury villa',
      'studio' => 'modern studio',
      'chalet' => 'prime chalet',
      'penthouse' => 'exclusive penthouse',
      'office' => 'commercial office space',
      _ => 'beautifully appointed apartment',
    };

    final propTypeHi = switch (draft.propertyType.toLowerCase()) {
      'villa' => 'शानदार विला',
      'studio' => 'आधुनिक स्टूडियो',
      'chalet' => 'प्रमुख शैले',
      'penthouse' => 'विशेष पेंटहाउस',
      'office' => 'वाणिज्यिक कार्यालय',
      _ => 'सुंदर अपार्टमेंट',
    };

    final furnishingAr = switch (draft.furnishingStatus) {
      FurnishingStatus.fullyFurnished => 'الوحدة مفروشة بالكامل بأثاث ومعدات عصرية.',
      FurnishingStatus.semiFurnished => 'الوحدة نصف مفروشة مع تجهيزات أساسية.',
      FurnishingStatus.unfurnished => 'الوحدة غير مفروشة وجاهزة للانتقال الفوري.',
    };

    final furnishingEn = switch (draft.furnishingStatus) {
      FurnishingStatus.fullyFurnished => 'The unit is fully furnished with premium contemporary furniture.',
      FurnishingStatus.semiFurnished => 'The unit is semi-furnished with essential fittings.',
      FurnishingStatus.unfurnished => 'The unit is unfurnished and ready for immediate handover.',
    };

    final furnishingHi = switch (draft.furnishingStatus) {
      FurnishingStatus.fullyFurnished => 'इकाई प्रीमियम फर्नीचर से पूरी तरह सुसज्जित है।',
      FurnishingStatus.semiFurnished => 'इकाई आवश्यक फिटिंग के साथ अर्ध-सुसज्जित है।',
      FurnishingStatus.unfurnished => 'इकाई बिना फर्नीचर के है और तत्काल रहने के लिए तैयार है।',
    };

    // Dynamic Amenities: strictly include ONLY what is explicitly selected by the user
    final arAmenities = <String>[];
    if (draft.hasParking) arAmenities.add('موقف سيارات خاص');
    if (draft.hasCentralAc) arAmenities.add('تكييف مركزي');
    if (draft.hasPoolGym) arAmenities.add('مسبح ونادٍ رياضي');
    if (draft.hasSecurity) arAmenities.add('أمن وحراسة على مدار 24 ساعة');
    if (draft.hasBalconyView) arAmenities.add('شرفة بإطلالة مفتوحة');
    if (draft.isPetFriendly) arAmenities.add('إمكانية اصطحاب الحيوانات الأليفة');

    final arAmenitiesLine = arAmenities.isNotEmpty
        ? 'تتميز الوحدة بتوفر: ${arAmenities.join('، ')}.'
        : '';

    final enAmenities = <String>[];
    if (draft.hasParking) enAmenities.add('private parking');
    if (draft.hasCentralAc) enAmenities.add('central AC');
    if (draft.hasPoolGym) enAmenities.add('pool & fitness center');
    if (draft.hasSecurity) enAmenities.add('24/7 security');
    if (draft.hasBalconyView) enAmenities.add('balcony with open view');
    if (draft.isPetFriendly) enAmenities.add('pet-friendly policy');

    final enAmenitiesLine = enAmenities.isNotEmpty
        ? 'Features include: ${enAmenities.join(', ')}.'
        : '';

    final hiAmenities = <String>[];
    if (draft.hasParking) hiAmenities.add('निजी पार्किंग');
    if (draft.hasCentralAc) hiAmenities.add('सेंट्रल एसी');
    if (draft.hasPoolGym) hiAmenities.add('स्विमिंग पूल और जिम');
    if (draft.hasSecurity) hiAmenities.add('24/7 सुरक्षा');
    if (draft.hasBalconyView) hiAmenities.add('बालकनी और खुला दृश्य');
    if (draft.isPetFriendly) hiAmenities.add('पालतू जानवरों के अनुकूल');

    final hiAmenitiesLine = hiAmenities.isNotEmpty
        ? 'सुविधाएं: ${hiAmenities.join(', ')} शामिल हैं।'
        : '';

    final locAr = [
      if (draft.district.trim().isNotEmpty) draft.district.trim(),
      if (draft.city.trim().isNotEmpty) draft.city.trim(),
      if (draft.buildingName != null && draft.buildingName!.trim().isNotEmpty) draft.buildingName!.trim(),
    ].join('، ');

    final locEn = [
      if (draft.district.trim().isNotEmpty) draft.district.trim(),
      if (draft.city.trim().isNotEmpty) draft.city.trim(),
      if (draft.buildingName != null && draft.buildingName!.trim().isNotEmpty) draft.buildingName!.trim(),
    ].join(', ');

    if (draft.countryCode == 'EG') {
      return {
        'ar': [
          'فرصة سكنية استثنائية في أرقى مواقع ${locAr.isNotEmpty ? locAr : "المدينة"}.',
          '$propTypeAr بمساحة ${draft.areaSqm} متر مربع، تضم ${draft.bedrooms} غرف نوم واسعة و${draft.bathrooms} حمامات مع تشطيب فاخر سوبر لوكس.',
          furnishingAr,
          if (arAmenitiesLine.isNotEmpty) arAmenitiesLine,
          'القيمة الإيجارية الشهرية: ${draft.monthlyRent.toInt()} $currency شهرياً (${draft.isNegotiable ? "قابلة للتفاوض البسيط" : "سعر نهائي"}). للحجز والمعاينة الفورية يرجى التواصل عبر المنصة.',
        ].join('\n'),
        'en': [
          'Exceptional residential opportunity in ${locEn.isNotEmpty ? locEn : "prime location"}.',
          'This $propTypeEn spans ${draft.areaSqm} sqm, offering ${draft.bedrooms} spacious bedrooms and ${draft.bathrooms} modern bathrooms with premium finishes.',
          furnishingEn,
          if (enAmenitiesLine.isNotEmpty) enAmenitiesLine,
          'Monthly Rent: ${draft.monthlyRent.toInt()} $currencyEn (${draft.isNegotiable ? "Negotiable" : "Fixed"}). Contact now to schedule an exclusive viewing.',
        ].join('\n'),
        'hi': [
          '${locEn.isNotEmpty ? locEn : "प्रमुख स्थान"} में उत्कृष्ट आवासीय अवसर।',
          '${draft.areaSqm} वर्ग मीटर का यह $propTypeHi ${draft.bedrooms} विशाल बेडरूम और ${draft.bathrooms} आधुनिक बाथरूम प्रदान करता है।',
          furnishingHi,
          if (hiAmenitiesLine.isNotEmpty) hiAmenitiesLine,
          'मासिक किराया: ${draft.monthlyRent.toInt()} $currencyEn (${draft.isNegotiable ? "परक्राम्य" : "निश्चित"})। देखने के लिए अभी संपर्क करें।',
        ].join('\n'),
      };
    } else {
      return {
        'ar': [
          'عقار فاخر بإطلالة مميزة في أرقى أحياء ${locAr.isNotEmpty ? locAr : "الإمارة"}.',
          'مساحة رحبة تبلغ ${draft.areaSqm} متر مربع تتضمن ${draft.bedrooms} غرف نوم رئيسية و${draft.bathrooms} حمامات بتشطيبات فندقية عالمية.',
          furnishingAr,
          if (arAmenitiesLine.isNotEmpty) arAmenitiesLine,
          'القيمة الإيجارية: ${draft.monthlyRent.toInt()} $currency شهرياً. احجز موعد المعاينة الآن.',
        ].join('\n'),
        'en': [
          'Stunning luxury residence in the heart of ${locEn.isNotEmpty ? locEn : "prime district"}.',
          'Offering ${draft.areaSqm} sqm of premium living space with ${draft.bedrooms} master bedrooms and ${draft.bathrooms} designer bathrooms.',
          furnishingEn,
          if (enAmenitiesLine.isNotEmpty) enAmenitiesLine,
          'Monthly Rent: ${draft.monthlyRent.toInt()} $currencyEn. Book your private viewing today.',
        ].join('\n'),
        'hi': [
          '${locEn.isNotEmpty ? locEn : "प्रमुख जिले"} में शानदार लक्जरी निवास।',
          '${draft.areaSqm} वर्ग मीटर का प्रीमियम स्थान, जिसमें ${draft.bedrooms} मास्टर बेडरूम और ${draft.bathrooms} डिजाइनर बाथरूम शामिल हैं।',
          furnishingHi,
          if (hiAmenitiesLine.isNotEmpty) hiAmenitiesLine,
          'मासिक किराया: ${draft.monthlyRent.toInt()} $currencyEn। आज ही अपना दौरा बुक करें।',
        ].join('\n'),
      };
    }
  }
}
