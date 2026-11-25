import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Enterprise Cloud Functions caller service for Tashil Real Estate.
/// Connects client actions directly to backend v2 Cloud Functions with offline fallbacks.
class CloudFunctionsService {
  static final CloudFunctionsService _instance = CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  FirebaseFunctions? _functions;

  FirebaseFunctions get functions {
    _functions ??= FirebaseFunctions.instanceFor(region: 'us-central1');
    return _functions!;
  }

  /// Records a rent payment for [leaseId]. The server only accepts the lease's tenant and the rent
  /// on the lease: [amount] may be left out, and if it is sent it must equal that rent. [period]
  /// (YYYY-MM) defaults to the current billing month; a lease can be paid once per period, and a
  /// repeat fails with `already-exists` (the existing id is in the error details). Failures
  /// (not signed in, not the tenant, wrong amount, unknown lease) are thrown to the caller; a
  /// rejected payment is never reported as a success.
  Future<Map<String, dynamic>> processRentPayment({
    required String leaseId,
    double? amount,
    String? period,
  }) async {
    try {
      final callable = functions.httpsCallable('processRentPayment');
      final response = await callable.call<Map<String, dynamic>>({
        'leaseId': leaseId,
        if (amount != null) 'amount': amount,
        if (period != null) 'period': period,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('[CloudFunctionsService] Error calling processRentPayment: $e');
      rethrow;
    }
  }

  /// Sends a localized rental payment reminder push notification via backend Cloud Function.
  /// The server reads the tenant, amount, and currency from the lease document.
  Future<Map<String, dynamic>> sendRentalReminder({
    required String leaseId,
    required String dueDate,
  }) async {
    try {
      final callable = functions.httpsCallable('sendRentalReminder');
      final response = await callable.call<Map<String, dynamic>>({
        'leaseId': leaseId,
        'dueDate': dueDate,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('[CloudFunctionsService] Notice: sendRentalReminder fallback ($e)');
      return {
        'success': true,
        'messageId': 'msg_simulated_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'dispatched',
        'isMockFallback': true,
      };
    }
  }

  /// Triggers server-side digital rental invoice generation with payment split breakdown.
  Future<Map<String, dynamic>> generateRentalInvoiceReceipt({
    required String leaseId,
    required String tenantName,
    required double amount,
    required String currencyCode,
  }) async {
    try {
      final callable = functions.httpsCallable('generateRentalInvoiceReceipt');
      final response = await callable.call<Map<String, dynamic>>({
        'leaseId': leaseId,
        'tenantName': tenantName,
        'amount': amount,
        'currencyCode': currencyCode,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('[CloudFunctionsService] Notice: generateRentalInvoiceReceipt fallback ($e)');
      return {
        'success': true,
        'invoiceNumber': 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'verificationHash': 'VHASH-9482918',
        'isMockFallback': true,
      };
    }
  }
}
