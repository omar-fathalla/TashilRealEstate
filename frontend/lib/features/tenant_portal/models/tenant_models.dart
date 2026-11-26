import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _text(dynamic value) => value is String ? value : '';

double _number(dynamic value) => value is num ? value.toDouble() : 0;

Map<String, String> _texts(dynamic value) => {
      for (final e in ((value as Map?) ?? const {}).entries) e.key.toString(): _text(e.value),
    };

const leaseStatuses = ['draft', 'pending_tenant_approval', 'active', 'expired', 'terminated', 'rejected'];

/// A lease the signed-in user rents (`Leases/{id}` where `tenant_id` is the user).
class TenantLease {
  final String id;
  final String status;
  final String propertyTitle;
  final double monthlyRent;
  final String currencyCode;
  final String startDate;
  final String endDate;
  final String ownerId;

  const TenantLease({
    required this.id,
    this.status = 'draft',
    this.propertyTitle = '',
    this.monthlyRent = 0,
    this.currencyCode = 'AED',
    this.startDate = '',
    this.endDate = '',
    this.ownerId = '',
  });

  bool get isOffer => status == 'pending_tenant_approval';
  bool get isActive => status == 'active';

  /// Drafts are the owner's work in progress and are never shown to the tenant.
  bool get visibleToTenant => status != 'draft' && leaseStatuses.contains(status);

  factory TenantLease.fromMap(String id, Map<String, dynamic> data) {
    final terms = (data['financialTerms'] as Map?) ?? const {};
    var rent = _number(terms['monthlyRent']);
    if (rent <= 0) rent = _number(data['monthly_rent']);
    if (rent <= 0) rent = _number(data['baseAmount']);
    if (rent <= 0) rent = _number(terms['annualRent']) / 12;
    final currency = _text(data['currencyCode']);
    final country = _text(data['country_code']).toUpperCase();
    return TenantLease(
      id: id,
      status: _text(data['status']).isEmpty ? 'draft' : _text(data['status']),
      propertyTitle: _text(data['property_title']).isNotEmpty ? _text(data['property_title']) : _text(data['propertyTitle']),
      monthlyRent: rent,
      currencyCode: currency.isNotEmpty ? currency : (country == 'EG' ? 'EGP' : 'AED'),
      startDate: _text(data['start_date']),
      endDate: _text(data['end_date']),
      ownerId: _text(data['owner_id']),
    );
  }
}

/// A payment attempt or payment (`Transactions/{leaseId}_{YYYY-MM}`, written only by the server).
class TenantTransaction {
  final String id;
  final String leaseId;
  final String period;
  final double amount;
  final String currencyCode;
  final String status;
  final String invoiceNumber;
  final DateTime? paidAt;

  const TenantTransaction({
    required this.id,
    this.leaseId = '',
    this.period = '',
    this.amount = 0,
    this.currencyCode = 'AED',
    this.status = 'pending',
    this.invoiceNumber = '',
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory TenantTransaction.fromMap(String id, Map<String, dynamic> data) {
    return TenantTransaction(
      id: id,
      leaseId: _text(data['leaseId']),
      period: _text(data['period']),
      amount: _number(data['amount']),
      currencyCode: _text(data['currencyCode']).isEmpty ? 'AED' : _text(data['currencyCode']),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      invoiceNumber: _text(data['invoiceNumber']),
      paidAt: _date(data['paidAt']),
    );
  }
}

/// A receipt (`Invoices/{invoiceNumber}`, issued by the server when a payment is paid or recorded).
class TenantInvoice {
  final String invoiceNumber;
  final String transactionId;
  final String period;
  final double totalPaid;
  final String currencyCode;
  final String status;
  final String paymentMethod;
  final String paymentReference;
  final DateTime? createdAt;

  const TenantInvoice({
    required this.invoiceNumber,
    this.transactionId = '',
    this.period = '',
    this.totalPaid = 0,
    this.currencyCode = 'AED',
    this.status = '',
    this.paymentMethod = '',
    this.paymentReference = '',
    this.createdAt,
  });

  factory TenantInvoice.fromMap(String id, Map<String, dynamic> data) {
    return TenantInvoice(
      invoiceNumber: _text(data['invoiceNumber']).isEmpty ? id : _text(data['invoiceNumber']),
      transactionId: _text(data['transactionId']),
      period: _text(data['period']),
      totalPaid: _number(data['totalPaid']),
      currencyCode: _text(data['currencyCode']).isEmpty ? 'AED' : _text(data['currencyCode']),
      status: _text(data['status']),
      paymentMethod: _text(data['paymentMethod']),
      paymentReference: _text(data['paymentReference']),
      createdAt: _date(data['createdAt']),
    );
  }
}

/// A message for the user (`Users/{uid}/notifications/{id}`), written by the server.
class TenantNotification {
  final String id;
  final String type;
  final Map<String, String> title;
  final Map<String, String> body;
  final bool read;
  final DateTime? createdAt;

  const TenantNotification({
    required this.id,
    this.type = '',
    this.title = const {},
    this.body = const {},
    this.read = false,
    this.createdAt,
  });

  String titleFor(String lang) => title[lang]?.isNotEmpty == true ? title[lang]! : (title['en'] ?? title['ar'] ?? '');
  String bodyFor(String lang) => body[lang]?.isNotEmpty == true ? body[lang]! : (body['en'] ?? body['ar'] ?? '');

  factory TenantNotification.fromMap(String id, Map<String, dynamic> data) {
    return TenantNotification(
      id: id,
      type: _text(data['type']),
      title: _texts(data['title']),
      body: _texts(data['body']),
      read: data['read'] == true,
      createdAt: _date(data['createdAt']),
    );
  }
}
