import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;

import '../models/models.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';

/// Service for handling in-app chat notifications
/// Similar to WhatsApp's notification behavior
class ChatNotificationService {
  static ChatNotificationService? _instance;
  static ChatNotificationService get instance =>
      _instance ??= ChatNotificationService._();

  ChatNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Active chat ID - don't show notifications for this chat
  String? _activeChatId;

  // Stream subscriptions for each chat
  final Map<String, StreamSubscription> _chatSubscriptions = {};

  // Last message IDs to prevent duplicate notifications
  final Map<String, String> _lastMessageIds = {};

  // Notification channel for Android
  static const String _channelId = 'chat_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription = 'Notifications for new chat messages';

  // Callback for handling notification taps
  void Function(String chatId, String chatTitle, ChatType chatType)? onNotificationTap;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize with settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    print('✅ ChatNotificationService: Initialized');
  }

  /// Start listening for new messages in user's chats
  Future<void> startListening() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Subscribe to user's chat list
    ChatRepository.instance.subscribeToUserChats(uid).listen((userChats) {
      for (final userChat in userChats) {
        _subscribeToChat(userChat);
      }
    });

    print('✅ ChatNotificationService: Started listening');
  }

  /// Subscribe to a specific chat for new messages
  void _subscribeToChat(UserChat userChat) {
    // Don't re-subscribe if already subscribed
    if (_chatSubscriptions.containsKey(userChat.chatId)) return;

    // Don't notify if muted
    if (userChat.muted) return;

    final subscription = ChatRepository.instance
        .subscribeToMessages(userChat.chatId, pageSize: 1)
        .listen((messages) {
      if (messages.isEmpty) return;

      final latestMessage = messages.first;
      _handleNewMessage(latestMessage, userChat);
    });

    _chatSubscriptions[userChat.chatId] = subscription;
  }

  /// Handle a new message
  Future<void> _handleNewMessage(Message message, UserChat userChat) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Don't notify for own messages
    if (message.senderId == currentUid) return;

    // Don't notify if this chat is currently active
    if (_activeChatId == userChat.chatId) return;

    // Don't notify if we already notified for this message
    if (_lastMessageIds[userChat.chatId] == message.id) return;

    // Check if message is recent (within last 10 seconds)
    final messageAge = DateTime.now().difference(message.createdAt);
    if (messageAge.inSeconds > 10) return;

    _lastMessageIds[userChat.chatId] = message.id;

    // Get sender name
    String senderName = userChat.title ?? 'Unknown';
    if (userChat.type != ChatType.dm) {
      // For group chats, try to get the actual sender name
      final sender = await UserRepository.instance.getUser(message.senderId);
      senderName = sender?.name ?? 'Unknown';
    }

    // Build notification content
    final title = userChat.type == ChatType.dm
        ? senderName
        : '${userChat.title ?? "Group"} • $senderName';

    final body = _getMessagePreview(message);

    // Show notification
    await _showNotification(
      chatId: userChat.chatId,
      title: title,
      body: body,
      chatType: userChat.type,
    );
  }

  /// Get message preview text
  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.text ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 File';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.video:
        return '🎬 Video';
      case MessageType.signableDoc:
        return '📝 Document for signing';
      default:
        return '';
    }
  }

  /// Show a local notification
  Future<void> _showNotification({
    required String chatId,
    required String title,
    required String body,
    required ChatType chatType,
  }) async {
    // Generate unique notification ID from chat ID
    final notificationId = chatId.hashCode;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Payload contains chat info for navigation
    final payload = '$chatId|$title|${chatType.name}';

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );

    print('🔔 ChatNotificationService: Showed notification for $chatId');
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');
    if (parts.length < 3) return;

    final chatId = parts[0];
    final chatTitle = parts[1];
    final chatType = ChatType.fromString(parts[2]);

    print('🔔 ChatNotificationService: Notification tapped - $chatId');

    onNotificationTap?.call(chatId, chatTitle, chatType);
  }

  /// Set the active chat ID (to suppress notifications)
  void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
    print('📱 ChatNotificationService: Active chat set to $chatId');
  }

  /// Cancel notifications for a specific chat
  Future<void> cancelNotificationsForChat(String chatId) async {
    await _notificationsPlugin.cancel(chatId.hashCode);
  }

  /// Update mute status for a chat
  void updateMuteStatus(String chatId, bool muted) {
    if (muted) {
      // Unsubscribe from notifications
      _chatSubscriptions[chatId]?.cancel();
      _chatSubscriptions.remove(chatId);
    }
    // Will re-subscribe on next chat list update if unmuted
  }

  /// Clean up resources
  Future<void> dispose() async {
    for (final subscription in _chatSubscriptions.values) {
      await subscription.cancel();
    }
    _chatSubscriptions.clear();
    _lastMessageIds.clear();
    _activeChatId = null;
    print('✅ ChatNotificationService: Disposed');
  }
}
