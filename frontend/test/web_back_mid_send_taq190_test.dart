// TAQ-190: on web, browser Back changes the location instead of popping. While a request is being
// sent, the app's routes refuse to be left, so the open sheet stays and shows the outcome.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/routing/navigation_lock.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';
import 'package:tashil_real_estate/features/requests/widgets/request_listing_sheet.dart';

class _HeldBackend implements RequestsBackend {
  final hold = Completer<void>();
  final calls = <String>[];

  @override
  String? get currentUserId => 'u1';
  @override
  bool get isSignedIn => true;
  @override
  Future<String> currentAgencyId() async => '';
  @override
  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) => Stream.value(const []);
  @override
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) => Stream.value(const []);
  @override
  Stream<String> watchLeaseStatus(String leaseId) => Stream.value('');
  @override
  Future<void> sendLeaseOffer(String leaseId) async {}
  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data) async {
    calls.add(function);
    await hold.future;
    return {'success': true};
  }
}

/// What the web engine sends when the browser goes Back to [location].
Future<void> browserBackTo(WidgetTester tester, String location) async {
  final message = SystemChannels.navigation.codec.encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': location, 'state': null}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(SystemChannels.navigation.name, message, (_) {});
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late RoleSession session;
  late _HeldBackend backend;

  setUp(() {
    LocaleController.currentLocale.value = const Locale('en');
    session = RoleSession();
  });
  tearDown(() => session.dispose());

  Future<GoRouter> start(WidgetTester tester) async {
    // Made inside the test's fake-async zone, so completing its hold runs the waiting code.
    backend = _HeldBackend();
    final router = buildAppRouter(
      session: session,
      screenOverride: (route) => switch (route) {
        '/' => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => RequestListingSheet.show(context, listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend)),
                child: const Text('open'),
              ),
            ),
          ),
        '/valuation' => const Text('screen:/valuation'),
        _ => null,
      },
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openAndSend(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Sara Ali');
    await tester.enterText(find.byType(TextField).at(1), '+971500000000');
    await tester.tap(find.text('Send viewing request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('browser Back mid-send keeps the page and the sheet, which then shows the outcome', (tester) async {
    final router = await start(tester);
    await openAndSend(tester);
    expect(backend.calls, ['requestViewing']);
    expect(NavigationLock.held, isTrue);

    await browserBackTo(tester, '/valuation');
    expect(find.byType(RequestListingSheet), findsOneWidget);
    expect(find.text('screen:/valuation'), findsNothing);
    expect(router.state.uri.path, '/');

    backend.hold.complete();
    await tester.pumpAndSettle();
    expect(NavigationLock.held, isFalse);
    expect(find.byType(RequestListingSheet), findsNothing);
    expect(find.textContaining('Your viewing request was sent'), findsOneWidget);
  });

  testWidgets('once the send has finished, browser Back leaves the page again', (tester) async {
    await start(tester);
    await openAndSend(tester);
    backend.hold.complete();
    await tester.pumpAndSettle();

    await browserBackTo(tester, '/valuation');
    await tester.pumpAndSettle();
    expect(find.text('screen:/valuation'), findsOneWidget);
  });

  test('a failed send releases the hold', () async {
    await expectLater(NavigationLock.holdWhile<void>(() async => throw StateError('x')), throwsStateError);
    expect(NavigationLock.held, isFalse);
  });
}
