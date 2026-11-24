import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/role_gate.dart';

/// TAQ-24: RoleGate is the second layer around dashboards, independent of the redirect.
void main() {
  late RoleSession session;

  setUp(() {
    LocaleController.currentLocale.value = const Locale('en');
    session = RoleSession();
  });
  tearDown(() => session.dispose());

  Future<void> pumpGate(WidgetTester tester, String route) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => RoleGate(route: route, session: session, child: const Text('dashboard'))),
      GoRoute(path: '/tenant', builder: (_, __) => const Text('tenant home')),
    ]);
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
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('shows a loading state while the role is unknown', (tester) async {
    await pumpGate(tester, '/owner');
    expect(find.byType(RoleCheckingView), findsOneWidget);
    expect(find.text('dashboard'), findsNothing);
  });

  testWidgets('renders the dashboard for an allowed role', (tester) async {
    session.debugSet(RoleSessionStatus.signedIn, 'Owner');
    await pumpGate(tester, '/owner');
    expect(find.text('dashboard'), findsOneWidget);
  });

  for (final role in ['Tenant', 'AgencyAdmin', 'SuperAdmin', '']) {
    testWidgets('blocks the Owner dashboard for ${role.isEmpty ? 'a user without a role' : role}', (tester) async {
      session.debugSet(RoleSessionStatus.signedIn, role);
      await pumpGate(tester, '/owner');
      expect(find.text('dashboard'), findsNothing);
      expect(find.byType(AccessDeniedView), findsOneWidget);
      expect(find.text("You don't have access to this page"), findsOneWidget);
    });
  }

  for (final role in ['Admin', 'SuperAdmin']) {
    testWidgets('TAQ-91: $role may open the /admin workspace', (tester) async {
      session.debugSet(RoleSessionStatus.signedIn, role);
      await pumpGate(tester, '/admin');
      expect(find.text('dashboard'), findsOneWidget);
    });
  }

  for (final role in ['Investor', 'Owner', 'Tenant', 'AgencyAdmin', '']) {
    testWidgets('TAQ-91: ${role.isEmpty ? 'a user without a role' : role} cannot open /admin', (tester) async {
      session.debugSet(RoleSessionStatus.signedIn, role);
      await pumpGate(tester, '/admin');
      expect(find.text('dashboard'), findsNothing);
      expect(find.byType(AccessDeniedView), findsOneWidget);
    });
  }

  testWidgets('TAQ-91: an Admin cannot open the SuperAdmin dashboard', (tester) async {
    session.debugSet(RoleSessionStatus.signedIn, 'Admin');
    await pumpGate(tester, '/super-admin');
    expect(find.text('dashboard'), findsNothing);
    expect(find.byType(AccessDeniedView), findsOneWidget);
  });

  testWidgets('blocks signed-out users', (tester) async {
    session.debugSet(RoleSessionStatus.signedOut);
    await pumpGate(tester, '/tenant');
    expect(find.text('dashboard'), findsNothing);
    expect(find.byType(AccessDeniedView), findsOneWidget);
  });

  testWidgets('reacts when the role changes underneath an open dashboard', (tester) async {
    session.debugSet(RoleSessionStatus.signedIn, 'SuperAdmin');
    await pumpGate(tester, '/super-admin');
    expect(find.text('dashboard'), findsOneWidget);

    session.debugSet(RoleSessionStatus.signedIn, 'Tenant');
    await tester.pump();
    expect(find.text('dashboard'), findsNothing);

    await tester.tap(find.text('Go to my home page'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('tenant home'), findsOneWidget);
  });

  testWidgets('leaves public routes alone', (tester) async {
    session.debugSet(RoleSessionStatus.signedOut);
    await pumpGate(tester, '/market-index');
    expect(find.text('dashboard'), findsOneWidget);
  });
}
