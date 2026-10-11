import 'package:flutter/foundation.dart';

/// Immutable model representing an accredited commercial or Islamic bank
/// operating in Egypt (CBE) or the United Arab Emirates (CBUAE).
@immutable
class BankModel {
  final String code;
  final String nameAr;
  final String nameEn;
  final String nameHi;
  final String countryCode; // 'EG' or 'AE'
  final bool isOther;

  const BankModel({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.nameHi,
    required this.countryCode,
    this.isOther = false,
  });

  /// Returns the pure localized bank name according to the active language code
  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'hi') return nameHi;
    return nameEn;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankModel &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          countryCode == other.countryCode;

  @override
  int get hashCode => code.hashCode ^ countryCode.hashCode;
}

/// Centralized Directory Service for banks in Egypt (CBE) and the UAE (CBUAE).
class BankDirectoryService {
  /// Code used for custom bank name manual entry
  static const String otherBankCode = 'OTHER';

  // ===========================================================================
  // 🇪🇬 EGYPTIAN BANKS DIRECTORY (Central Bank of Egypt - CBE Accredited)
  // ===========================================================================
  static const List<BankModel> egyptianBanks = [
    BankModel(
      code: 'NBE',
      nameAr: 'البنك الأهلي المصري (NBE)',
      nameEn: 'National Bank of Egypt (NBE)',
      nameHi: 'नेशनल बैंक ऑफ मिस्र (NBE)',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'MISR',
      nameAr: 'بنك مصر',
      nameEn: 'Banque Misr',
      nameHi: 'बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'CIB',
      nameAr: 'البنك التجاري الدولي (CIB)',
      nameEn: 'Commercial International Bank (CIB)',
      nameHi: 'कमर्शियल इंटरनेशनल बैंक (CIB)',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'BDC',
      nameAr: 'بنك القاهرة',
      nameEn: 'Banque du Caire',
      nameHi: 'बैंक डू काहिरा',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ALEX',
      nameAr: 'بنك الإسكندرية',
      nameEn: 'Bank of Alexandria',
      nameHi: 'बैंक ऑफ अलेक्जेंड्रिया',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'QNB',
      nameAr: 'بنك قطر الوطني الأهلي (QNB Alahli)',
      nameEn: 'QNB Alahli',
      nameHi: 'क्यूएनबी अहली बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'AAIB',
      nameAr: 'البنك العربي الإفريقي الدولي (AAIB)',
      nameEn: 'Arab African International Bank (AAIB)',
      nameHi: 'अरब अफ्रीकन इंटरनेशनल बैंक (AAIB)',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'HSBC_EG',
      nameAr: 'بنك إتش إس بي سي مصر (HSBC Egypt)',
      nameEn: 'HSBC Bank Egypt',
      nameHi: 'एचएसबीसी बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'FAISAL',
      nameAr: 'بنك فيصل الإسلامي المصري',
      nameEn: 'Faisal Islamic Bank of Egypt',
      nameHi: 'फैसल इस्लामिक बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ADIB_EG',
      nameAr: 'مصرف أبوظبي الإسلامي - مصر (ADIB)',
      nameEn: 'Abu Dhabi Islamic Bank Egypt (ADIB)',
      nameHi: 'अबू धाबी इस्लामिक बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'HDB',
      nameAr: 'بنك التعمير والإسكان (HDB)',
      nameEn: 'Housing & Development Bank (HDB)',
      nameHi: 'हाउसिंग एंड डेवलपमेंट बैंक (HDB)',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'NBK_EG',
      nameAr: 'بنك الكويت الوطني - مصر (NBK)',
      nameEn: 'National Bank of Kuwait Egypt (NBK)',
      nameHi: 'नेशनल बैंक ऑफ कुवैत मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'SCB_EG',
      nameAr: 'بنك قناة السويس',
      nameEn: 'Suez Canal Bank',
      nameHi: 'स्वेज नहर बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'CA_EG',
      nameAr: 'بنك كريدي أجريكول مصر',
      nameEn: 'Crédit Agricole Egypt',
      nameHi: 'क्रेडिट एग्रीकोल मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ALBARAKA_EG',
      nameAr: 'بنك البركة مصر',
      nameEn: 'Al Baraka Bank Egypt',
      nameHi: 'अल बरका बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'EBANK',
      nameAr: 'البنك المصري لتنمية الصادرات (EBank)',
      nameEn: 'Export Development Bank of Egypt (EBank)',
      nameHi: 'निर्यात विकास बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'UB',
      nameAr: 'المصرف المتحد (The United Bank)',
      nameEn: 'The United Bank of Egypt',
      nameHi: 'द यूनाइटेड बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ADCB_EG',
      nameAr: 'بنك أبوظبي التجاري - مصر (ADCB)',
      nameEn: 'Abu Dhabi Commercial Bank Egypt (ADCB)',
      nameHi: 'अबू धाबी कमर्शियल बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ENBD_EG',
      nameAr: 'بنك الإمارات دبي الوطني - مصر (Emirates NBD)',
      nameEn: 'Emirates NBD Egypt',
      nameHi: 'एमिरेट्स एनबीडी मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'FAB_EG',
      nameAr: 'بنك أبوظبي الأول - مصر (FAB Misr)',
      nameEn: 'First Abu Dhabi Bank Egypt (FAB Misr)',
      nameHi: 'फर्स्ट अबू धाबी बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ABK_EG',
      nameAr: 'البنك الأهلي الكويتي - مصر (ABK)',
      nameEn: 'Al Ahli Bank of Kuwait Egypt (ABK)',
      nameHi: 'अल अहली बैंक ऑफ कुवैत',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'ARAB_EG',
      nameAr: 'البنك العربي - مصر',
      nameEn: 'Arab Bank Egypt',
      nameHi: 'अरब बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'SAIB',
      nameAr: 'بنك الشركة المصرفية العربية الدولية (saib)',
      nameEn: 'Société Arabe Internationale de Banque (saib)',
      nameHi: 'सोसाइटी अरब इंटरनेशनल बैंक (saib)',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'EALB',
      nameAr: 'البنك العقاري المصري العربي',
      nameEn: 'Egyptian Arab Land Bank',
      nameHi: 'इजिप्शियन अरब लैंड बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'AIBANK',
      nameAr: 'بنك الاستثمار العربي (aiBANK)',
      nameEn: 'Arab Investment Bank (aiBANK)',
      nameHi: 'अरब इन्वेस्टमेंट बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'NASSER',
      nameAr: 'بنك ناصر الاجتماعي',
      nameEn: 'Nasser Social Bank',
      nameHi: 'नासर सोशल बैंक',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'MASHREQ_EG',
      nameAr: 'بنك المشرق مصر',
      nameEn: 'Mashreq Bank Egypt',
      nameHi: 'मशरेक बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'EGYPT_POST',
      nameAr: 'الهيئة القومية للبريد (حساب البريد المصري)',
      nameEn: 'Egypt Post Financial Services',
      nameHi: 'मिस्र पोस्ट वित्तीय सेवाएं',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'IDB_EG',
      nameAr: 'بنك التنمية الصناعية (IDB)',
      nameEn: 'Industrial Development Bank (IDB)',
      nameHi: 'औद्योगिक विकास बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: 'SC_EG',
      nameAr: 'بنك ستاندرد تشارترد مصر',
      nameEn: 'Standard Chartered Bank Egypt',
      nameHi: 'स्टैंडर्ड चार्टर्ड बैंक मिस्र',
      countryCode: 'EG',
    ),
    BankModel(
      code: otherBankCode,
      nameAr: 'بنك آخر (كتابة يدوية)...',
      nameEn: 'Other Bank (Custom entry)...',
      nameHi: 'अन्य बैंक (मैन्युअल प्रविष्टि)...',
      countryCode: 'EG',
      isOther: true,
    ),
  ];

