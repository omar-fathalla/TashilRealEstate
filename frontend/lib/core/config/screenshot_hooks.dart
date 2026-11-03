import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/config/super_admin_security_config.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Query-param hooks compiled only into screenshot builds.
///
/// `--dart-define=SCREENSHOT_HOOKS=true` reads `lang`, `theme`, `q`,
/// `details`, and `legal` from the page URL. Production builds ignore them.
class ScreenshotHooks {
  ScreenshotHooks._();

  static const bool enabled = bool.fromEnvironment(
    'SCREENSHOT_HOOKS',
    defaultValue: false,
  );

  static const String _demoUserPassword = String.fromEnvironment('DEMO_USER_PASSWORD');
  static const String _demoAdminPassword = String.fromEnvironment(
    'SUPER_ADMIN_PASSWORD',
  );

  /// Signs in a seeded emulator account when the URL contains `auth`.
  /// Passwords come from `--dart-define` and are never stored in source.
  static Future<void> signInIfRequested() async {
    if (!enabled) return;
    final who = Uri.base.queryParameters['auth'];
    if (who == null || who.isEmpty) return;
    final email = switch (who) {
      'owner' => 'owner@demo.tashil.test',
      'tenant' => 'tenant@demo.tashil.test',
      'agency' => 'agency@demo.tashil.test',
      'investor' => 'investor@demo.tashil.test',
      'super' => SuperAdminSecurityConfig.defaultEmail,
      _ => '',
    };
    final password = who == 'super' ? _demoAdminPassword : _demoUserPassword;
    if (email.isEmpty || password.isEmpty) return;
    final auth = FirebaseAuth.instance;
    try {
      User? existing;
      final ready = Completer<void>();
      final sub = auth.authStateChanges().listen((user) {
        existing = user;
        if (user != null && !ready.isCompleted) ready.complete();
      });
      await Future.any([
        ready.future,
        Future<void>.delayed(const Duration(milliseconds: 700)),
      ]);
      await sub.cancel();
      if (existing != null && existing!.email?.toLowerCase() == email.toLowerCase()) {
        await UserProfileService().loadProfile();
        return;
      }
      if (existing != null) {
        await auth.signOut();
      }
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await UserProfileService().loadProfile();
    } catch (error) {
      // ignore: avoid_print
      print('Screenshot sign-in failed for $who: $error');
    }
  }

  static void applyFromUri() {
    if (!enabled) return;
    final params = Uri.base.queryParameters;
    final lang = params['lang'];
    if (lang != null && lang.isNotEmpty) {
      LocaleController.setLanguage(lang);
    }
    if (params['theme'] == 'dark') {
      ThemePaletteController.instance.setDarkMode(true);
    }
  }

  static String? get searchQuery {
    if (!enabled) return null;
    final q = Uri.base.queryParameters['q'];
    if (q == null || q.trim().isEmpty) return null;
    return q.trim();
  }

  /// `permit` opens the seeded Dubai listing. `sample` opens a demo listing.
  static String? get details {
    if (!enabled) return null;
    final value = Uri.base.queryParameters['details'];
    if (value == 'permit' || value == 'sample') return value;
    return null;
  }

  /// `valuation`, `district`, or `voice` opens that sheet for screenshots.
  static String? get sheet {
    if (!enabled) return null;
    final value = Uri.base.queryParameters['sheet'];
    switch (value) {
      case 'valuation':
      case 'district':
      case 'voice':
        return value;
      default:
        return null;
    }
  }

  /// `dubai`, `abu_dhabi`, `sharjah`, or `ajman`.
  static String? get legalEmirate {
    if (!enabled) return null;
    final value = Uri.base.queryParameters['legal'];
    switch (value) {
      case 'dubai':
      case 'abu_dhabi':
      case 'sharjah':
      case 'ajman':
        return value;
      default:
        return null;
    }
  }

  static RentInvoiceModel demoLegalInvoice(String emirate) {
    final district = switch (emirate) {
      'abu_dhabi' => 'Al Reem Island, Abu Dhabi',
      'sharjah' => 'Al Majaz, Sharjah',
      'ajman' => 'Ajman Corniche',
      _ => 'Dubai Marina, Dubai',
    };
    final cityCode = switch (emirate) {
      'abu_dhabi' => 'abu_dhabi',
      'sharjah' => 'sharjah',
      'ajman' => 'ajman',
      _ => 'dubai',
    };
    return RentInvoiceModel(
      id: 'shot-legal-$emirate',
      invoiceNumber: 'INV-AE-2026-$emirate',
      contractNumber: 'AE-2026-${switch (cityCode) {
        'abu_dhabi' => 'AUH',
        'sharjah' => 'SHJ',
        'ajman' => 'AJM',
        _ => 'DXB',
      }}-1001',
      countryCode: 'AE',
      unitTitle: 'Waterfront apartment',
      unitNumber: '1001',
      buildingName: 'Marina Gate',
      district: district,
      cityCode: cityCode,
      tenant: const TenantInfo(
        name: 'James Arthur Wilson',
        phone: '+971501234567',
        email: 'james.wilson@demo.tashil.test',
        idNumber: '784-1990-1234567-1',
      ),
      owner: const OwnerPayoutInfo(
        name: 'Abdullah Rashid Al Nuaimi',
        bankName: 'Emirates NBD',
        iban: 'AE070331234567890123456',
        accountNumber: '1234567890',
      ),
      baseAmount: 18000,
      dueDate: DateTime.now().subtract(const Duration(days: 247)),
      gracePeriodDays: 5,
      dailyPenaltyRate: 100,
      status: 'overdue',
      propertyId: 'listing-dubai-permit',
      monthKey: '2026-03',
    );
  }
}
