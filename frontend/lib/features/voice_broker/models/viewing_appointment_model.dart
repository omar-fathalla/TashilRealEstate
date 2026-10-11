import 'package:flutter/foundation.dart';

enum ViewingStatus {
  confirmed,
  pending,
  completed,
  cancelled,
}

@immutable
class ViewingAppointmentModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String clientName;
  final String clientPhone;
  final DateTime scheduledDateTime;
  final ViewingStatus status;
  final String notes;
  final String countryCode;
  final String bookedBy; // e.g., 'gemini_voice_broker', 'portal_form'
  final DateTime createdAt;

  const ViewingAppointmentModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.clientName,
    required this.clientPhone,
    required this.scheduledDateTime,
    this.status = ViewingStatus.confirmed,
    this.notes = '',
    required this.countryCode,
    this.bookedBy = 'gemini_voice_broker',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'client_name': clientName,
        'client_phone': clientPhone,
        'scheduled_datetime': scheduledDateTime.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'country_code': countryCode,
        'booked_by': bookedBy,
        'created_at': createdAt.toIso8601String(),
      };

  factory ViewingAppointmentModel.fromJson(Map<String, dynamic> json) {
    return ViewingAppointmentModel(
      id: json['id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      propertyTitle: json['property_title'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String? ?? '',
      scheduledDateTime: json['scheduled_datetime'] != null
          ? DateTime.tryParse(json['scheduled_datetime'] as String) ?? DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      status: ViewingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ViewingStatus.confirmed,
      ),
      notes: json['notes'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'EG',
      bookedBy: json['booked_by'] as String? ?? 'gemini_voice_broker',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ViewingAppointmentModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? clientName,
    String? clientPhone,
    DateTime? scheduledDateTime,
    ViewingStatus? status,
    String? notes,
    String? countryCode,
    String? bookedBy,
    DateTime? createdAt,
  }) {
    return ViewingAppointmentModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      countryCode: countryCode ?? this.countryCode,
      bookedBy: bookedBy ?? this.bookedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