  // ===========================================================================
  // 🇦🇪 UAE BANKS DIRECTORY (Central Bank of the UAE - CBUAE Accredited)
  // ===========================================================================
  static const List<BankModel> uaeBanks = [
    BankModel(
      code: 'ENBD',
      nameAr: 'بنك الإمارات دبي الوطني (Emirates NBD)',
      nameEn: 'Emirates NBD',
      nameHi: 'एमिरेट्स एनबीडी',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'FAB',
      nameAr: 'بنك أبوظبي الأول (FAB)',
      nameEn: 'First Abu Dhabi Bank (FAB)',
      nameHi: 'फर्स्ट अबू धाबी बैंक (FAB)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'ADCB',
      nameAr: 'بنك أبوظبي التجاري (ADCB)',
      nameEn: 'Abu Dhabi Commercial Bank (ADCB)',
      nameHi: 'अबू धाबी कमर्शियल बैंक (ADCB)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'DIB',
      nameAr: 'بنك دبي الإسلامي (DIB)',
      nameEn: 'Dubai Islamic Bank (DIB)',
      nameHi: 'दुबई इस्लामिक बैंक (DIB)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'ADIB',
      nameAr: 'مصرف أبوظبي الإسلامي (ADIB)',
      nameEn: 'Abu Dhabi Islamic Bank (ADIB)',
      nameHi: 'अबू धाबी इस्लामिक बैंक (ADIB)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'MASHREQ',
      nameAr: 'بنك المشرق',
      nameEn: 'Mashreq Bank',
      nameHi: 'मशरेक बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'CBD',
      nameAr: 'بنك دبي التجاري (CBD)',
      nameEn: 'Commercial Bank of Dubai (CBD)',
      nameHi: 'कमर्शियल बैंक ऑफ दुबई (CBD)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'SIB',
      nameAr: 'مصرف الشارقة الإسلامي (SIB)',
      nameEn: 'Sharjah Islamic Bank (SIB)',
      nameHi: 'शारजाह इस्लामिक बैंक (SIB)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'RAKBANK',
      nameAr: 'بنك رأس الخيمة الوطني (RAKBANK)',
      nameEn: 'National Bank of Ras Al Khaimah (RAKBANK)',
      nameHi: 'आरएके बैंक (RAKBANK)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'ALHILAL',
      nameAr: 'مصرف الهلال',
      nameEn: 'Al Hilal Bank',
      nameHi: 'अल हिलाल बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'NBF',
      nameAr: 'بنك الفجيرة الوطني (NBF)',
      nameEn: 'National Bank of Fujairah (NBF)',
      nameHi: 'नेशनल बैंक ऑफ फुजैराह (NBF)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'NBQ',
      nameAr: 'بنك أم القيوين الوطني (NBQ)',
      nameEn: 'National Bank of Umm Al Qaiwain (NBQ)',
      nameHi: 'नेशनल बैंक ऑफ उम्म अल क़ुवैन (NBQ)',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'AJMAN',
      nameAr: 'مصرف عجمان',
      nameEn: 'Ajman Bank',
      nameHi: 'अजमान बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'EI',
      nameAr: 'الإمارات الإسلامي',
      nameEn: 'Emirates Islamic',
      nameHi: 'एमिरेट्स इस्लामिक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'WIO',
      nameAr: 'بنك ويو الرقمي (Wio Bank)',
      nameEn: 'Wio Bank',
      nameHi: 'वियो डिजिटल बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'LIV',
      nameAr: 'بنك لِيف الرقمي (Liv. Bank)',
      nameEn: 'Liv. Bank (by Emirates NBD)',
      nameHi: 'लिव डिजिटल बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'ALMARYAH',
      nameAr: 'بنك المارية المحلي',
      nameEn: 'Al Maryah Community Bank',
      nameHi: 'अल मारिया कम्युनिटी बैंक',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'HSBC_UAE',
      nameAr: 'بنك إتش إس بي سي الشرق الأوسط',
      nameEn: 'HSBC Bank Middle East',
      nameHi: 'एचएसबीसी बैंक मिडिल ईस्ट',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'SC_UAE',
      nameAr: 'بنك ستاندرد تشارترد الإمارات',
      nameEn: 'Standard Chartered UAE',
      nameHi: 'स्टैंडर्ड चार्टर्ड यूएई',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'CITI_UAE',
      nameAr: 'سيتي بنك الإمارات',
      nameEn: 'Citibank UAE',
      nameHi: 'सिटीबैंक यूएई',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'ARAB_UAE',
      nameAr: 'البنك العربي - الإمارات',
      nameEn: 'Arab Bank UAE',
      nameHi: 'अरब बैंक यूएई',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'HABIB_UAE',
      nameAr: 'بنك حبيب المحدود - زيورخ',
      nameEn: 'Habib Bank AG Zurich UAE',
      nameHi: 'हबीब बैंक एजी ज्यूरिख यूएई',
      countryCode: 'AE',
    ),
    BankModel(
      code: 'BARCLAYS_UAE',
      nameAr: 'بنك باركليز الإمارات',
      nameEn: 'Barclays Bank UAE',
      nameHi: 'बार्कलेज बैंक यूएई',
      countryCode: 'AE',
    ),
    BankModel(
      code: otherBankCode,
      nameAr: 'بنك آخر (كتابة يدوية)...',
      nameEn: 'Other Bank (Custom entry)...',
      nameHi: 'अन्य बैंक (मैन्युअल प्रविष्टि)...',
      countryCode: 'AE',
      isOther: true,
    ),
  ];

