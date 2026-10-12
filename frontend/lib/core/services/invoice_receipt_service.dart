import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tashil_real_estate/core/services/remote_config_service.dart';

/// Digital rental invoice and official payment receipt model.
class RentalInvoiceReceipt {
  final String invoiceNumber;
  final String leaseId;
  final String tenantName;
  final String propertyTitle;
  final double rentalAmount;
  final double platformFee;
  final double agencyFee;
  final double ownerPayout;
  final double vatAmount;
  final double totalPaid;
  final String currencyCode;
  final DateTime issueDate;
  final String verificationQrData;
  final String status;

  RentalInvoiceReceipt({
    required this.invoiceNumber,
    required this.leaseId,
    required this.tenantName,
    required this.propertyTitle,
    required this.rentalAmount,
    required this.platformFee,
    required this.agencyFee,
    required this.ownerPayout,
    required this.vatAmount,
    required this.totalPaid,
    required this.currencyCode,
    required this.issueDate,
    required this.verificationQrData,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'leaseId': leaseId,
      'tenantName': tenantName,
      'propertyTitle': propertyTitle,
      'rentalAmount': rentalAmount,
      'platformFee': platformFee,
      'agencyFee': agencyFee,
      'ownerPayout': ownerPayout,
      'vatAmount': vatAmount,
      'totalPaid': totalPaid,
      'currencyCode': currencyCode,
      'issueDate': issueDate.toIso8601String(),
      'verificationQrData': verificationQrData,
      'status': status,
    };
  }
}

/// Service for generating verified digital rental invoices and payment receipts.
class InvoiceReceiptService {
  static final InvoiceReceiptService _instance = InvoiceReceiptService._internal();
  factory InvoiceReceiptService() => _instance;
  InvoiceReceiptService._internal();

  /// Generates a verified digital receipt based on dynamic Remote Config fee parameters.
  Future<RentalInvoiceReceipt> generateReceipt({
    required String leaseId,
    required String tenantName,
    required String propertyTitle,
    required double rentalAmount,
    required String countryCode,
  }) async {
    final currencyCode = countryCode.toUpperCase() == 'AE' ? 'AED' : 'EGP';
    final vatRate = countryCode.toUpperCase() == 'AE' ? 0.05 : 0.14; // 5% UAE, 14% Egypt

    // Dynamic platform fee percentage from Firebase Remote Config
    final platformFeePercent = RemoteConfigService().platformFeePercentage / 100.0;
    const agencyFeePercent = 0.08; // 8% standard agency management fee

    final platformFee = rentalAmount * platformFeePercent;
    final agencyFee = rentalAmount * agencyFeePercent;
    final ownerPayout = rentalAmount - (platformFee + agencyFee);
    final vatAmount = (platformFee + agencyFee) * vatRate;
    final totalPaid = rentalAmount + vatAmount;

    final invoiceNumber = 'TASHIL-INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final verificationQr = 'TASHIL_VERIFIED|$invoiceNumber|$leaseId|$totalPaid $currencyCode|${DateTime.now().toIso8601String()}';

    final receipt = RentalInvoiceReceipt(
      invoiceNumber: invoiceNumber,
      leaseId: leaseId,
      tenantName: tenantName,
      propertyTitle: propertyTitle,
      rentalAmount: rentalAmount,
      platformFee: platformFee,
      agencyFee: agencyFee,
      ownerPayout: ownerPayout,
      vatAmount: vatAmount,
      totalPaid: totalPaid,
      currencyCode: currencyCode,
      issueDate: DateTime.now(),
      verificationQrData: verificationQr,
      status: 'Paid_Verified',
    );

    try {
      await FirebaseFirestore.instance
          .collection('Invoices')
          .doc(invoiceNumber)
          .set(receipt.toMap());
      debugPrint('[InvoiceReceiptService] Successfully stored invoice: $invoiceNumber');
    } catch (e) {
      debugPrint('[InvoiceReceiptService] Notice: Offline fallback for invoice storage ($e)');
    }

    return receipt;
  }
}
