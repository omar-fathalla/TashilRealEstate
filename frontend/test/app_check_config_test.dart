import 'dart:io';

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

    test('No placeholder site key is left in the source', () {
      final source = File('lib/core/services/app_check_service.dart').readAsStringSync();
      expect(source.contains('placeholder_site_key'), isFalse);
    });
  });
}
