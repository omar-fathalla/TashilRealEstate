import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_financials_view.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/property_value_dialog.dart';
import 'package:tashil_real_estate/features/portfolio/services/gross_yield.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

ManagedPropertyModel _property(String id, {double? value, String country = 'AE'}) => ManagedPropertyModel(
      id: id,
      countryCode: country,
      currencyCode: country == 'AE' ? 'AED' : 'EGP',
      titles: const {'en': 'Unit'},
      descriptions: const {},
      locations: const {},
      cityCode: 'dubai',
      propertyTypeCode: 'apartment',
      unitNumber: '1',
      buildingName: 'B',
      pricePerMonth: 8000,
      bedrooms: 2,
      bathrooms: 2,
      areaSqM: 120,
      image: '',
      imageUrls: const [],
      propertyValue: value,
    );

// TAQ-164 part 2: an optional, private property value; gross yield only when it is set.
void main() {
  group('grossRentalYield', () {
    test('is the yearly rent of active leases over the values entered', () {
      final y = grossRentalYield([lease('l1', rent: 8000), lease('l2', rent: 5000)], {'p-l1': 960000}, countryCode: 'AE');
      expect(y, closeTo(10.0, 1e-9), reason: 'l2 has no value, so it is left out of both sides');
    });

    test('is null with no values, no active lease, or only other countries', () {
      expect(grossRentalYield([lease('l1')], const {}, countryCode: 'AE'), isNull);
      expect(grossRentalYield([lease('l1', status: 'ended')], {'p-l1': 1e6}, countryCode: 'AE'), isNull);
      expect(grossRentalYield([lease('l1', country: 'EG')], {'p-l1': 1e6}, countryCode: 'AE'), isNull);
      expect(grossRentalYield([lease('l1')], {'p-l1': 0}, countryCode: 'AE'), isNull);
    });

    test('a property with two active leases counts its value once', () {
      final a = lease('a', rent: 4000);
      final b = lease('a', rent: 4000);
      expect(grossRentalYield([a, b], {'p-a': 960000}, countryCode: 'AE'), closeTo(10.0, 1e-9));
    });
  });

  group('ManagedPropertyModel.propertyValue', () {
    test('round-trips, and is left out of the map when unset', () {
      expect(_property('p').toMap().containsKey('propertyValue'), isFalse);
      final map = _property('p', value: 1500000).toMap();
      expect(map['propertyValue'], 1500000);
      expect(ManagedPropertyModel.fromMap(map).propertyValue, 1500000);
    });

    test('ignores values that are not positive numbers', () {
      expect(ManagedPropertyModel.parsePropertyValue(-1), isNull);
      expect(ManagedPropertyModel.parsePropertyValue(0), isNull);
      expect(ManagedPropertyModel.parsePropertyValue('900000'), isNull);
      expect(ManagedPropertyModel.parsePropertyValue(double.infinity), isNull);
    });

    test('copyWith keeps it unless cleared', () {
      final p = _property('p', value: 5);
      expect(p.copyWith(bedrooms: 3).propertyValue, 5);
      expect(p.copyWith(clearPropertyValue: true).propertyValue, isNull);
    });

    test('an edit that does not carry the value keeps the stored one', () async {
      final service = PropertyLifecycleService();
      final before = service.propertiesNotifier.value;
      addTearDown(() => service.propertiesNotifier.value = before);
      service.propertiesNotifier.value = [_property('keep', value: 700000)];
      await service.updateProperty(_property('keep').copyWith(bedrooms: 4));
      final saved = service.propertiesNotifier.value.single;
      expect(saved.bedrooms, 4);
      expect(saved.propertyValue, 700000);
    });
  });

  group('PropertyValueDialog', () {
    test('parse', () {
      expect(PropertyValueDialog.parse(''), isNull);
      expect(PropertyValueDialog.parse(' 1,250,000 '), 1250000);
      expect(PropertyValueDialog.parse('0')!.isNaN, isTrue);
      expect(PropertyValueDialog.parse('abc')!.isNaN, isTrue);
    });

    Future<void> open(WidgetTester tester, ManagedPropertyModel p, PropertyValueSaver save) async {
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => TextButton(
          onPressed: () => PropertyValueDialog.show(context, p, save: save),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves the typed value and refuses zero', (tester) async {
      final saved = <double?>[];
      await open(tester, _property('p'), (id, v) async => saved.add(v));
      expect(find.byKey(const ValueKey('property_value_clear')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('property_value_field')), '0');
      await tester.tap(find.byKey(const ValueKey('property_value_save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount above zero.'), findsOneWidget);
      expect(saved, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('property_value_field')), '1200000');
      await tester.tap(find.byKey(const ValueKey('property_value_save')));
      await tester.pumpAndSettle();
      expect(saved, [1200000]);
      expect(find.byType(PropertyValueDialog), findsNothing);
    });

    testWidgets('clears a stored value', (tester) async {
      final saved = <double?>[];
      await open(tester, _property('p', value: 9), (id, v) async => saved.add(v));
      await tester.tap(find.byKey(const ValueKey('property_value_clear')));
      await tester.pumpAndSettle();
      expect(saved, [null]);
    });

    testWidgets('says so when the save fails', (tester) async {
      await open(tester, _property('p'), (id, v) async => throw StateError('offline'));
      await tester.enterText(find.byKey(const ValueKey('property_value_field')), '500000');
      await tester.tap(find.byKey(const ValueKey('property_value_save')));
      await tester.pumpAndSettle();
      expect(find.text('Could not save the value. Try again.'), findsOneWidget);
    });
  });

  group('owner financials', () {
    setUp(() => CountryController.setCountry('AE'));
    tearDown(() {
      CountryController.setCountry('EG');
      RentCollectionService().leaveServerMode(signedIn: false);
    });

    Future<PortfolioController> controller(WidgetTester tester) async {
      final backend = FakePortfolioBackend(agency: '', uid: 'o1')
        ..leases = [lease('l1', rent: 8000, start: '2026-08-10', end: '2099-08-09')];
      final c = PortfolioController(
        data: PortfolioDataService(backend: backend),
        requests: RequestsService(backend: FakeRequestsBackendForPortfolio()),
        agencyOnly: false,
        includeRequests: false,
      );
      addTearDown(c.dispose);
      await tester.runAsync(() async {
        await c.start();
        await Future<void>.delayed(Duration.zero);
      });
      return c;
    }

    void big(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1800);
      addTearDown(tester.view.reset);
    }

    testWidgets('show the gross yield only once a property value is set', (tester) async {
      big(tester);
      final service = PropertyLifecycleService();
      final before = service.propertiesNotifier.value;
      addTearDown(() => service.propertiesNotifier.value = before);
      service.propertiesNotifier.value = [_property('p-l1')];

      final c = await controller(tester);
      await tester.pumpWidget(testApp(OwnerFinancialsView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('owner_gross_yield_kpi')), findsNothing);

      service.propertiesNotifier.value = [_property('p-l1', value: 960000)];
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('owner_gross_yield_kpi')), findsOneWidget);
      expect(find.text('10.0%'), findsOneWidget);
    });
  });
}
