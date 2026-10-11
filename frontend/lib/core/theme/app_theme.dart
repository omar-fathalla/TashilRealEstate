import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';

/// Official Material Design 3 (M3) Dynamic Theming Engine for Tashil Real Estate.
/// Fully conforms to Google M3 HCT Tonal Palette and Color Roles specification.
class AppTheme {
  /// Generates a complete 26-role M3 Theme derived from a single seed color.
  static ThemeData getTheme({
    Locale? locale,
    Color seedColor = const Color(0xFF0061A4), // Default: Ocean Royal Blue
    Brightness brightness = Brightness.light,
    AppFontTheme? fontTheme,
  }) {
    // 1. Google M3 Material Color Utilities: Generates HCT tonal palettes
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;
    final lang = locale?.languageCode ?? 'ar';
    final activeFont = fontTheme ?? FontThemeController.instance.currentFont.value;
    TextTheme textTheme;

    if (lang == 'ar') {
      textTheme = activeFont.buildTextTheme();
    } else if (lang == 'hi') {
      textTheme = GoogleFonts.notoSansDevanagariTextTheme();
    } else {
      textTheme = GoogleFonts.interTextTheme();
    }

    final appliedTextTheme = textTheme.apply(
      bodyColor: isDark ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      visualDensity: VisualDensity.standard,
      textTheme: appliedTextTheme,

      // M3 Card Container Theme: Crisp contrast between canvas & card
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // M3 Buttons: Derived harmoniously from single seed with strict contrast & primary hover tones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          foregroundColor: colorScheme.primary,
          iconColor: colorScheme.primary,
          overlayColor: colorScheme.primaryHoverStateLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          visualDensity: VisualDensity.standard,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          iconColor: colorScheme.onPrimary,
          // Darken slightly on hover per M3 specs ("اللون الغامق سيكة من اللون الأساسي")
          overlayColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          visualDensity: VisualDensity.standard,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          iconColor: colorScheme.primary,
          overlayColor: colorScheme.primaryHoverStateLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          visualDensity: VisualDensity.standard,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          iconColor: colorScheme.primary,
          overlayColor: colorScheme.primaryHoverStateLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          visualDensity: VisualDensity.standard,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          hoverColor: colorScheme.primaryHoverStateLayer,
          padding: const EdgeInsets.all(8),
          visualDensity: VisualDensity.standard,
        ),
      ),

      // M3 Official SegmentedButton Theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.secondaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSecondaryContainer;
            }
            return colorScheme.onSurfaceVariant;
          }),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6.0,
        backgroundColor: colorScheme.inverseSurface,
        actionTextColor: colorScheme.inversePrimary,
        closeIconColor: colorScheme.onInverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        useIndicator: true,
        indicatorColor: colorScheme.secondaryContainer,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12);
        }),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(locale: const Locale('ar'), brightness: Brightness.light);
  static ThemeData get darkTheme => getTheme(locale: const Locale('ar'), brightness: Brightness.dark);
}
