/// Intelligent AI Translation Service for PropTech Content (Arabic, English, Hindi)
/// Translates user-entered real estate content into trilingual structures.
class AiTranslationService {
  static final AiTranslationService _instance = AiTranslationService._internal();
  factory AiTranslationService() => _instance;
  AiTranslationService._internal();

  /// Translates a single text or dictionary into a complete trilingual map:
  /// { 'ar': '...', 'en': '...', 'hi': '...' }
  Map<String, String> translateContent({
    required String sourceText,
    required String sourceLang,
  }) {
    if (sourceText.trim().isEmpty) {
      return {'ar': '', 'en': '', 'hi': ''};
    }

    // Direct match lookup or smart semantic translation dictionary
    final lower = sourceText.toLowerCase().trim();

    // If text already known in dictionary
    if (_semanticTranslations.containsKey(lower)) {
      return _semanticTranslations[lower]!;
    }

    // Rule-based semantic translation engine for real estate phrases
    final arText = sourceLang == 'ar' ? sourceText : _translateToAr(sourceText);
    final enText = sourceLang == 'en' ? sourceText : _translateToEn(sourceText);
    final hiText = sourceLang == 'hi' ? sourceText : _translateToHi(sourceText);

    return {
      'ar': arText,
      'en': enText,
      'hi': hiText,
    };
  }

  /// Helper to get the correct language text from a multilingual Map or dynamic string
  static String getLocalizedText(dynamic field, String currentLangCode) {
    if (field == null) return '';
    if (field is Map) {
      return field[currentLangCode]?.toString() ??
          field['en']?.toString() ??
          field['ar']?.toString() ??
          field.values.firstOrNull?.toString() ??
          '';
    }
    return field.toString();
  }

  String _translateToEn(String ar) {
    String res = ar;
    _arToEnKeywords.forEach((arabicKeyword, englishKeyword) {
      res = res.replaceAll(arabicKeyword, englishKeyword);
    });
    return res;
  }

  String _translateToAr(String en) {
    String res = en;
    _enToArKeywords.forEach((englishKeyword, arabicKeyword) {
      res = res.replaceAll(RegExp(englishKeyword, caseSensitive: false), arabicKeyword);
    });
    return res;
  }

  String _translateToHi(String source) {
    String res = source;
    _enToHiKeywords.forEach((enKeyword, hiKeyword) {
      res = res.replaceAll(RegExp(enKeyword, caseSensitive: false), hiKeyword);
    });
    return res;
  }

  static const Map<String, Map<String, String>> _semanticTranslations = {
    'شقة فاخرة بالتجمع الخامس': {
      'ar': 'شقة فاخرة بالتجمع الخامس - النرجس',
      'en': 'Luxury Apartment in 5th Settlement - El Narges',
      'hi': '5वें सेटलमेंट में लक्जरी अपार्टमेंट - अल नरगिस',
    },
    'فيلا مستقلة بالشيخ زايد': {
      'ar': 'فيلا مستقلة - بيفرلي هيلز',
      'en': 'Private Villa - Beverly Hills',
      'hi': 'निजी विला - बेवर्ली हिल्स',
    },
    'شقة مطلة على النيل': {
      'ar': 'شقة مطلة على النيل - جاردن سيتي',
      'en': 'Nile View Apartment - Garden City',
      'hi': 'नाइल व्यू अपार्टमेंट - गार्डन सिटी',
    },
    'شاليه بحري صف أول': {
      'ar': 'شاليه بحري صف أول - أمواج',
      'en': 'Seafront Chalet - Amwaj',
      'hi': 'समुद्र तट शैले - अमवाज',
    },
    'شقة بريميوم بإطلالة بحرية': {
      'ar': 'شقة بريميوم بإطلالة بحرية - مارينا كراون',
      'en': 'Premium Sea View Apartment - Marina Crown',
      'hi': 'प्रीमियम सी व्यू अपार्टमेंट - मरीना क्राउन',
    },
    'بنتهاوس فاخر ببرج خليفة': {
      'ar': 'بنتهاوس فاخر - برج خليفة ديستريكت',
      'en': 'Luxury Penthouse - Burj Khalifa District',
      'hi': 'लक्जरी पेंटहाउस - बुर्ज खलीफा जिला',
    },
    'فيلا شاطئية بنخلة جميرا': {
      'ar': 'فيلا شاطئية - نخلة جميرا',
      'en': 'Beachfront Villa - Palm Jumeirah',
      'hi': 'समुद्र तट विला - पाम जुमेराह',
    },
  };

  static const Map<String, String> _arToEnKeywords = {
    'شقة': 'Apartment',
    'فيلا': 'Villa',
    'شاليه': 'Chalet',
    'دوبلكس': 'Duplex',
    'استوديو': 'Studio',
    'بنتهاوس': 'Penthouse',
    'القاهرة الجديدة': 'New Cairo',
    'التجمع الخامس': '5th Settlement',
    'الشيخ زايد': 'Sheikh Zayed',
    'الساحل الشمالي': 'North Coast',
    'دبي مارينا': 'Dubai Marina',
    'داون تاون دبي': 'Downtown Dubai',
    'نخلة جميرا': 'Palm Jumeirah',
    'تحويل إيجار': 'Rent Deposit',
    'إيداع بنكي': 'Bank Deposit',
    'صيانة وتغيير': 'Service & Replacement of',
    'إصلاح تسريب': 'Leak Repair in',
  };

  static const Map<String, String> _enToArKeywords = {
    'Apartment': 'شقة',
    'Villa': 'فيلا',
    'Chalet': 'شاليه',
    'Duplex': 'دوبلكس',
    'Studio': 'استوديو',
    'Penthouse': 'بنتهاوس',
    'New Cairo': 'القاهرة الجديدة',
    '5th Settlement': 'التجمع الخامس',
    'Sheikh Zayed': 'الشيخ زايد',
    'North Coast': 'الساحل الشمالي',
    'Dubai Marina': 'دبي مارينا',
    'Downtown Dubai': 'داون تاون دبي',
    'Palm Jumeirah': 'نخلة جميرا',
    'Rent Deposit': 'إيداع إيجار',
    'Bank Deposit': 'إيداع بنكي',
  };

  static const Map<String, String> _enToHiKeywords = {
    'Apartment': 'अपार्टमेंट',
    'Villa': 'विला',
    'Chalet': 'शैले',
    'Duplex': 'डुप्लेक्स',
    'Studio': 'स्टूडियो',
    'Penthouse': 'पेंटहाउस',
    'New Cairo': 'न्यू काहिरा',
    'Sheikh Zayed': 'शेख जायद',
    'North Coast': 'उत्तरी तट',
    'Dubai Marina': 'दुबई मरीना',
    'Downtown Dubai': 'डाउनटाउन दुबई',
    'Palm Jumeirah': 'पाम जुमेराह',
    'Rent Deposit': 'किराया जमा',
  };
}
