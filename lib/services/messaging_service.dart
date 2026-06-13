import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../widgets/notification_toast.dart';

/// Handles Firebase Cloud Messaging (FCM) for web push notifications.
/// On web, this powers browser push notifications that work even when
/// the tab is in the background.
class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> init() async {
    // Request permission (required on iOS and macOS, recommended for web)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      // User denied notifications — do nothing silently
      return;
    }

    // Get FCM token and save to Firestore
    await _registerToken();

    // Handle foreground messages (show in-app toast)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification tap when app is in background (opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Check if app was opened from a terminated state via a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessagePayload(initialMessage);
    }

    // Refresh token whenever it rotates
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(newToken));
  }

  // ─── Token Management ─────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      String? token;
      if (kIsWeb) {
        // On web, you need your VAPID public key from Firebase Console
        // Firebase > Project Settings > Cloud Messaging > Web Push certificates
        token = await _messaging.getToken(
          vapidKey: const String.fromEnvironment(
            'FCM_VAPID_KEY',
            defaultValue: '',
          ),
        );
      } else {
        token = await _messaging.getToken();
      }
      if (token != null) await _saveToken(token);
    } catch (e) {
      // Silently fail — non-critical
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Message Handlers ─────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    // When the app is open, show an in-app toast instead of a system notification
    _handleMessagePayload(message);
  }

  void _onNotificationTap(RemoteMessage message) {
    // App was opened via a background notification tap
    _handleMessagePayload(message);
  }

  void _handleMessagePayload(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? 'info';

    ToastType toastType;
    switch (type) {
      case 'achievement':
        toastType = ToastType.achievement;
        break;
      case 'warning':
        toastType = ToastType.warning;
        break;
      case 'success':
        toastType = ToastType.success;
        break;
      default:
        toastType = ToastType.info;
    }

    ToastController().show(
      ToastMessage(
        title: notification.title ?? 'TaskMate',
        body: notification.body ?? '',
        type: toastType,
      ),
    );
  }

  // ─── Manual Push Helpers ──────────────────────────────────────────────────

  /// Call this when user earns a badge to fire a local in-app toast.
  void notifyBadgeEarned(List<String> badgeNames) {
    if (badgeNames.isEmpty) return;
    final badgeText = badgeNames.length == 1
        ? badgeNames.first
        : '${badgeNames.length} new badges';
    ToastController().showAchievement(
      'Badge Earned',
      'You unlocked: $badgeText',
    );
  }

  /// Call this when user levels up.
  void notifyLevelUp(int newLevel) {
    ToastController().showAchievement(
      'Level Up',
      'You reached Level $newLevel. Keep it up!',
    );
  }

  /// Call this when a task is completed.
  void notifyTaskCompleted(String taskName) {
    ToastController().showSuccess('Task Complete', taskName);
  }

  /// Call this when Pomodoro session ends.
  void notifyPomodoroEnd({bool isBreak = false}) {
    if (isBreak) {
      ToastController().showInfo(
        'Break Time',
        'Take a short break — you earned it.',
      );
    } else {
      ToastController().showSuccess(
        'Session Complete',
        'Great focus. Ready for a break?',
      );
    }
  }
}
