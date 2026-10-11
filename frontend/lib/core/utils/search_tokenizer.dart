class SearchTokenizer {
  /// Normalizes Arabic string by standardizing Alef variants, Ta Marbuta, and Yaa
  static String normalizeArabic(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // Remove Harakat/Tashkeel
    return text;
  }

  /// Extracts searchable token keywords from trilingual texts
  static List<String> generateKeywords({
    required String titleAr,
    required String titleEn,
    required String locationAr,
    required String locationEn,
    String? cityCode,
    String? propertyType,
  }) {
    final Set<String> tokens = <String>{};

    void addTokensFromText(String text, bool isArabic) {
      final normalized = isArabic ? normalizeArabic(text) : text.trim().toLowerCase();
      final words = normalized.split(RegExp(r'[\s,.\-_/]+'));
      for (final word in words) {
        if (word.length >= 2) {
          tokens.add(word);
          // Add prefixes (3 chars+) for instant autocomplete
          for (int i = 3; i <= word.length; i++) {
            tokens.add(word.substring(0, i));
          }
        }
      }
    }

    addTokensFromText(titleAr, true);
    addTokensFromText(locationAr, true);
    addTokensFromText(titleEn, false);
    addTokensFromText(locationEn, false);

    if (cityCode != null) tokens.add(cityCode.toLowerCase());
    if (propertyType != null) tokens.add(propertyType.toLowerCase());

    return tokens.toList();
  }

  /// Checks if query matches target text with Arabic normalization
  static bool matches(String target, String query) {
    if (query.isEmpty) return true;
    final normTarget = normalizeArabic(target);
    final normQuery = normalizeArabic(query);
    return normTarget.contains(normQuery);
  }
}
