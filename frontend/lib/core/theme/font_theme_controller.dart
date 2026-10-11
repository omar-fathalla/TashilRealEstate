import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Categories of Arabic Google Fonts for PropTech UI & Design System.
enum FontCategory {
  modern,
  headlines,
  classic,
}

/// The 12 Official Google Fonts supported by Tashil Real Estate.
enum AppFontTheme {
  // --- Modern & Contemporary (حديثة وعصرية) ---
  cairo(
    id: 'cairo',
    nameAr: 'Cairo (القاهرة - الافتراضي)',
    nameEn: 'Cairo (Default)',
    nameHi: 'काहिरा (Cairo)',
    category: FontCategory.modern,
    descriptionKey: 'fontCairoDesc',
  ),
  tajawal(
    id: 'tajawal',
    nameAr: 'Tajawal (تجول)',
    nameEn: 'Tajawal',
    nameHi: 'तजावल (Tajawal)',
    category: FontCategory.modern,
    descriptionKey: 'fontTajawalDesc',
  ),
  readexPro(
    id: 'readex_pro',
    nameAr: 'Readex Pro (ريدكس برو)',
    nameEn: 'Readex Pro',
    nameHi: 'रीडेक्स प्रो (Readex Pro)',
    category: FontCategory.modern,
    descriptionKey: 'fontReadexProDesc',
  ),
  elMessiri(
    id: 'el_messiri',
    nameAr: 'El Messiri (المسيري)',
    nameEn: 'El Messiri',
    nameHi: 'अल मेसिरी (El Messiri)',
    category: FontCategory.modern,
    descriptionKey: 'fontElMessiriDesc',
  ),
  ibmPlexSansArabic(
    id: 'ibm_plex_sans_arabic',
    nameAr: 'IBM Plex Sans Arabic (آي بي إم بلكس)',
    nameEn: 'IBM Plex Sans Arabic',
    nameHi: 'आईबीएम प्लेक्स (IBM Plex Sans)',
    category: FontCategory.modern,
    descriptionKey: 'fontIbmPlexSansArabicDesc',
  ),

  // --- Bold / Headlines & Logos (عناوين عريضة وشعارات) ---
  changa(
    id: 'changa',
    nameAr: 'Changa (تشانغا)',
    nameEn: 'Changa',
    nameHi: 'चांगा (Changa)',
    category: FontCategory.headlines,
    descriptionKey: 'fontChangaDesc',
  ),
  lemonada(
    id: 'lemonada',
    nameAr: 'Lemonada (ليمونادا)',
    nameEn: 'Lemonada',
    nameHi: 'लेमोनाड़ा (Lemonada)',
    category: FontCategory.headlines,
    descriptionKey: 'fontLemonadaDesc',
  ),
  reemKufi(
    id: 'reem_kufi',
    nameAr: 'Reem Kufi (ريم كوفي)',
    nameEn: 'Reem Kufi',
    nameHi: 'रीम कूफ़ी (Reem Kufi)',
    category: FontCategory.headlines,
    descriptionKey: 'fontReemKufiDesc',
  ),
  kufam(
    id: 'kufam',
    nameAr: 'Kufam (كوفام)',
    nameEn: 'Kufam',
    nameHi: 'कूफ़ाम (Kufam)',
    category: FontCategory.headlines,
    descriptionKey: 'fontKufamDesc',
  ),

  // --- Classic & Long Text (كلاسيكية ونصوص طويلة) ---
  notoNaskhArabic(
    id: 'noto_naskh_arabic',
    nameAr: 'Noto Naskh Arabic (نوتو نسخ)',
    nameEn: 'Noto Naskh Arabic',
    nameHi: 'नोटो नस्ख (Noto Naskh Arabic)',
    category: FontCategory.classic,
    descriptionKey: 'fontNotoNaskhArabicDesc',
  ),
  scheherazadeNew(
    id: 'scheherazade_new',
    nameAr: 'Scheherazade New (شهرزاد)',
    nameEn: 'Scheherazade New',
    nameHi: 'शहज़ाद न्यू (Scheherazade New)',
    category: FontCategory.classic,
    descriptionKey: 'fontScheherazadeNewDesc',
  ),
  lateef(
    id: 'lateef',
    nameAr: 'Lateef (لطيف)',
    nameEn: 'Lateef',
    nameHi: 'लतीफ़ (Lateef)',
    category: FontCategory.classic,
    descriptionKey: 'fontLateefDesc',
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final String nameHi;
  final FontCategory category;
  final String descriptionKey;

  const AppFontTheme({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.descriptionKey,
  });

  String getLocalizedName(String langCode) {
    if (langCode == 'en') return nameEn;
    if (langCode == 'hi') return nameHi;
    return nameAr;
  }

  /// Builds a complete Material TextTheme for this font family.
  TextTheme buildTextTheme([TextTheme? base]) {
    switch (this) {
      case AppFontTheme.cairo:
        return GoogleFonts.cairoTextTheme(base);
      case AppFontTheme.tajawal:
        return GoogleFonts.tajawalTextTheme(base);
      case AppFontTheme.readexPro:
        return GoogleFonts.readexProTextTheme(base);
      case AppFontTheme.elMessiri:
        return GoogleFonts.elMessiriTextTheme(base);
      case AppFontTheme.ibmPlexSansArabic:
        return GoogleFonts.ibmPlexSansArabicTextTheme(base);
      case AppFontTheme.changa:
        return GoogleFonts.changaTextTheme(base);
      case AppFontTheme.lemonada:
        return GoogleFonts.lemonadaTextTheme(base);
      case AppFontTheme.reemKufi:
        return GoogleFonts.reemKufiTextTheme(base);
      case AppFontTheme.kufam:
        return GoogleFonts.kufamTextTheme(base);
      case AppFontTheme.notoNaskhArabic:
        return GoogleFonts.notoNaskhArabicTextTheme(base);
      case AppFontTheme.scheherazadeNew:
        return GoogleFonts.scheherazadeNewTextTheme(base);
      case AppFontTheme.lateef:
        return GoogleFonts.lateefTextTheme(base);
    }
  }

  /// Returns a specific TextStyle for live preview rendering in the UI.
  TextStyle getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
  }) {
    switch (this) {
      case AppFontTheme.cairo:
        return GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.tajawal:
        return GoogleFonts.tajawal(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.readexPro:
        return GoogleFonts.readexPro(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.elMessiri:
        return GoogleFonts.elMessiri(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.ibmPlexSansArabic:
        return GoogleFonts.ibmPlexSansArabic(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.changa:
        return GoogleFonts.changa(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.lemonada:
        return GoogleFonts.lemonada(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.reemKufi:
        return GoogleFonts.reemKufi(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.kufam:
        return GoogleFonts.kufam(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.notoNaskhArabic:
        return GoogleFonts.notoNaskhArabic(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.scheherazadeNew:
        return GoogleFonts.scheherazadeNew(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
      case AppFontTheme.lateef:
        return GoogleFonts.lateef(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontStyle: fontStyle,
        );
    }
  }
}

/// Central Reactive Controller for dynamic Font Theming across Tashil Real Estate.
class FontThemeController {
  FontThemeController._();
  static final FontThemeController instance = FontThemeController._();

  /// Default active font: Cairo
  final ValueNotifier<AppFontTheme> currentFont =
      ValueNotifier<AppFontTheme>(AppFontTheme.cairo);

  /// Changes the active font theme across the entire application instantly
  void setFont(AppFontTheme font) {
    if (currentFont.value != font) {
      currentFont.value = font;
    }
  }

  AppFontTheme get activeFont => currentFont.value;
}
