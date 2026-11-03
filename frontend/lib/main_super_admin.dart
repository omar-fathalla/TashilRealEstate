import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/firebase_options.dart';
import 'package:tashil_real_estate/core/services/app_check_service.dart';
import 'package:tashil_real_estate/core/services/remote_config_service.dart';
import 'package:tashil_real_estate/core/services/fcm_notification_service.dart';
import 'package:tashil_real_estate/core/services/performance_monitoring_service.dart';
import 'package:tashil_real_estate/core/services/crash_reporting_service.dart';
import 'package:tashil_real_estate/core/config/firebase_emulator.dart';
import 'package:tashil_real_estate/main.dart';

/// Dedicated standalone entry point for the Tashil Real Estate Super Admin Portal.
/// Directly boots into the Super Admin Portal and management dashboard (/admin -> /super-admin).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known upstream Flutter Web engine assertions:
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    if (exceptionStr.contains('PointerDeviceKind.trackpad') ||
        (details.library == 'gestures library' && exceptionStr.contains('identical(kind, PointerDeviceKind.trackpad)')) ||
        exceptionStr.contains('EngineFlutterView') ||
        exceptionStr.contains('disposed EngineFlutterView')) {
      return;
    }
    CrashReportingService().recordFlutterError(details);
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final errStr = error.toString();
    if (errStr.contains('PointerDeviceKind.trackpad') ||
        errStr.contains('EngineFlutterView') ||
        errStr.contains('disposed EngineFlutterView')) {
      return true;
    }
    CrashReportingService().recordError(error, stack, fatal: true);
    return false;
  };

  if (FirebaseEmulatorConfig.enabled) {
    await FirebaseEmulatorConfig.prepareBeforeInitializeApp();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (FirebaseEmulatorConfig.enabled) {
    await FirebaseEmulatorConfig.connect();
  } else {
    CrashReportingService().initialize();
    unawaited(AppCheckService().initialize());
    unawaited(RemoteConfigService().initialize());
    unawaited(FcmNotificationService().initialize());
    unawaited(PerformanceMonitoringService().initialize());
  }

  // Launch Tashil Real Estate App with Super Admin router initialLocation: '/admin'
  runApp(TashilRealEstateApp(routerConfig: superAdminAppRouter));
}
