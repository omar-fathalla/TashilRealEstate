import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/features/admin/admin_dashboard.dart';
import 'package:tashil_real_estate/features/admin/admin_data_source.dart';

class _FakeAdminData implements AdminDataSource {
  _FakeAdminData({List<AdminListing>? listings}) : listings = listings ?? _defaultListings();

  List<AdminListing> listings;
  final calls = <String>[];
  final _controller = StreamController<List<AdminListing>>.broadcast();
  bool failWrites = false;
  bool failUsers = false;

  static List<AdminListing> _defaultListings() => const [
        AdminListing(
          id: 'p1',
          title: 'Sea view flat',
          location: 'Dubai Marina',
          pricePerMonth: 14500,
          currencyCode: 'AED',
          isPublished: true,
          verified: false,
          hidden: false,
          status: 'vacant',
        ),
        AdminListing(
          id: 'p2',
          title: 'Hidden villa',
          location: 'Cairo',
          pricePerMonth: 28000,
          currencyCode: 'EGP',
          isPublished: false,
          verified: true,
          hidden: true,
          status: 'vacant',
        ),
        AdminListing(
          id: 'p3',
          title: 'Rented hidden flat',
          location: 'Cairo',
          pricePerMonth: 9000,
          currencyCode: 'EGP',
          isPublished: false,
          verified: false,
          hidden: true,
          status: 'rented',
        ),
      ];

  @override
  Stream<List<AdminListing>> watchListings(String langCode) async* {
    yield listings;
    yield* _controller.stream;
  }

  Future<void> _write(String call) async {
    calls.add(call);
    if (failWrites) throw Exception('permission-denied');
  }

  @override
  Future<void> setVerified(String listingId, bool verified) => _write('verify:$listingId:$verified');

  @override
  Future<void> hide(AdminListing listing) => _write('hide:${listing.id}:wasPublished=${listing.isPublished}');

  @override
  Future<void> restore(AdminListing listing) => _write('restore:${listing.id}');

  /// Two pages: u1..u2 then u3 (token 'u2'). A third request would be a bug.
  @override
  Future<AdminUserPage> loadUsers({String? startAfter}) async {
    calls.add('loadUsers:${startAfter ?? 'first'}');
    if (failUsers) throw Exception('unavailable');
    if (startAfter == null) {
      return const AdminUserPage(users: [
        AdminUserRow(uid: 'u1', email: 'owner@test.tashilaqar.com', fullName: 'Demo Owner', role: 'Owner', claimRole: 'Owner'),
        AdminUserRow(uid: 'u2', email: 'investor@test.tashilaqar.com', fullName: '', role: 'Owner', claimRole: 'Admin'),
      ], nextPageToken: 'u2');
    }
    return const AdminUserPage(users: [
      AdminUserRow(uid: 'u3', email: 'third@test.tashilaqar.com', fullName: 'Third User', role: 'Investor'),
    ]);
  }

  bool canVerify = false;

  @override
  Stream<List<AdminAgencyRow>> watchAgencies(String langCode) => Stream.value(const [
        AdminAgencyRow(id: 'a1', name: 'Demo Agency', verified: true, city: 'Dubai', orn: '12345', licenceStatus: 'verified'),
        AdminAgencyRow(id: 'a2', name: 'New Agency', verified: false, city: 'Abu Dhabi', orn: '777', licenceStatus: 'pending'),
      ]);

  @override
  Future<bool> canVerifyAgencies() async => canVerify;

  @override
  Future<void> setAgencyLicence(String agencyId, String status) => _write('licence:$agencyId:$status');
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    home: home,
  );
}

