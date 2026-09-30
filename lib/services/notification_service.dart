import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  NotificationService();

  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _log('NotificationService initialized (stub)');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _log('Local notification: $title - $body');
  }

  Future<void> subscribeToTopic(String topic) async {
    _log('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    _log('Unsubscribed from topic: $topic');
  }

  Future<void> deleteToken() async {
    _fcmToken = null;
    _log('FCM token deleted');
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'NotificationService');
    }
  }
}
