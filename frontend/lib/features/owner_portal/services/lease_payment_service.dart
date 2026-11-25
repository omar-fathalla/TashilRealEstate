import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/cloud_functions_service.dart';

/// An active lease the signed-in owner or agency can record a rent payment on.
class PayableLease {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String tenantName;
  final double monthlyRent;
  final String currencyCode;

  const PayableLease({
    required this.id,
    this.propertyId = '',
    this.propertyTitle = '',
    this.tenantName = '',
    this.monthlyRent = 0,
    this.currencyCode = 'AED',
  });

  String get label => [if (propertyTitle.isNotEmpty) propertyTitle, if (tenantName.isNotEmpty) tenantName].join(' · ');

  factory PayableLease.fromMap(String id, Map<String, dynamic> data) {
    double number(dynamic v) => v is num ? v.toDouble() : 0;
    final terms = (data['financialTerms'] as Map?) ?? const {};
    var rent = number(terms['monthlyRent']);
    if (rent <= 0) rent = number(data['monthly_rent']);
    if (rent <= 0) rent = number(data['baseAmount']);
    if (rent <= 0) rent = number(terms['annualRent']) / 12;
    final currency = data['currencyCode'];
    final country = (data['country_code'] as String?)?.toUpperCase();
    return PayableLease(
      id: id,
      propertyId: (data['property_id'] as String?) ?? '',
      propertyTitle: (data['property_title'] as String?) ?? (data['propertyTitle'] as String?) ?? '',
      tenantName: (data['tenant_name'] as String?) ?? (data['tenantName'] as String?) ?? '',
      monthlyRent: rent,
      currencyCode: currency is String && currency.isNotEmpty ? currency : (country == 'EG' ? 'EGP' : 'AED'),
    );
  }
}

class NoActiveLeaseException implements Exception {
  const NoActiveLeaseException();
  @override
  String toString() => 'NoActiveLeaseException';
}

/// Where the owner and agency lease actions read and write. The default talks to Firebase.
abstract class LeasePaymentBackend {
  String? get currentUserId;

  /// 'AgencyAdmin' with the agency id, or null when the user manages leases as an owner.
  Future<String?> currentAgencyId();
  Future<List<PayableLease>> activeLeases({required String field, required String value});
  Future<Map<String, dynamic>> recordManualPayment({
    required String leaseId,
    required String method,
    required String reference,
    required String paidOn,
    required String period,
    required double amount,
  });
  Future<Map<String, dynamic>> sendRentalReminder({required String leaseId, required String dueDate});
}

class FirebaseLeasePaymentBackend implements LeasePaymentBackend {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<String?> currentAgencyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    final agency = claims['agency_id'];
    return claims['role'] == 'AgencyAdmin' && agency is String && agency.isNotEmpty ? agency : null;
  }

  @override
  Future<List<PayableLease>> activeLeases({required String field, required String value}) async {
    final snap = await FirebaseFirestore.instance
        .collection('Leases')
        .where(field, isEqualTo: value)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map((d) => PayableLease.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<Map<String, dynamic>> recordManualPayment({
    required String leaseId,
    required String method,
    required String reference,
    required String paidOn,
    required String period,
    required double amount,
  }) {
    return CloudFunctionsService().recordManualPayment(
      leaseId: leaseId,
      method: method,
      reference: reference,
      paidOn: paidOn,
      period: period,
      amount: amount,
    );
  }

  @override
  Future<Map<String, dynamic>> sendRentalReminder({required String leaseId, required String dueDate}) {
    return CloudFunctionsService().sendRentalReminder(leaseId: leaseId, dueDate: dueDate);
  }
}

/// Owner and agency actions on active leases: manual (cash or bank transfer) payments and reminders.
/// Every action goes through a Cloud Function, and a failed call is thrown, never faked.
class LeasePaymentService {
  LeasePaymentService({LeasePaymentBackend? backend}) : backend = backend ?? FirebaseLeasePaymentBackend();

  static LeasePaymentService instance = LeasePaymentService();

  final LeasePaymentBackend backend;

  /// The signed-in owner's active leases, or the managing agency's for an agency admin.
  Future<List<PayableLease>> activeLeases() async {
    final uid = backend.currentUserId;
    if (uid == null) return const [];
    final agency = await backend.currentAgencyId();
    final leases = agency != null
        ? await backend.activeLeases(field: 'agency_id', value: agency)
        : await backend.activeLeases(field: 'owner_id', value: uid);
    final sorted = [...leases]..sort((a, b) => a.label.compareTo(b.label));
    return sorted;
  }

  Future<Map<String, dynamic>> recordManualPayment({
    required PayableLease lease,
    required String method,
    required String reference,
    required String paidOn,
    required String period,
    required double amount,
  }) {
    return backend.recordManualPayment(
      leaseId: lease.id,
      method: method,
      reference: reference.trim(),
      paidOn: paidOn,
      period: period,
      amount: amount,
    );
  }

  /// Sends the reminder for the active lease on [propertyId]. Throws [NoActiveLeaseException] when
  /// there is none, and the Cloud Function's own error when the call fails.
  Future<void> sendReminderForProperty(String propertyId, {required String dueDate}) async {
    final leases = await activeLeases();
    final match = leases.where((l) => l.propertyId == propertyId).toList();
    if (match.isEmpty) throw const NoActiveLeaseException();
    await backend.sendRentalReminder(leaseId: match.first.id, dueDate: dueDate);
  }
}

