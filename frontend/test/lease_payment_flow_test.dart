import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/callable_error.dart';
import 'package:tashil_real_estate/features/owner_portal/services/lease_payment_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/record_manual_payment_dialog.dart';

class FakeBackend implements LeasePaymentBackend {
  String? uid;
  String? agency;
  List<PayableLease> leases;
  Object? failRecord;
  Object? failReminder;
  final scopes = <String>[];
  final recorded = <Map<String, dynamic>>[];
  final reminders = <Map<String, dynamic>>[];

  FakeBackend({this.uid = 'owner1', this.agency, this.leases = const []});

  @override
  String? get currentUserId => uid;
  @override
  Future<String?> currentAgencyId() async => agency;
  @override
  Future<List<PayableLease>> activeLeases({required String field, required String value}) async {
    scopes.add('$field=$value');
    return leases;
  }

  @override
  Future<Map<String, dynamic>> recordManualPayment({
    required String leaseId,
    required String method,
    required String reference,
    required String paidOn,
    required String period,
    required double amount,
  }) async {
    if (failRecord != null) throw failRecord!;
    recorded.add({'leaseId': leaseId, 'method': method, 'reference': reference, 'paidOn': paidOn, 'period': period, 'amount': amount});
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> sendRentalReminder({required String leaseId, required String dueDate}) async {
    if (failReminder != null) throw failReminder!;
    reminders.add({'leaseId': leaseId, 'dueDate': dueDate});
    return {'success': true};
  }
}

const marina = PayableLease(id: 'l1', propertyId: 'p1', propertyTitle: 'Marina Apartment', tenantName: 'Sara Ali', monthlyRent: 8500, currencyCode: 'AED');
const palm = PayableLease(id: 'l2', propertyId: 'p2', propertyTitle: 'Palm Villa', tenantName: 'Omar Hassan', monthlyRent: 12000.5, currencyCode: 'AED');

Widget app(Widget child, {Locale locale = const Locale('en')}) {
  LocaleController.setLocale(locale);
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
    home: Scaffold(body: child),
  );
}

Future<void> openDialog(
  WidgetTester tester,
  FakeBackend backend, {
  String? propertyId,
  String? period,
  void Function(String, String)? onRecorded,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(app(
    Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => RecordManualPaymentDialog(
            propertyId: propertyId,
            period: period,
            onRecorded: onRecorded,
            service: LeasePaymentService(backend: backend),
            now: () => DateTime(2026, 11, 25),
          ),
        ),
        child: const Text('open'),
      ),
    ),
    locale: locale,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextField, label);

