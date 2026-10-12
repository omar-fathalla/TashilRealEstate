import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Handling background FCM message: ${message.messageId} - ${message.notification?.title}');
}

/// Structured PropTech Push Notification Payload
class TashilNotificationPayload {
  final String id;
  final String title;
  final String body;
  final String type; // 'rent_reminder', 'booking_confirmed', 'maintenance_update', 'contract_ready'
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const TashilNotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.receivedAt,
  });

  factory TashilNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return TashilNotificationPayload(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? (message.data['title'] as String? ?? 'تنبيه جديد'),
      body: message.notification?.body ?? (message.data['body'] as String? ?? ''),
      type: message.data['type'] as String? ?? 'general',
      data: message.data,
      receivedAt: DateTime.now(),
    );
  }
}

/// Enterprise Firebase Cloud Messaging Service for Tashil Real Estate.
/// Handles web push notifications, background handlers, and in-app realtime dispatches.
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _isInitialized = false;

  /// Global notifier of foreground notifications for UI snackbars and badges
  final ValueNotifier<TashilNotificationPayload?> latestNotificationNotifier =
      ValueNotifier<TashilNotificationPayload?>(null);

  String? get fcmToken => _fcmToken;

  /// Initializes FCM listeners, permissions, and handlers
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // 1. Request Notification Permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // 2. Set Background Message Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Obtain Device Push Token
      try {
        _fcmToken = await _messaging!.getToken();
        debugPrint('🔑 FCM Device Token: $_fcmToken');
      } catch (tokenErr) {
        debugPrint('ℹ️ FCM token fetch note (e.g. Web VAPID missing in dev): $tokenErr');
      }

      // 4. Foreground Message Stream
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground notification received: ${message.notification?.title}');
        final payload = TashilNotificationPayload.fromRemoteMessage(message);
        latestNotificationNotifier.value = payload;
      });

      // 5. App Opened via Notification Click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 App opened from notification: ${message.data}');
      });

      _isInitialized = true;
      debugPrint('✅ Firebase Cloud Messaging initialized successfully.');
    } catch (e) {
      debugPrint('ℹ️ FCM initialization note (graceful offline fallback): $e');
      _isInitialized = true;
    }
  }

  /// Subscribes the client to a specific topic (e.g. 'tenants_eg', 'owners_all')
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb || _messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribes from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb || _messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}
