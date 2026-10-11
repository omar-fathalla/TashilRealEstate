import 'package:flutter/foundation.dart';
import '../models/viewing_appointment_model.dart';

class ViewingAppointmentsService {
  static final ViewingAppointmentsService _instance = ViewingAppointmentsService._internal();
  factory ViewingAppointmentsService() => _instance;

  ViewingAppointmentsService._internal() {
    _initSeedAppointments();
  }

  final ValueNotifier<List<ViewingAppointmentModel>> appointmentsNotifier =
      ValueNotifier<List<ViewingAppointmentModel>>([]);

  void _initSeedAppointments() {
    appointmentsNotifier.value = [
      ViewingAppointmentModel(
        id: 'viewing_eg_101',
        propertyId: 'prop_eg_1',
        propertyTitle: 'شقة فاخرة بالتجمع الخامس - شارع التسعين',
        clientName: 'أحمد محمود القاضي',
        clientPhone: '+201012345678',
        scheduledDateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
        status: ViewingStatus.confirmed,
        notes: 'العميل مهتم بالمعاينة المسائية بعد مواعيد العمل ومعه أسرته.',
        countryCode: 'EG',
        bookedBy: 'gemini_voice_broker',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ViewingAppointmentModel(
        id: 'viewing_ae_202',
        propertyId: 'prop_ae_1',
        propertyTitle: 'Luxury 2BR in Dubai Marina with Sea View',
        clientName: 'Rashid Al Nuaimi',
        clientPhone: '+971501234567',
        scheduledDateTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
        status: ViewingStatus.confirmed,
        notes: 'Client wants to inspect parking access and balcony view over the marina.',
        countryCode: 'AE',
        bookedBy: 'gemini_voice_broker',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  /// Book a new viewing appointment (e.g. called from Gemini Function Calling or UI Dialog)
  Future<ViewingAppointmentModel> bookAppointment({
    required String propertyId,
    required String propertyTitle,
    required String clientName,
    required String clientPhone,
    required DateTime scheduledDateTime,
    required String countryCode,
    String notes = '',
    String bookedBy = 'gemini_voice_broker',
  }) async {
    final appointment = ViewingAppointmentModel(
      id: 'viewing_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      clientName: clientName,
      clientPhone: clientPhone,
      scheduledDateTime: scheduledDateTime,
      status: ViewingStatus.confirmed,
      notes: notes,
      countryCode: countryCode,
      bookedBy: bookedBy,
      createdAt: DateTime.now(),
    );

    final current = List<ViewingAppointmentModel>.from(appointmentsNotifier.value);
    current.insert(0, appointment);
    appointmentsNotifier.value = current;

    debugPrint('🗓️ [ViewingAppointmentsService] New viewing appointment saved: ${appointment.id} for $clientName');
    return appointment;
  }

  List<ViewingAppointmentModel> getAppointmentsForProperty(String propertyId) {
    return appointmentsNotifier.value.where((a) => a.propertyId == propertyId).toList();
  }

  List<ViewingAppointmentModel> getAppointmentsForCountry(String countryCode) {
    return appointmentsNotifier.value.where((a) => a.countryCode == countryCode).toList();
  }
}
