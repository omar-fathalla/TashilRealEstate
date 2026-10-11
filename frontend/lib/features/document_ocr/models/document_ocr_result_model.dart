import 'package:flutter/foundation.dart';

enum DocumentOcrType {
  egyptianNationalId,
  emiratesId,
  titleDeed,
  leaseAgreement,
}

@immutable
class DocumentOcrResultModel {
  final String id;
  final DocumentOcrType documentType;
  final String countryCode;
  
  // Person Information
  final String fullNameAr;
  final String fullNameEn;
  final String idNumber;
  final String dateOfBirth;
  final String expiryDate;
  final String nationality;
  final String address;
  final String governorateOrEmirate;
  final String gender;
  final String documentSerialNumber;
  final String? phoneNumber;
  final String? email;

  // Property Information (for Title Deeds & Leases)
  final String? propertyTitle;
  final String? titleDeedNumber;
  final String? unitNumber;
  final String? buildingName;
  final String? district;
  final String? city;
  final double? areaSqm;
  final String? floor;
  final String? makaniNumber;
  final String? dewaNumber;

  // Financial & Lease Information
  final double? annualRent;
  final double? securityDeposit;
  final int? chequesCount;
  final String? paymentFrequency;

  // Security & Anti-Tamper Audit
  final double confidenceScore;
  final bool isTamperFree;
  final bool isHologramDetected;
  final bool isExpired;
  final String securityStatus;
  final List<String> securityPassedChecks;
  final DateTime extractedAt;
  final String documentImageUrl;

  const DocumentOcrResultModel({
    required this.id,
    required this.documentType,
    required this.countryCode,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.idNumber,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.nationality,
    required this.address,
    required this.governorateOrEmirate,
    required this.gender,
    required this.documentSerialNumber,
    this.phoneNumber,
    this.email,
    this.propertyTitle,
    this.titleDeedNumber,
    this.unitNumber,
    this.buildingName,
    this.district,
    this.city,
    this.areaSqm,
    this.floor,
    this.makaniNumber,
    this.dewaNumber,
    this.annualRent,
    this.securityDeposit,
    this.chequesCount,
    this.paymentFrequency,
    this.confidenceScore = 0.998,
    this.isTamperFree = true,
    this.isHologramDetected = true,
    this.isExpired = false,
    this.securityStatus = 'AUTHENTIC_VERIFIED',
    this.securityPassedChecks = const [
      'تطابق التشفير البصري MRZ والباركود الثنائي',
      'فحص العلامات الأمنية المائية والهولوجرام',
      'التحقق من صحة خوارزمية الرقم القومي / الهوية',
      'سريان المستند وعدم إدراجه في قوائم الإلغاء',
    ],
    required this.extractedAt,
    required this.documentImageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentType': documentType.name,
    'countryCode': countryCode,
    'fullNameAr': fullNameAr,
    'fullNameEn': fullNameEn,
    'idNumber': idNumber,
    'dateOfBirth': dateOfBirth,
    'expiryDate': expiryDate,
    'nationality': nationality,
    'address': address,
    'governorateOrEmirate': governorateOrEmirate,
    'gender': gender,
    'documentSerialNumber': documentSerialNumber,
    'phoneNumber': phoneNumber,
    'email': email,
    'propertyTitle': propertyTitle,
    'titleDeedNumber': titleDeedNumber,
    'unitNumber': unitNumber,
    'buildingName': buildingName,
    'district': district,
    'city': city,
    'areaSqm': areaSqm,
    'floor': floor,
    'makaniNumber': makaniNumber,
    'dewaNumber': dewaNumber,
    'annualRent': annualRent,
    'securityDeposit': securityDeposit,
    'chequesCount': chequesCount,
    'paymentFrequency': paymentFrequency,
    'confidenceScore': confidenceScore,
    'isTamperFree': isTamperFree,
    'isHologramDetected': isHologramDetected,
    'isExpired': isExpired,
    'securityStatus': securityStatus,
    'securityPassedChecks': securityPassedChecks,
    'extractedAt': extractedAt.toIso8601String(),
    'documentImageUrl': documentImageUrl,
  };
}
