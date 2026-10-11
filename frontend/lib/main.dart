import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';
import 'package:tashil_real_estate/firebase_options.dart';

/// Global M3 ScrollBehavior for Tashil Real Estate.
/// Enables smooth dragging with mouse, touch, and stylus across all platforms and web,
/// while excluding trackpad from drag-emulation to prevent gesture conflicts with native wheel events.
class TashilAppScrollBehavior extends MaterialScrollBehavior {
  const TashilAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known upstream Flutter Web engine assertion for trackpad wheel events:
  // "Assertion failed: ... !identical(kind, PointerDeviceKind.trackpad)"
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    if (exceptionStr.contains('PointerDeviceKind.trackpad') ||
        (details.library == 'gestures library' && exceptionStr.contains('identical(kind, PointerDeviceKind.trackpad)'))) {
      // Benign Flutter Web engine trackpad event discrepancy; ignore and suppress console noise.
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('PointerDeviceKind.trackpad')) {
      return true; // handled
    }
    return false;
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TashilRealEstateApp());
}

class TashilRealEstateApp extends StatelessWidget {
  const TashilRealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, child) {
        return ValueListenableBuilder<M3ThemePalette>(
          valueListenable: ThemePaletteController.instance.currentPalette,
          builder: (context, activePalette, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: ThemePaletteController.instance.isDarkMode,
              builder: (context, isDark, _) {
                return ValueListenableBuilder<AppFontTheme>(
                  valueListenable: FontThemeController.instance.currentFont,
                  builder: (context, activeFont, _) {
                    return MaterialApp.router(
                      title: 'Tashil Real Estate',
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.getTheme(
                        locale: currentLocale,
                        seedColor: activePalette.color,
                        brightness: Brightness.light,
                        fontTheme: activeFont,
                      ),
                      darkTheme: AppTheme.getTheme(
                        locale: currentLocale,
                        seedColor: activePalette.color,
                        brightness: Brightness.dark,
                        fontTheme: activeFont,
                      ),
                      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                      scrollBehavior: const TashilAppScrollBehavior(),
                      routerConfig: appRouter,
                      locale: currentLocale,
                      supportedLocales: const [
                        Locale('ar'),
                        Locale('en'),
                        Locale('hi'),
                      ],
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

