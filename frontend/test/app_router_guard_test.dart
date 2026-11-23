import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading_indicator.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/routing/role_gate.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';

/// TAQ-24: the real GoRouter with stub screens, driven through each role.
const protectedRoutes = {
  '/super-admin': 'SuperAdmin',
  '/agency': 'AgencyAdmin',
  '/owner': 'Owner',
  '/tenant': 'Tenant',
};

Widget? stubScreen(String route) => route == RouteAccess.authCheck ? null : Text('screen:$route');

Widget app(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

Future<void> settle(WidgetTester tester) async {
  // The loading indicator animates forever, so pumpAndSettle would time out.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late RoleSession session;
  late GoRouter router;

  Future<void> start(WidgetTester tester, String location) async {
    router = buildAppRouter(session: session, initialLocation: location, screenOverride: stubScreen);
    await tester.pumpWidget(app(router));
    await settle(tester);
  }

  setUp(() {
    LocaleController.currentLocale.value = const Locale('en');
    session = RoleSession();
  });
  tearDown(() => session.dispose());

  testWidgets('a protected route shows a loading state until the claims resolve', (tester) async {
    await start(tester, '/owner');
    expect(find.byType(RoleCheckingView), findsOneWidget);
    expect(find.byType(TashilLoadingIndicator), findsOneWidget);
    expect(find.text('Checking your access…'), findsOneWidget);
    expect(find.text('screen:/owner'), findsNothing);

    session.debugSet(RoleSessionStatus.signedIn, 'Owner');
    await settle(tester);
    expect(find.text('screen:/owner'), findsOneWidget);
    expect(router.state.uri.path, '/owner');
  });

  testWidgets('when the claims resolve to another role, the user lands on their own home', (tester) async {
    await start(tester, '/super-admin');
    session.debugSet(RoleSessionStatus.signedIn, 'Tenant');
    await settle(tester);
    expect(find.text('screen:/tenant'), findsOneWidget);
    expect(find.text('screen:/super-admin'), findsNothing);
  });

  testWidgets('public routes never wait for claims', (tester) async {
    await start(tester, '/');
    expect(find.text('screen:/'), findsOneWidget);
  });

  for (final role in [...protectedRoutes.values, '']) {
    testWidgets('${role.isEmpty ? 'a user without a role' : role} only reaches their own portal', (tester) async {
      session.debugSet(RoleSessionStatus.signedIn, role);
      await start(tester, '/');
      for (final entry in protectedRoutes.entries) {
        router.go(entry.key);
        await settle(tester);
        final expected = entry.value == role ? entry.key : RouteAccess.homeFor(role);
        expect(find.text('screen:$expected'), findsOneWidget, reason: '$role → ${entry.key}');
        expect(router.state.uri.path, expected);
      }
    });
  }

  testWidgets('signed-out users are sent to login with the route to return to', (tester) async {
    session.debugSet(RoleSessionStatus.signedOut);
    await start(tester, '/');
    for (final route in [...protectedRoutes.keys, '/checkout', '/rent-collection', '/payment-schedule', '/fast-onboarding']) {
      router.go(route);
      await settle(tester);
      expect(find.text('screen:/login'), findsOneWidget, reason: route);
      expect(router.state.uri.queryParameters['redirect'], route);
    }
  });

  testWidgets('signing out on a dashboard leaves it', (tester) async {
    session.debugSet(RoleSessionStatus.signedIn, 'Owner');
    await start(tester, '/owner');
    expect(find.text('screen:/owner'), findsOneWidget);

    session.debugSet(RoleSessionStatus.signedOut);
    await settle(tester);
    expect(find.text('screen:/owner'), findsNothing);
    expect(router.state.uri.path, '/login');
  });

  testWidgets('a Tenant can pay at /checkout but an Owner cannot', (tester) async {
    session.debugSet(RoleSessionStatus.signedIn, 'Tenant');
    await start(tester, '/checkout');
    expect(find.text('screen:/checkout'), findsOneWidget);

    session.debugSet(RoleSessionStatus.signedIn, 'Owner');
    await settle(tester);
    expect(find.text('screen:/owner'), findsOneWidget);
  });
}