Future<void> _pump(WidgetTester tester, _FakeAdminData data, {Locale locale = const Locale('en')}) async {
  LocaleController.setLocale(locale);
  await tester.binding.setSurfaceSize(const Size(1000, 900));
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    LocaleController.setLocale(const Locale('ar'));
  });
  await tester.pumpWidget(_app(AdminDashboard(dataSource: data, onSignOut: () async {}), locale: locale));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TAQ-91: AdminDashboard moderation', () {
    testWidgets('shows listings with moderation state and verify/hide/restore controls', (tester) async {
      await _pump(tester, _FakeAdminData());
      expect(find.text('Platform admin workspace'), findsOneWidget);
      expect(find.text('Sea view flat'), findsOneWidget);
      expect(find.byKey(const Key('admin-hide-p1')), findsOneWidget);
      expect(find.byKey(const Key('admin-restore-p1')), findsNothing);
      expect(find.byKey(const Key('admin-restore-p2')), findsOneWidget);
      expect(find.byKey(const Key('admin-hide-p2')), findsNothing);
    });

    testWidgets('hide, verify and restore call the data source', (tester) async {
      final data = _FakeAdminData();
      await _pump(tester, data);

      await tester.tap(find.byKey(const Key('admin-hide-p1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin-verify-p1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin-restore-p2')));
      await tester.pump();

      expect(data.calls, ['hide:p1:wasPublished=true', 'verify:p1:true', 'restore:p2']);
    });

    testWidgets('a hidden listing that is no longer vacant cannot be restored', (tester) async {
      final data = _FakeAdminData();
      await _pump(tester, data);
      await tester.tap(find.byKey(const Key('admin-restore-p3')), warnIfMissed: false);
      await tester.pump();
      expect(data.calls, isEmpty);
    });

    testWidgets('a rejected write shows an error and does not crash', (tester) async {
      final data = _FakeAdminData()..failWrites = true;
      await _pump(tester, data);
      await tester.tap(find.byKey(const Key('admin-hide-p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('The action failed'), findsOneWidget);
    });
  });

  group('TAQ-91: AdminDashboard read-only views', () {
    testWidgets('users come from the sanitized callable and have no edit controls', (tester) async {
      final data = _FakeAdminData();
      await _pump(tester, data);
      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(data.calls, contains('loadUsers:first'));
      expect(find.byKey(const Key('admin-user-u1')), findsOneWidget);
      expect(find.text('Demo Owner'), findsOneWidget);
      expect(find.text('investor@test.tashilaqar.com'), findsOneWidget);
      expect(find.byKey(const Key('admin-read-only-note')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Hide listing'), findsNothing);
    });

    testWidgets('the users tab shows the claim role, and the profile role too when they differ', (tester) async {
      await _pump(tester, _FakeAdminData());
      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.descendant(of: find.byKey(const Key('admin-user-role-u1')), matching: find.text('Property Owner')), findsOneWidget);
      expect(find.byKey(const Key('admin-user-profile-role-u1')), findsNothing);
      expect(find.descendant(of: find.byKey(const Key('admin-user-role-u2')), matching: find.text('Platform Admin')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('admin-user-profile-role-u2')), matching: find.text('Profile role: Property Owner')), findsOneWidget);
    });

    testWidgets('the users tab pages past the first page with startAfter', (tester) async {
      final data = _FakeAdminData();
      await _pump(tester, data);
      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('admin-user-u3')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('admin-users-load-more')));
      await tester.tap(find.byKey(const Key('admin-users-load-more')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(data.calls.where((c) => c.startsWith('loadUsers')), ['loadUsers:first', 'loadUsers:u2']);
      expect(find.byKey(const Key('admin-user-u1')), findsOneWidget);
      expect(find.byKey(const Key('admin-user-u3')), findsOneWidget);
      expect(find.byKey(const Key('admin-users-load-more')), findsNothing, reason: 'the last page has no token');
    });

    testWidgets('a failed first page shows an error, not an empty list', (tester) async {
      await _pump(tester, _FakeAdminData()..failUsers = true);
      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Could not load the data'), findsOneWidget);
      expect(find.text('No users'), findsNothing);
    });

    testWidgets('agencies are listed read-only', (tester) async {
      await _pump(tester, _FakeAdminData());
      await tester.tap(find.text('Agencies'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('admin-agency-a1')), findsOneWidget);
      expect(find.text('Demo Agency'), findsOneWidget);
      expect(find.byKey(const Key('admin-read-only-note')), findsOneWidget);
      expect(find.text('Licence verified'), findsOneWidget);
      expect(find.text('Licence pending review'), findsOneWidget);
      expect(find.text('ORN: 777'), findsOneWidget);
      // A platform Admin sees the status but cannot change it (TAQ-154).
      expect(find.byKey(const Key('admin-agency-verify-a2')), findsNothing);
      expect(find.byKey(const Key('admin-agency-reject-a2')), findsNothing);
    });

    testWidgets('a SuperAdmin verifies or rejects an agency licence by hand (TAQ-154)', (tester) async {
      final data = _FakeAdminData()..canVerify = true;
      await _pump(tester, data);
      await tester.tap(find.text('Agencies'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('admin-agency-verify-a2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin-agency-reject-a1')));
      await tester.pump();
      expect(data.calls, containsAll(['licence:a2:verified', 'licence:a1:rejected']));
    });

    testWidgets('the dashboard has no role, payment or settings controls', (tester) async {
      await _pump(tester, _FakeAdminData());
      for (final word in ['Super Admin', 'Role', 'Payment', 'Settings', 'Seed', 'IBAN', 'National ID']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });

    testWidgets('renders in Arabic and Hindi with the translated role labels', (tester) async {
      await _pump(tester, _FakeAdminData(), locale: const Locale('ar'));
      expect(find.text('مساحة عمل أدمن المنصة'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _FakeAdminData(), locale: const Locale('hi'));
      expect(find.text('प्लेटफ़ॉर्म एडमिन कार्यक्षेत्र'), findsOneWidget);
    });
  });

  group('TAQ-91: localized role labels', () {
    testWidgets('Admin and Investor labels exist in all three languages', (tester) async {
      addTearDown(() => LocaleController.setLocale(const Locale('ar')));
      Future<AppLocalizations> loc(Locale locale) async {
        LocaleController.setLocale(locale);
        late AppLocalizations out;
        await tester.pumpWidget(_app(Builder(builder: (context) {
          out = AppLocalizations.of(context);
          return const SizedBox();
        }), locale: locale));
        await tester.pump();
        return out;
      }

      final ar = await loc(const Locale('ar'));
      expect(ar.tr('roleAdmin'), 'أدمن المنصة');
      expect(ar.tr('roleInvestor'), 'مستثمر');
      final en = await loc(const Locale('en'));
      expect(en.tr('roleAdmin'), 'Platform Admin');
      expect(en.tr('roleInvestor'), 'Investor');
      final hi = await loc(const Locale('hi'));
      expect(hi.tr('roleAdmin'), 'प्लेटफ़ॉर्म एडमिन');
      expect(hi.tr('roleInvestor'), 'निवेशक');
    });
  });

  group('TAQ-91: /admin route', () {
    test('is registered and guarded', () {
      final router = buildAppRouter(session: RoleSession());
      final paths = router.configuration.routes.whereType<GoRoute>().map((r) => r.path);
      expect(paths, contains('/admin'));
    });
  });
}
