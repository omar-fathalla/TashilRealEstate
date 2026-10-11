import 'package:flutter/material.dart';

class LocaleController {
  static final ValueNotifier<Locale> currentLocale = ValueNotifier<Locale>(const Locale('ar'));

  static bool get isRTL => currentLocale.value.languageCode == 'ar';
  static String get languageCode => currentLocale.value.languageCode;

  static void setLocale(Locale newLocale) {
    if (['ar', 'en', 'hi'].contains(newLocale.languageCode)) {
      currentLocale.value = newLocale;
    }
  }

  static void setLanguage(String langCode) {
    setLocale(Locale(langCode));
  }
}
