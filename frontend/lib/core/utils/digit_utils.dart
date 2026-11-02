import 'package:flutter/services.dart';

/// Central utility for normalizing numerals across all languages in Tashil Real Estate.
/// Mandates standard Western Arabic digits (0-9) to ensure unambiguous, error-free
/// display and processing of phone numbers, national IDs, bank accounts, prices, and metrics.
class DigitUtils {
  // Eastern Arabic numerals (U+0660 to U+0669)
  static const String _easternArabic = '٠١٢٣٤٥٦٧٨٩';
  // Persian / Extended Arabic-Indic numerals (U+06F0 to U+06F9)
  static const String _persianUrdu = '۰۱۲۳۴۵۶۷۸۹';
  // Standard Western digits (0 to 9)
  static const String _western = '0123456789';

  /// Converts all Eastern Arabic and Persian/Urdu numerals to Western English digits (0-9).
  /// Safe for mixed text (e.g. '37 شارع الجمرك' or '٢١١٥٠٠١٣٨٠٤١٦٧٠١٠١').
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';
    var output = input;

    // Fast-path: check if input contains any Arabic-Indic characters
    bool hasArabicDigits = false;
    for (int i = 0; i < output.length; i++) {
      final code = output.codeUnitAt(i);
      // U+0660 - U+0669 (Eastern Arabic) or U+06F0 - U+06F9 (Persian/Urdu)
      if ((code >= 0x0660 && code <= 0x0669) || (code >= 0x06F0 && code <= 0x06F9)) {
        hasArabicDigits = true;
        break;
      }
    }

    if (!hasArabicDigits) return output;

    for (int i = 0; i < 10; i++) {
      output = output.replaceAll(_easternArabic[i], _western[i]);
      output = output.replaceAll(_persianUrdu[i], _western[i]);
    }

    return output;
  }

  /// Converts all Arabic and Persian digits, returning null if the input was null.
  static String? normalizeNullable(String? input) {
    if (input == null) return null;
    return normalize(input);
  }

  /// Normalizes and parses as int safely
  static int? tryParseInt(String? input) {
    if (input == null) return null;
    final normalized = normalize(input).trim();
    return int.tryParse(normalized);
  }

  /// Normalizes and parses as double safely (also normalizes Arabic decimal separator '٫')
  static double? tryParseDouble(String? input) {
    if (input == null) return null;
    var normalized = normalize(input).trim().replaceAll('٫', '.').replaceAll('٬', ',');
    // Remove formatting commas for double parsing
    normalized = normalized.replaceAll(',', '');
    return double.tryParse(normalized);
  }
}

/// A [TextInputFormatter] that automatically converts Eastern Arabic (٠-٩)
/// and Persian (۰-۹) digits into standard Western English digits (0-9)
/// in real time as the user types or pastes text.
class ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  const ArabicToEnglishDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = DigitUtils.normalize(newValue.text);
    if (normalized == newValue.text) {
      return newValue;
    }

    // Since each Arabic-Indic character is 1 code unit in UTF-16 and maps to
    // an ASCII digit which is also 1 code unit, selection offsets are preserved identically.
    return newValue.copyWith(
      text: normalized,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
