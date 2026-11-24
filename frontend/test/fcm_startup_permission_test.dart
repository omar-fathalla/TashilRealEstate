import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/fcm_notification_service.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = FcmNotificationService();
  late int promptCalls;
  late int tokenCalls;

  setUp(() {
    service.resetForTest();
    promptCalls = 0;
    tokenCalls = 0;
    service.isSupportedOverride = () async => true;
    service.requestPermissionOverride = () {
      promptCalls++;
      return Completer<AuthorizationStatus>().future;
    };
    service.getTokenOverride = () async {
      tokenCalls++;
      return 'token';
    };
  });

  tearDown(service.resetForTest);

  group('TAQ-68: notification permission is never requested at boot', () {
    test('initialize() returns without asking for permission or a token', () async {
      await service.initialize().timeout(const Duration(seconds: 2));
      expect(promptCalls, 0);
      expect(tokenCalls, 0);
      expect(service.fcmToken, isNull);
      expect(service.enableResultNotifier.value, isNull);
    });

    test('initialize() cannot be held up by a prompt that is never answered', () async {
      var completed = false;
      unawaited(service.initialize().then((_) => completed = true));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(completed, isTrue);
      expect(promptCalls, 0);
    });

    test('initialize() swallows an unsupported or broken messaging stack', () async {
      service.isSupportedOverride = () async => throw StateError('no service worker (private mode)');
      await service.initialize();
      service.resetForTest();
      service.isSupportedOverride = () async => false;
      await service.initialize();
    });

    test('main.dart starts the app before FCM and never asks for permission itself', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, isNot(contains('requestPermission')));
      expect(main, isNot(contains('getToken')));
      expect(main, isNot(contains('await FcmNotificationService')));
      final runApp = main.indexOf('runApp(const TashilRealEstateApp())');
      final fcm = main.indexOf('FcmNotificationService().initialize()');
      expect(runApp, greaterThan(0));
      expect(fcm, greaterThan(runApp), reason: 'FCM setup follows runApp and is not awaited');
      expect(main.substring(0, runApp), isNot(contains('FcmNotificationService')));
    });

    test('the service only prompts inside requestPermissionAndRegister', () {
      final source = File('lib/core/services/fcm_notification_service.dart').readAsStringSync();
      final init = source.substring(source.indexOf('Future<void> initialize()'), source.indexOf('Future<bool> _supported()'));
      expect(init, isNot(contains('requestPermission')));
      expect(init, isNot(contains('getToken')));
    });
  });

  group('TAQ-68: turning notifications on after a tap', () {
    test('granted permission fetches the token', () async {
      service.requestPermissionOverride = () async => AuthorizationStatus.authorized;
      expect(await service.requestPermissionAndRegister(), NotificationEnableResult.granted);
      expect(service.fcmToken, 'token');
      expect(service.enableResultNotifier.value, NotificationEnableResult.granted);
    });

    test('denied permission is a result, not an error, and fetches no token', () async {
      service.requestPermissionOverride = () async => AuthorizationStatus.denied;
      expect(await service.requestPermissionAndRegister(), NotificationEnableResult.denied);
      expect(tokenCalls, 0);
    });

    test('an unsupported browser never prompts', () async {
      service.isSupportedOverride = () async => false;
      expect(await service.requestPermissionAndRegister(), NotificationEnableResult.unsupported);
      expect(promptCalls, 0);
    });

    test('a failing prompt or token is contained', () async {
      service.requestPermissionOverride = () async => throw StateError('boom');
      expect(await service.requestPermissionAndRegister(), NotificationEnableResult.failed);
      service.requestPermissionOverride = () async => AuthorizationStatus.authorized;
      service.getTokenOverride = () async => throw StateError('VAPID missing');
      expect(await service.requestPermissionAndRegister(), NotificationEnableResult.granted);
      expect(service.fcmToken, isNull);
    });

    testWidgets('a prompt that is never answered times out', (tester) async {
      NotificationEnableResult? result;
      unawaited(service.requestPermissionAndRegister().then((value) => result = value));
      await tester.pump(FcmNotificationService.promptTimeout - const Duration(seconds: 1));
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(result, NotificationEnableResult.timedOut);
    });
  });

  group('TAQ-68: the Settings notifications action', () {
    Widget app() => MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: AppSettingsDialog()),
        );

    testWidgets('opening Settings does not prompt; tapping Turn on notifications does', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      LocaleController.setLanguage('en');
      service.requestPermissionOverride = () async {
        promptCalls++;
        return AuthorizationStatus.denied;
      };

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(promptCalls, 0);
      expect(find.text('Notifications'), findsOneWidget);

      final button = find.text('Turn on notifications');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(promptCalls, 1);
      expect(find.textContaining('permission was denied'), findsOneWidget);
    });
  });
}