void main() {
  group('LeasePaymentService', () {
    test('an owner sees their own active leases; an agency admin sees the agency\'s; signed out sees none', () async {
      final owner = FakeBackend(leases: [palm, marina]);
      final list = await LeasePaymentService(backend: owner).activeLeases();
      expect(owner.scopes, ['owner_id=owner1']);
      expect(list.map((l) => l.id), ['l1', 'l2'], reason: 'sorted by label');

      final agency = FakeBackend(uid: 'ag-admin', agency: 'ag1', leases: [marina]);
      await LeasePaymentService(backend: agency).activeLeases();
      expect(agency.scopes, ['agency_id=ag1']);

      expect(await LeasePaymentService(backend: FakeBackend(uid: null, leases: [marina])).activeLeases(), isEmpty);
    });

    test('leases read the new and the legacy rent fields', () {
      expect(PayableLease.fromMap('a', {'monthly_rent': 5000, 'country_code': 'EG'}).currencyCode, 'EGP');
      expect(PayableLease.fromMap('b', {'financialTerms': {'annualRent': 120000}}).monthlyRent, 10000);
      expect(PayableLease.fromMap('c', {'property_title': 'T', 'tenant_name': 'N'}).label, 'T · N');
    });

    test('a reminder goes to the active lease on the property, and failures are thrown', () async {
      final backend = FakeBackend(leases: [marina, palm]);
      await LeasePaymentService(backend: backend).sendReminderForProperty('p2', dueDate: '2026-12-01');
      expect(backend.reminders, [
        {'leaseId': 'l2', 'dueDate': '2026-12-01'}
      ]);
      await expectLater(LeasePaymentService(backend: backend).sendReminderForProperty('nope', dueDate: '2026-12-01'), throwsA(isA<NoActiveLeaseException>()));
      backend.failReminder = FirebaseFunctionsException(code: 'resource-exhausted', message: 'A reminder was already sent for this lease in the last 24 hours.');
      await expectLater(
        LeasePaymentService(backend: backend).sendReminderForProperty('p1', dueDate: '2026-12-01'),
        throwsA(isA<FirebaseFunctionsException>().having((e) => e.code, 'code', 'resource-exhausted')),
      );
      expect(backend.reminders.length, 1, reason: 'a failed call is not recorded as sent');
    });

    test('describeCallableError keeps the code and the server message', () {
      final info = describeCallableError(FirebaseFunctionsException(code: 'already-exists', message: 'Rent for 2026-11 has already been paid on this lease.'));
      expect(info.code, 'already-exists');
      expect(info.text, 'already-exists: Rent for 2026-11 has already been paid on this lease.');
      expect(describeCallableError(Exception('boom')).code, 'unknown');
    });
  });

  group('RecordManualPaymentDialog', () {
    testWidgets('lists active leases, records a bank transfer through the function and closes', (tester) async {
      final backend = FakeBackend(leases: [marina, palm]);
      String? seenMethod;
      String? seenReference;
      await openDialog(tester, backend, onRecorded: (m, r) {
        seenMethod = m;
        seenReference = r;
      });
      await tester.tap(find.byType(DropdownButtonFormField<PayableLease>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palm Villa · Omar Hassan').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field('Amount received')).controller!.text, '12000.5');
      await tester.enterText(field('Amount received'), '12000.5');
      await tester.tap(find.text('Bank transfer'));
      await tester.pump();
      await tester.enterText(field('Reference or receipt number'), '  TRX-4411  ');
      await tester.enterText(field('Date received (YYYY-MM-DD)'), '2026-11-20');
      await tester.tap(find.text('Record payment and issue receipt'));
      await tester.pumpAndSettle();
      expect(backend.recorded.single, {
        'leaseId': 'l2',
        'method': 'bank_transfer',
        'reference': 'TRX-4411',
        'paidOn': '2026-11-20',
        'period': '2026-11',
        'amount': 12000.5,
      });
      expect(seenMethod, 'bank_transfer');
      expect(seenReference, 'TRX-4411');
      expect(find.byType(RecordManualPaymentDialog), findsNothing);
    });

    testWidgets('the lease for the property is preselected and cash is the default', (tester) async {
      final backend = FakeBackend(leases: [marina, palm]);
      await openDialog(tester, backend, propertyId: 'p1', period: '2026-10');
      expect(tester.widget<TextField>(field('Amount received')).controller!.text, '8500');
      expect(tester.widget<TextField>(field('Month (YYYY-MM)')).controller!.text, '2026-10');
      await tester.enterText(field('Reference or receipt number'), 'RCPT-1');
      await tester.tap(find.text('Record payment and issue receipt'));
      await tester.pumpAndSettle();
      expect(backend.recorded.single['leaseId'], 'l1');
      expect(backend.recorded.single['method'], 'cash');
      expect(backend.recorded.single['period'], '2026-10');
      expect(backend.recorded.single['paidOn'], '2026-11-25');
    });

    testWidgets('a missing reference sends nothing', (tester) async {
      final backend = FakeBackend(leases: [marina]);
      await openDialog(tester, backend);
      await tester.tap(find.text('Record payment and issue receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Fill in every field with a valid amount.'), findsOneWidget);
      expect(backend.recorded, isEmpty);
    });

    testWidgets('a server refusal shows a translated message, never the server text, and keeps the dialog open', (tester) async {
      final backend = FakeBackend(leases: [marina])
        ..failRecord = FirebaseFunctionsException(code: 'already-exists', message: 'Rent for 2026-11 has already been paid on this lease.');
      var recorded = 0;
      await openDialog(tester, backend, onRecorded: (_, __) => recorded++);
      await tester.enterText(field('Reference or receipt number'), 'RCPT-1');
      await tester.tap(find.text('Record payment and issue receipt'));
      await tester.pumpAndSettle();
      expect(find.text('This month is already paid on this lease.'), findsOneWidget);
      expect(find.text('Rent for 2026-11 has already been paid on this lease.'), findsNothing);
      expect(find.byType(RecordManualPaymentDialog), findsOneWidget);
      expect(recorded, 0, reason: 'nothing is synced locally when the server refused');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('TAQ-110 N-2: an unknown code or reason shows a generic translated message, never raw server English (${locale.languageCode})', (tester) async {
        for (final error in [
          FirebaseFunctionsException(code: 'internal', message: 'Failed to record the payment.'),
          FirebaseFunctionsException(code: 'failed-precondition', message: 'Something new the app does not know.', details: {'reason': 'brand_new_reason'}),
          FirebaseFunctionsException(code: 'weird-code', message: 'Totally unexpected.', details: {'reason': 'other'}),
        ]) {
          final backend = FakeBackend(leases: [marina])..failRecord = error;
          await openDialog(tester, backend, locale: locale);
          await tester.enterText(find.byType(TextField).at(2), 'RCPT-1');
          await tester.tap(find.byType(TashilButton));
          await tester.pumpAndSettle();
          final loc = AppLocalizations(locale);
          final expected = error.code == 'failed-precondition' ? loc.tr('mpErr_failed-precondition') : loc.tr('mpErr_unknown');
          expect(find.text(expected), findsOneWidget, reason: error.code);
          expect(find.textContaining(error.message!), findsNothing, reason: error.code);
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('TAQ-110 N-2: an open online payment shows when it expires, in local time (${locale.languageCode})', (tester) async {
        final until = DateTime(2026, 11, 25, 14, 37);
        final backend = FakeBackend(leases: [marina])
          ..failRecord = FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'An online payment for this month is still open. Try again after it expires.',
            details: {'reason': 'payment_pending', 'retryAfterMs': until.millisecondsSinceEpoch, 'period': '2026-11'},
          );
        await openDialog(tester, backend, locale: locale);
        await tester.enterText(find.byType(TextField).at(2), 'RCPT-1');
        await tester.tap(find.byType(TashilButton));
        await tester.pumpAndSettle();
        final text = AppLocalizations(locale).tr('mpErr_payment_pending').replaceAll('{time}', '2026-11-25 14:37');
        expect(find.text(text), findsOneWidget);
        expect(find.textContaining('still open. Try again'), findsNothing);
      });
    }

    test('TAQ-110 N-2: manual payment reasons map to their own messages in every language', () {
      for (final lang in ['ar', 'en', 'hi']) {
        final loc = AppLocalizations(Locale(lang));
        final utc = DateTime.utc(2026, 11, 25, 10, 5);
        final pending = manualPaymentErrorText(loc, CallableErrorInfo('failed-precondition', 'x', reason: 'payment_pending', retryAfterMs: utc.millisecondsSinceEpoch));
        expect(pending, contains(localDateTimeLabel(utc.toLocal())), reason: lang);
        expect(pending, isNot(contains('{time}')));
        expect(manualPaymentErrorText(loc, const CallableErrorInfo('failed-precondition', 'x', reason: 'payment_pending')), loc.tr('mpErr_payment_pending_soon'));
        expect(manualPaymentErrorText(loc, const CallableErrorInfo('already-exists', 'x', reason: 'already_paid')), loc.tr('mpErr_already-exists'));
        expect(manualPaymentErrorText(loc, const CallableErrorInfo('failed-precondition', 'x', reason: 'lease_not_verified')), loc.tr('mpErr_lease_not_verified'));
        for (final reason in ['property_not_registered', 'property_id_conflict']) {
          expect(manualPaymentErrorText(loc, CallableErrorInfo('failed-precondition', 'x', reason: reason)), loc.tr('mpErr_property_invalid'));
        }
        for (final key in ['mpErr_payment_pending', 'mpErr_payment_pending_soon', 'mpErr_lease_not_verified', 'mpErr_property_invalid']) {
          expect(loc.tr(key), isNot(key), reason: '$lang $key');
        }
      }
      expect(localDateTimeLabel(DateTime(2026, 1, 2, 3, 4)), '2026-01-02 03:04');
      final info = describeCallableError(FirebaseFunctionsException(code: 'failed-precondition', message: 'm', details: {'reason': 'payment_pending', 'retryAfterMs': 1700000000000}));
      expect(info.retryAfterMs, 1700000000000);
      expect(describeCallableError(FirebaseFunctionsException(code: 'internal', message: 'm')).retryAfterMs, isNull);
    });

    testWidgets('no active leases: explains and offers no form', (tester) async {
      await openDialog(tester, FakeBackend());
      expect(find.text('There are no active leases to record a payment on.'), findsOneWidget);
      expect(find.text('Record payment and issue receipt'), findsNothing);
    });

    testWidgets('renders in Arabic', (tester) async {
      await openDialog(tester, FakeBackend(leases: [marina]), locale: const Locale('ar'));
      expect(find.text('تسجيل الدفعة وإصدار الإيصال'), findsOneWidget);
      expect(find.text('تحويل بنكي'), findsOneWidget);
    });
  });
}
