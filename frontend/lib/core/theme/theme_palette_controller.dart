import 'package:flutter/material.dart';
export 'package:tashil_real_estate/core/widgets/theme_palette_switcher.dart';

/// The 5 Official Curated Seed Palettes based on Google Material Design 3 Color System.
enum M3ThemePalette {
  /// Forest / Olive Green (#2E6B48) - Growth, Nature, Real Estate Prestige
  forestGreen(
    nameAr: 'الزيتي الفاخر',
    nameEn: 'Forest Olive',
    nameHi: 'फॉरेस्ट ऑलिव',
    color: Color(0xFF2E6B48),
  ),

  /// Warm Terracotta (#8F4C38) - Architectural Masonry & Warm Earth
  warmTerracotta(
    nameAr: 'الترابي الدافئ',
    nameEn: 'Terracotta',
    nameHi: 'टेराकोटा',
    color: Color(0xFF8F4C38),
  ),

  /// Ocean Royal Blue (#0061A4) - Institutional Confidence & Enterprise SaaS
  oceanBlue(
    nameAr: 'الأزرق الملكي',
    nameEn: 'Ocean Blue',
    nameHi: 'रॉयल ब्लू',
    color: Color(0xFF0061A4),
  ),

  /// Slate Navy (#0F172A) - Flagship Deep Architectural Tone
  slateNavy(
    nameAr: 'الكحلي الإردوازي',
    nameEn: 'Slate Navy',
    nameHi: 'स्लेट नेवी',
    color: Color(0xFF0F172A),
  ),

  /// Emerald Teal (#006874) - Modern PropTech Intelligence & Clean Serenity
  emeraldTeal(
    nameAr: 'الزمردي التيل',
    nameEn: 'Emerald Teal',
    nameHi: 'एमराल्ड टील',
    color: Color(0xFF006874),
  );

  final String nameAr;
  final String nameEn;
  final String nameHi;
  final Color color;

  const M3ThemePalette({
    required this.nameAr,
    required this.nameEn,
    required this.nameHi,
    required this.color,
  });

  String getLocalizedName(String langCode) {
    if (langCode == 'en') return nameEn;
    if (langCode == 'hi') return nameHi;
    return nameAr;
  }
}

/// Central Reactive Controller for M3 Dynamic Color Schemes & Light/Dark Modes.
class ThemePaletteController {
  ThemePaletteController._();
  static final ThemePaletteController instance = ThemePaletteController._();

  /// Default active seed palette: Ocean Royal Blue
  final ValueNotifier<M3ThemePalette> currentPalette =
      ValueNotifier<M3ThemePalette>(M3ThemePalette.oceanBlue);

  /// Dark mode state: default is Light mode (false)
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  /// Changes the active seed palette across the entire application
  void setPalette(M3ThemePalette palette) {
    if (currentPalette.value != palette) {
      currentPalette.value = palette;
    }
  }

  /// Toggles between Light and Dark mode
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
  }

  /// Explicitly sets Dark or Light mode
  void setDarkMode(bool enabled) {
    if (isDarkMode.value != enabled) {
      isDarkMode.value = enabled;
    }
  }

  Color get activeSeedColor => currentPalette.value.color;
  bool get isDark => isDarkMode.value;
}

/// Official Google Material Design 3 Dynamic Hover & State Layer Color Derivation Extension.
/// Automatically derives all hover states, darkened tones, borders, and shadows
/// directly from the active theme's primary seed color (e.g. Warm Terracotta brown #8F4C38,
/// Forest Olive green #2E6B48, Ocean Blue #0061A4, Slate Navy #0F172A, Emerald Teal #006874).
extension M3HoverColorScheme on ColorScheme {
  /// A slightly darker tone derived directly from the primary seed color for hover states
  /// on filled buttons and active pill segments ("اللون الغامق سيكة ده أو غامق شوية من اللون الأساسي").
  /// In Light Mode: ~10% darker by blending with black.
  /// In Dark Mode: ~12% lighter by blending with white.
  Color get primaryDarkenedHover => brightness == Brightness.dark
      ? (Color.lerp(primary, Colors.white, 0.12) ?? primary)
      : (Color.lerp(primary, Colors.black, 0.10) ?? primary);

  /// Subtle primary-derived hover state layer overlay for cards, containers, and unselected buttons.
  Color get primaryHoverStateLayer => primary.withValues(
        alpha: brightness == Brightness.dark ? 0.10 : 0.06,
      );

  /// Primary-derived outline border for hovered cards, buttons, and chips.
  Color get primaryHoverBorder => primary.withValues(
        alpha: brightness == Brightness.dark ? 0.55 : 0.45,
      );

  /// Primary-derived shadow color for hovered elevated containers.
  Color get primaryHoverShadow => primary.withValues(
        alpha: brightness == Brightness.dark ? 0.30 : 0.12,
      );
}