  /// Returns the complete list of banks for the requested country ('EG' or 'AE')
  static List<BankModel> getBanksForCountry(String countryCode) {
    if (countryCode.toUpperCase() == 'AE') {
      return uaeBanks;
    }
    return egyptianBanks;
  }

  /// Locates a bank by code, or by matching Arabic, English, or Hindi name
  static BankModel? findBank(String query, String countryCode) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final list = getBanksForCountry(countryCode);

    // 1. Direct code match
    for (final bank in list) {
      if (bank.code.toLowerCase() == clean) return bank;
    }

    // 2. Exact or substring name match
    for (final bank in list) {
      if (bank.nameAr.toLowerCase() == clean ||
          bank.nameEn.toLowerCase() == clean ||
          bank.nameHi.toLowerCase() == clean) {
        return bank;
      }
    }

    // 3. Relaxed contains match
    for (final bank in list) {
      if (bank.isOther) continue;
      if (bank.nameAr.toLowerCase().contains(clean) ||
          clean.contains(bank.nameAr.toLowerCase()) ||
          bank.nameEn.toLowerCase().contains(clean) ||
          clean.contains(bank.nameEn.toLowerCase())) {
        return bank;
      }
    }

    return null;
  }

  /// Resolves the display name for a bank code or saved string in the given locale
  static String resolveBankName(String bankCodeOrName, String countryCode, String lang) {
    final bank = findBank(bankCodeOrName, countryCode);
    if (bank != null) {
      return bank.localizedName(lang);
    }
    return bankCodeOrName;
  }
}
