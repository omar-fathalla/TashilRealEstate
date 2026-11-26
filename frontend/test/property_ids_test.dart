import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/utils/property_ids.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';

// TAQ-110 N-1: new properties get ids nobody can guess; an id another owner already holds is
// refused by the rules and explained, and saving again uses a new id.
void main() {
  test('new property ids are prop- plus 20 random characters, and never repeat', () {
    final ids = {for (var i = 0; i < 2000; i++) newPropertyId()};
    expect(ids.length, 2000);
    for (final id in ids.take(50)) {
      expect(id, matches(RegExp(r'^prop-[A-Za-z0-9]{20}$')));
      expect(id, isNot(matches(RegExp(r'^prop-\d+$'))), reason: 'not a clock value');
    }
    expect(newPropertyId(Random(7)), newPropertyId(Random(7)), reason: 'the generator is injectable for tests');
    expect(newPropertyId(Random(7)), isNot(newPropertyId(Random(8))));
  });

  test('a model read without an id gets an unguessable one; a stored id is kept', () {
    expect(ManagedPropertyModel.fromMap(const {}).id, matches(RegExp(r'^prop-[A-Za-z0-9]{20}$')));
    expect(ManagedPropertyModel.fromMap(const {}, docId: 'prop-1700000000000').id, 'prop-1700000000000');
    expect(ManagedPropertyModel.fromMap(const {'id': 'prop-eg-101'}).id, 'prop-eg-101');
  });

  test('a property saved as available writes rentalStatus available explicitly', () {
    final p = ManagedPropertyModel.fromMap(const {}).copyWith(rentalStatus: PropertyRentalStatus.available);
    expect(p.toMap()['rentalStatus'], 'available');
    expect(ManagedPropertyModel.fromMap(const {}).rentalStatus, PropertyRentalStatus.available, reason: 'a doc without a status reads as available');
  });

  test('creating an id another owner holds is explained in every language; other failures are generic', () {
    final denied = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Missing or insufficient permissions.');
    expect(propertySaveErrorKey(denied, creating: true), 'propIdTakenError');
    expect(propertySaveErrorKey(denied, creating: false), 'propSaveFailedError');
    expect(propertySaveErrorKey(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'), creating: true), 'propSaveFailedError');
    expect(propertySaveErrorKey(Exception('offline'), creating: true), 'propSaveFailedError');
    for (final lang in ['ar', 'en', 'hi']) {
      final loc = AppLocalizations(Locale(lang));
      for (final key in ['propIdTakenError', 'propSaveFailedError']) {
        expect(loc.tr(key), isNot(key), reason: '$lang $key');
        expect(loc.tr(key), isNot(contains('permission')), reason: '$lang $key');
      }
    }
    expect(AppLocalizations(const Locale('en')).tr('propIdTakenError'), 'This property ID is already in use. Save again to get a new ID for the property.');
    expect(AppLocalizations(const Locale('ar')).tr('propIdTakenError'), 'رقم العقار هذا مستخدم من قبل. احفظ مرة أخرى ليُنشأ رقم جديد للعقار.');
  });

  test('lease creation from an application explains unverified ownership and rent precision', () {
    FirebaseFunctionsException refusal(String reason) =>
        FirebaseFunctionsException(code: 'failed-precondition', message: 'x', details: {'reason': reason});
    expect(requestErrorKey(refusal('property_not_registered')), 'rqPropertyNotVerified');
    expect(requestErrorKey(refusal('property_id_conflict')), 'rqPropertyNotVerified');
    expect(requestErrorKey(FirebaseFunctionsException(code: 'invalid-argument', message: 'x', details: {'reason': 'rent_precision'})), 'rqRentPrecision');
    expect(requestErrorKey(FirebaseFunctionsException(code: 'invalid-argument', message: 'x', details: {'reason': 'contact_in_message'})), 'rqContactInMessage');
    for (final lang in ['ar', 'en', 'hi']) {
      final loc = AppLocalizations(Locale(lang));
      for (final key in ['rqPropertyNotVerified', 'rqRentPrecision', 'rqContactInMessage']) {
        expect(loc.tr(key), isNot(key), reason: '$lang $key');
      }
    }
  });
}
