import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/app_check_service.dart';

void main() {
  group('App Check configuration', () {
    test('The web reCAPTCHA site key comes from a dart-define and defaults to empty', () {
      expect(AppCheckService.webSiteKey, isEmpty);
    });

    test('Release web builds only activate App Check with a site key', () {
      expect(AppCheckService.shouldActivateOnWeb(debug: false, siteKey: ''), isFalse);
      expect(AppCheckService.shouldActivateOnWeb(debug: false, siteKey: '   '), isFalse);
      expect(AppCheckService.shouldActivateOnWeb(debug: false, siteKey: '6LcRealKey'), isTrue);
      expect(AppCheckService.shouldActivateOnWeb(debug: true, siteKey: ''), isTrue);
    });

    test('Release web uses reCAPTCHA Enterprise with the trimmed key; debug uses the debug provider', () {
      final release = AppCheckService.webProvider(debug: false, siteKey: ' 6LcRealKey ');
      expect(release, isA<ReCaptchaEnterpriseProvider>());
      expect((release as ReCaptchaEnterpriseProvider).siteKey, '6LcRealKey');
      expect(AppCheckService.webProvider(debug: true, siteKey: ''), isA<WebDebugProvider>());
    });

    test('Release mobile uses Play Integrity and App Attest with DeviceCheck fallback', () {
      expect(AppCheckService.androidProvider(debug: false), isA<AndroidPlayIntegrityProvider>());
      expect(AppCheckService.androidProvider(debug: true), isA<AndroidDebugProvider>());
      expect(
        AppCheckService.appleProvider(debug: false),
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
      expect(AppCheckService.appleProvider(debug: true), isA<AppleDebugProvider>());
    });

    test('The v3 provider is no longer used', () {
      final source = File('lib/core/services/app_check_service.dart').readAsStringSync();
      expect(source.contains('ReCaptchaV3Provider'), isFalse);
    });

    test('iOS entitlements set App Attest: production for release, development for debug', () {
      String environmentIn(String file) {
        final plist = File('ios/Runner/$file').readAsStringSync();
        final match = RegExp(
          r'com\.apple\.developer\.devicecheck\.appattest-environment</key>\s*<string>(\w+)</string>',
        ).firstMatch(plist);
        return match!.group(1)!;
      }

      expect(environmentIn('Runner.entitlements'), 'production');
      expect(environmentIn('RunnerDebug.entitlements'), 'development');

      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(RegExp(r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;').allMatches(project).length, 2);
      expect(RegExp(r'CODE_SIGN_ENTITLEMENTS = Runner/RunnerDebug\.entitlements;').allMatches(project).length, 1);
    });

    test('No placeholder site key is left in the source', () {
      final source = File('lib/core/services/app_check_service.dart').readAsStringSync();
      expect(source.contains('placeholder_site_key'), isFalse);
    });
  });
}
