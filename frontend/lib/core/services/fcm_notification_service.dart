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

/// Outcome of asking the user to turn on notifications.
enum NotificationEnableResult { granted, denied, unsupported, timedOut, failed }

/// Enterprise Firebase Cloud Messaging Service for Tashil Real Estate.
/// Handles web push notifications, background handlers, and in-app realtime dispatches.
///
/// Startup never asks for notification permission: browsers (Firefox in particular) hold the
/// page until the prompt is answered, and Firefox only shows it after a user gesture anyway.
/// [initialize] only attaches listeners; [requestPermissionAndRegister] is called from a tap.
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  static const Duration setupTimeout = Duration(seconds: 5);
  static const Duration promptTimeout = Duration(seconds: 60);
  static const Duration tokenTimeout = Duration(seconds: 10);

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _isInitialized = false;

  /// Global notifier of foreground notifications for UI snackbars and badges
  final ValueNotifier<TashilNotificationPayload?> latestNotificationNotifier =
      ValueNotifier<TashilNotificationPayload?>(null);

  /// Result of the last [requestPermissionAndRegister] call, null until the user asked.
  final ValueNotifier<NotificationEnableResult?> enableResultNotifier =
      ValueNotifier<NotificationEnableResult?>(null);

  @visibleForTesting
  Future<bool> Function()? isSupportedOverride;

  @visibleForTesting
  Future<AuthorizationStatus> Function()? requestPermissionOverride;

  @visibleForTesting
  Future<String?> Function()? getTokenOverride;

  @visibleForTesting
  void resetForTest() {
    _isInitialized = false;
    _fcmToken = null;
    enableResultNotifier.value = null;
    isSupportedOverride = null;
    requestPermissionOverride = null;
    getTokenOverride = null;
  }

  String? get fcmToken => _fcmToken;

  /// Attaches message listeners. Never prompts, never throws, and gives up after
  /// [setupTimeout], so an unsupported browser (Safari without push, private mode) cannot
  /// hold up startup.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _attachListeners().timeout(setupTimeout);
      debugPrint('✅ Firebase Cloud Messaging listeners attached (permission not requested).');
    } catch (e) {
      debugPrint('ℹ️ FCM initialization note (graceful fallback): $e');
    }
  }

  Future<void> _attachListeners() async {
    _messaging = FirebaseMessaging.instance;
    if (!await _supported()) {
      debugPrint('ℹ️ FCM is not supported in this browser.');
      return;
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground notification received: ${message.notification?.title}');
      latestNotificationNotifier.value = TashilNotificationPayload.fromRemoteMessage(message);
    }, onError: (Object e) => debugPrint('ℹ️ FCM foreground stream note: $e'));

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 App opened from notification: ${message.data}');
    }, onError: (Object e) => debugPrint('ℹ️ FCM opened-app stream note: $e'));
  }

  Future<bool> _supported() async {
    if (isSupportedOverride != null) return isSupportedOverride!();
    if (!kIsWeb) return true;
    return _messaging!.isSupported();
  }

  /// Asks for notification permission and fetches the push token. Call it only from a user
  /// gesture (a button tap). Always completes: a denied permission, an unsupported browser,
  /// a prompt that is never answered, or any error is reported as a result, never thrown.
  Future<NotificationEnableResult> requestPermissionAndRegister() async {
    final result = await _requestPermissionAndRegister();
    enableResultNotifier.value = result;
    return result;
  }

  Future<NotificationEnableResult> _requestPermissionAndRegister() async {
    try {
      _messaging ??= requestPermissionOverride == null ? FirebaseMessaging.instance : null;
      if (!await _supported().timeout(setupTimeout)) return NotificationEnableResult.unsupported;

      final status = await (requestPermissionOverride?.call() ??
              _messaging!
                  .requestPermission(alert: true, badge: true, sound: true)
                  .then((settings) => settings.authorizationStatus))
          .timeout(promptTimeout);
      debugPrint('🔔 FCM Permission status: $status');
      if (status != AuthorizationStatus.authorized && status != AuthorizationStatus.provisional) {
        return NotificationEnableResult.denied;
      }

      try {
        _fcmToken = await (getTokenOverride?.call() ?? _messaging!.getToken()).timeout(tokenTimeout);
      } catch (tokenErr) {
        debugPrint('ℹ️ FCM token fetch note (e.g. Web VAPID missing in dev): $tokenErr');
      }
      return NotificationEnableResult.granted;
    } on TimeoutException {
      return NotificationEnableResult.timedOut;
    } catch (e) {
      debugPrint('ℹ️ FCM permission note: $e');
      return NotificationEnableResult.failed;
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
