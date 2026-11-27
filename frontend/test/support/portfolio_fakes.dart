import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

class FakePortfolioBackend implements PortfolioBackend {
  bool signedIn;
  String agency;
  String uid;
  bool superAdmin = false;
  List<PortfolioLease> leases = const [];
  List<PortfolioTransaction> transactions = const [];
  List<PortfolioInvoice> invoices = const [];
  List<PortfolioMaintenance> maintenance = const [];
  bool failStreams = false;
  Object? createFailure;
  Object? statusFailure;
  final scopes = <PortfolioScope>[];
  final created = <Map<String, dynamic>>[];
  final statusChanges = <MapEntry<String, String>>[];
  final deleted = <String>[];

  FakePortfolioBackend({this.signedIn = true, this.agency = 'agency-1', this.uid = 'u1'});

  @override
  String? get currentUserId => signedIn ? uid : null;

  @override
  Future<String> currentAgencyId() async => agency;

  @override
  Future<bool> currentIsSuperAdmin() async => superAdmin;

  Stream<List<T>> _stream<T>(PortfolioScope scope, List<T> items) {
    scopes.add(scope);
    if (failStreams) return Stream.error(StateError('denied'));
    return Stream.value(items);
  }

  @override
  Stream<List<PortfolioLease>> watchLeases(PortfolioScope scope) => _stream(scope, leases);

  @override
  Stream<List<PortfolioTransaction>> watchTransactions(PortfolioScope scope) => _stream(scope, transactions);

  @override
  Stream<List<PortfolioInvoice>> watchInvoices(PortfolioScope scope) => _stream(scope, invoices);

  @override
  Stream<List<PortfolioMaintenance>> watchMaintenance(PortfolioScope scope) => _stream(scope, maintenance);

  @override
  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data) async {
    if (createFailure != null) throw createFailure!;
    created.add(data);
    return {'success': true, 'leaseId': 'lease_new'};
  }

  @override
  Future<void> setLeaseStatus(String leaseId, String status) async {
    if (statusFailure != null) throw statusFailure!;
    statusChanges.add(MapEntry(leaseId, status));
  }

  @override
  Future<void> deleteDraftLease(String leaseId) async => deleted.add(leaseId);
}

class FakeRequestsBackendForPortfolio implements RequestsBackend {
  List<ViewingRequestItem> viewings = const [];
  List<RentalApplicationItem> applications = const [];
  RequestScope? lastScope;

  @override
  String? get currentUserId => 'u1';
  @override
  bool get isSignedIn => true;
  @override
  Future<String> currentAgencyId() async => 'agency-1';
  @override
  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) {
    lastScope = scope;
    return Stream.value(viewings);
  }

  @override
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) => Stream.value(applications);
  @override
  Stream<String> watchLeaseStatus(String leaseId) => Stream.value('draft');
  @override
  Future<void> sendLeaseOffer(String leaseId) async {}
  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data) async => {'success': true};
}

ManagedPropertyModel unit(
  String id, {
  String country = 'AE',
  bool rented = false,
  String title = 'Marina Tower 1204',
  double price = 12000,
}) =>
    ManagedPropertyModel(
      id: id,
      countryCode: country,
      currencyCode: country == 'EG' ? 'EGP' : 'AED',
      titles: {'ar': title, 'en': title, 'hi': title},
      descriptions: const {},
      locations: const {'ar': 'Dubai', 'en': 'Dubai', 'hi': 'Dubai'},
      cityCode: 'dubai',
      propertyTypeCode: 'apartment',
      unitNumber: '1204',
      buildingName: 'Marina',
      pricePerMonth: price,
      bedrooms: 2,
      bathrooms: 2,
      areaSqM: 90,
      image: '',
      imageUrls: const [],
      rentalStatus: rented ? PropertyRentalStatus.rented : PropertyRentalStatus.available,
    );

PortfolioLease lease(
  String id, {
  String status = 'active',
  String country = 'AE',
  double rent = 8000,
  String title = 'Marina Tower 1204',
  String start = '2026-01-01',
  String end = '2026-12-31',
  DateTime? changed,
}) =>
    PortfolioLease(
      id: id,
      status: status,
      propertyId: 'p-$id',
      propertyTitle: title,
      tenantId: 't-$id',
      tenantName: 'Tenant $id',
      ownerId: 'o1',
      agencyId: 'agency-1',
      monthlyRent: rent,
      currencyCode: country == 'EG' ? 'EGP' : 'AED',
      countryCode: country,
      startDate: start,
      endDate: end,
      updatedAt: changed ?? DateTime(2026, 11, 20),
    );

Widget testApp(Widget child, {Locale locale = const Locale('en')}) {
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

Future<void> settle(Future<void> Function() pump) async {
  await pump();
  await Future<void>.delayed(Duration.zero);
}
