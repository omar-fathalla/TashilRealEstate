/// UAE display rules: annual rent and square feet.
/// Stored prices remain monthly and stored areas remain square metres.
class MarketDisplay {
  static const double sqmToSqFt = 10.76391041671;

  static bool isUaeCurrency(String currencyCode) => currencyCode == 'AED';

  static bool isUaeCountry(String countryCode) => countryCode == 'AE';

  static double rentAmount({
    required double pricePerMonth,
    required String currencyCode,
  }) {
    if (isUaeCurrency(currencyCode)) return pricePerMonth * 12;
    return pricePerMonth;
  }

  static String rentPeriodKey(String currencyCode) =>
      isUaeCurrency(currencyCode) ? 'perYear' : 'perMonth';

  static String rentLabelKey(String currencyCode) =>
      isUaeCurrency(currencyCode) ? 'annualRentLabel' : 'monthlyRent';

  static double areaAmount({
    required double areaSqM,
    required String countryCode,
  }) {
    if (isUaeCountry(countryCode)) return areaSqM * sqmToSqFt;
    return areaSqM;
  }

  static String areaUnitKey(String countryCode) =>
      isUaeCountry(countryCode) ? 'sqft' : 'sqm';
}
