import 'package:flutter/material.dart';

class CountryController {
  static final ValueNotifier<String> currentCountry = ValueNotifier<String>('EG'); // 'EG' or 'AE'

  static bool get isEgypt => currentCountry.value == 'EG';
  static bool get isUAE => currentCountry.value == 'AE';
  static String get countryCode => currentCountry.value;

  static void setCountry(String code) {
    if (code == 'EG' || code == 'AE') {
      currentCountry.value = code;
    }
  }

  static String getCurrency(String lang) {
    if (isUAE) {
      if (lang == 'ar') return 'د.إ';
      if (lang == 'hi') return 'AED';
      return 'AED';
    } else {
      if (lang == 'ar') return 'ج.م';
      if (lang == 'hi') return 'EGP';
      return 'EGP';
    }
  }

  static double getMaxRentLimit() {
    return isUAE ? 50000 : 150000;
  }
}
