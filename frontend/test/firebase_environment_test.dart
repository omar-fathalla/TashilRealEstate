import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/app_firebase_options.dart';
import 'package:tashil_real_estate/firebase_options.dart';
import 'package:tashil_real_estate/firebase_options_dev.dart';

void main() {
  test('builds without FIREBASE_ENV use prod', () {
    expect(AppFirebaseOptions.environment, 'prod');
    expect(AppFirebaseOptions.currentPlatform.projectId, DefaultFirebaseOptions.currentPlatform.projectId);
    expect(DefaultFirebaseOptions.web.projectId, 'tashil-proptech-os');
    expect(DefaultFirebaseOptions.web.appId, '1:534001947779:web:f8c9c5bc18ce69947ff7b6');
  });

  test('FIREBASE_ENV=dev points at tashil-aqar-dev with the dev web app', () {
    final options = DevFirebaseOptions.forPlatform(isWeb: true, webApiKey: 'test-key');
    expect(options.apiKey, 'test-key');
    expect(options.projectId, 'tashil-aqar-dev');
    expect(options.appId, '1:169661829655:web:0251892e514a30e54c4252');
    expect(options.messagingSenderId, '169661829655');
    expect(options.authDomain, 'tashil-aqar-dev.firebaseapp.com');
    expect(options.storageBucket, 'tashil-aqar-dev.firebasestorage.app');
    expect(options.measurementId, isNull);
    expect(
      AppFirebaseOptions.forEnvironment('dev', devOptions: () => options).projectId,
      'tashil-aqar-dev',
    );
  });

  test('a dev build without the web API key fails loudly instead of using prod', () {
    for (final key in ['', '   ']) {
      expect(
        () => DevFirebaseOptions.forPlatform(isWeb: true, webApiKey: key),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('DEV_FIREBASE_WEB_API_KEY'))),
      );
    }
  });

  test('dev is web only; mobile builds do not fall back to prod', () {
    expect(() => DevFirebaseOptions.forPlatform(isWeb: false, webApiKey: 'k'), throwsUnsupportedError);
  });

  test('an unknown FIREBASE_ENV is rejected', () {
    for (final env in ['', 'staging', 'Dev', 'production']) {
      expect(() => AppFirebaseOptions.forEnvironment(env), throwsArgumentError, reason: env);
    }
  });

  test('the dev options never reuse a prod identifier', () {
    final dev = DevFirebaseOptions.forPlatform(isWeb: true, webApiKey: 'k');
    final prod = DefaultFirebaseOptions.web;
    expect(dev.projectId, isNot(prod.projectId));
    expect(dev.appId, isNot(prod.appId));
    expect(dev.messagingSenderId, isNot(prod.messagingSenderId));
    expect(dev.storageBucket, isNot(prod.storageBucket));
    expect(dev.authDomain, isNot(prod.authDomain));
  });
}
