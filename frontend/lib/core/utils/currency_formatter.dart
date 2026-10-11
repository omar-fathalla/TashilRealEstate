import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats a number with comma separators (e.g. 28000 -> 28,000 or 4,200,000).
  /// Standardizes on Western Arabic numerals (0-9) across Egyptian and UAE PropTech contexts
  /// to eliminate ambiguity where Arabic-Indic zero glyphs ('٠') visually resemble an ellipsis ('...').
  static String formatAmount(num amount, {String langCode = 'ar'}) {
    final formatter = NumberFormat('#,##0', langCode == 'hi' ? 'hi_IN' : 'en_US');
    return formatter.format(amount);
  }

  /// Formats an amount with localized currency symbol (e.g. 28,000 ج.م or 14,500 AED)
  static String formatPriceWithCurrency({
    required num amount,
    required String currencyCode, // 'EGP' or 'AED'
    required String langCode,     // 'ar', 'en', 'hi'
  }) {
    final formattedNum = formatAmount(amount, langCode: langCode);
    final currencySymbol = getCurrencySymbol(currencyCode, langCode);

    if (langCode == 'ar') {
      return '$formattedNum $currencySymbol';
    } else {
      return '$formattedNum $currencySymbol';
    }
  }

  static String getCurrencySymbol(String currencyCode, String langCode) {
    if (currencyCode == 'AED') {
      if (langCode == 'ar') return 'د.إ';
      return 'AED';
    } else {
      if (langCode == 'ar') return 'ج.م';
      return 'EGP';
    }
  }
}
