import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppFontTheme & FontThemeController Tests', () {
    test('All 12 Google Fonts exist with complete metadata', () {
      expect(AppFontTheme.values.length, equals(12));

      for (final font in AppFontTheme.values) {
        expect(font.id, isNotEmpty);
        expect(font.nameAr, isNotEmpty);
        expect(font.nameEn, isNotEmpty);
        expect(font.nameHi, isNotEmpty);
        expect(font.descriptionKey, isNotEmpty);
        expect(font.category, isIn([
          FontCategory.modern,
          FontCategory.headlines,
          FontCategory.classic,
        ]));
      }
    });

    test('Font categorization matches specification', () {
      final modern = AppFontTheme.values.where((f) => f.category == FontCategory.modern).toList();
      final headlines = AppFontTheme.values.where((f) => f.category == FontCategory.headlines).toList();
      final classic = AppFontTheme.values.where((f) => f.category == FontCategory.classic).toList();

      expect(modern.length, equals(5)); // Cairo, Tajawal, Readex Pro, El Messiri, IBM Plex Sans
      expect(headlines.length, equals(4)); // Changa, Lemonada, Reem Kufi, Kufam
      expect(classic.length, equals(3)); // Noto Naskh Arabic, Scheherazade New, Lateef
    });

    test('Each font produces valid TextTheme and TextStyle', () {
      for (final font in AppFontTheme.values) {
        final textTheme = font.buildTextTheme();
        expect(textTheme, isNotNull);
        expect(textTheme.bodyMedium, isNotNull);

        final textStyle = font.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold);
        expect(textStyle, isNotNull);
        expect(textStyle.fontSize, equals(16));
        expect(textStyle.fontWeight, equals(FontWeight.bold));
      }
    });

    test('FontThemeController updates active font reactively', () {
      final controller = FontThemeController.instance;
      expect(controller.currentFont.value, equals(AppFontTheme.cairo));

      controller.setFont(AppFontTheme.tajawal);
      expect(controller.currentFont.value, equals(AppFontTheme.tajawal));
      expect(controller.activeFont, equals(AppFontTheme.tajawal));

      controller.setFont(AppFontTheme.readexPro);
      expect(controller.currentFont.value, equals(AppFontTheme.readexPro));

      // Reset back to Cairo
      controller.setFont(AppFontTheme.cairo);
      expect(controller.currentFont.value, equals(AppFontTheme.cairo));
    });
  });
}
