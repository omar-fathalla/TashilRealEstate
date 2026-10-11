import 'package:flutter/foundation.dart';
import 'viewing_appointment_model.dart';

enum MessageSender {
  user,
  broker,
  system,
}

enum FunctionCallType {
  none,
  bookViewing,
  calculateAffordability,
  inquireFacilities,
}

@immutable
class AffordabilityResult {
  final double propertyPrice;
  final double downPayment;
  final int years;
  final double estimatedMonthlyPayment;
  final double downPaymentPercentage;
  final String affordabilityLevel; // e.g. 'Excellent', 'Comfortable', 'Moderate'

  const AffordabilityResult({
    required this.propertyPrice,
    required this.downPayment,
    required this.years,
    required this.estimatedMonthlyPayment,
    required this.downPaymentPercentage,
    required this.affordabilityLevel,
  });
}

@immutable
class FacilityDistanceResult {
  final String facilityName;
  final String facilityType; // 'metro', 'school', 'hospital', 'mall', 'airport'
  final String distanceKm;
  final String travelTimeMinutes;
  final String description;

  const FacilityDistanceResult({
    required this.facilityName,
    required this.facilityType,
    required this.distanceKm,
    required this.travelTimeMinutes,
    required this.description,
  });
}

@immutable
class VoiceBrokerMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final FunctionCallType functionCallType;
  final ViewingAppointmentModel? appointmentData;
  final AffordabilityResult? affordabilityData;
  final List<FacilityDistanceResult>? facilitiesData;
  final bool isAudioPlaying;

  const VoiceBrokerMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.functionCallType = FunctionCallType.none,
    this.appointmentData,
    this.affordabilityData,
    this.facilitiesData,
    this.isAudioPlaying = false,
  });

  VoiceBrokerMessage copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    DateTime? timestamp,
    FunctionCallType? functionCallType,
    ViewingAppointmentModel? appointmentData,
    AffordabilityResult? affordabilityData,
    List<FacilityDistanceResult>? facilitiesData,
    bool? isAudioPlaying,
  }) {
    return VoiceBrokerMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      functionCallType: functionCallType ?? this.functionCallType,
      appointmentData: appointmentData ?? this.appointmentData,
      affordabilityData: affordabilityData ?? this.affordabilityData,
      facilitiesData: facilitiesData ?? this.facilitiesData,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
    );
  }
}
