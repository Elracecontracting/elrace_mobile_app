import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:el_race/core/services/notification_api_service.dart';

class NotificationStorageService {
  static const String _notificationsKey = 'stored_notifications';
  static const String _unreadCountKey = 'unread_notification_count';

  /// Callback to notify when notification count changes
  static void Function()? onCountChanged;

  /// Save a new notification
  static Future<void> saveNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? category, // 'notification', 'announcement', 'circular'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      List<Map<String, dynamic>> notifications =
          await _getStoredNotifications();

      // Determine category from data or default to 'notification'
      String notificationCategory =
          category ?? data?['category'] ?? data?['type'] ?? 'notification';

      // Create new notification
      final newNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'category': notificationCategory.toLowerCase(),
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      }; // Add to beginning of list
      notifications.insert(0, newNotification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      // Save to preferences
      await _saveStoredNotifications(notifications, prefs);

      // Update unread count
      await _updateUnreadCount();

      print('✅ Notification saved: $title');

      // Notify listeners that count changed
      onCountChanged?.call();
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Get all notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final localNotifications = await _getStoredNotifications();

      final apiResult = await NotificationApiService.getNotifications(
        page: 1,
        perPage: 100,
        category: 'all',
        unreadOnly: false,
      );

      final normalized = apiResult.notifications
          .map(_normalizeApiNotification)
          .toList(growable: false);

      final prefs = await SharedPreferences.getInstance();
      await _saveStoredNotifications(normalized, prefs);

      if (apiResult.unreadCount != null) {
        await prefs.setInt(_unreadCountKey, apiResult.unreadCount!);
      } else {
        await _updateUnreadCount();
      }

      return normalized;
    } catch (e) {
      print('⚠️ Notification API unavailable, using local cache: $e');
      return _getStoredNotifications();
    }
  }

  static Map<String, dynamic> _normalizeApiNotification(
      Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    dynamic notificationData = raw['data'];
    if (notificationData is String && notificationData.trim().isNotEmpty) {
      try {
        notificationData = jsonDecode(notificationData);
      } catch (_) {
        // Keep original string when backend sends non-JSON content.
      }
    }

    final rawRead = raw['is_read'] ?? raw['isRead'] ?? false;
    final isRead = rawRead == true ||
        rawRead == 1 ||
        rawRead.toString().toLowerCase() == 'true';

    normalized['id'] =
        (raw['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    normalized['title'] =
        (raw['title'] ?? raw['subject'] ?? 'Notification').toString();
    normalized['body'] = (raw['body'] ?? raw['message'] ?? '').toString();
    normalized['imageUrl'] = raw['image_url'] ?? raw['imageUrl'];
    normalized['data'] = notificationData;
    normalized['category'] = (raw['category'] ?? raw['type'] ?? 'notification')
        .toString()
        .toLowerCase();
    normalized['timestamp'] = (raw['created_at'] ??
            raw['timestamp'] ??
            DateTime.now().toIso8601String())
        .toString();
    normalized['isRead'] = isRead;
    normalized['readAt'] = raw['read_at'] ?? raw['readAt'];

    return normalized;
  }

  static Future<List<Map<String, dynamic>>> _getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  static Future<void> _saveStoredNotifications(
    List<Map<String, dynamic>> notifications,
    SharedPreferences prefs,
  ) async {
    final jsonString = jsonEncode(notifications);
    await prefs.setString(_notificationsKey, jsonString);
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications =
          await _getStoredNotifications();

      // Find and update the notification
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications[index]['readAt'] = DateTime.now().toIso8601String();

        // Save updated list
        await _saveStoredNotifications(notifications, prefs);

        // Update unread count
        await _updateUnreadCount();

        // Notify listeners that count changed
        onCountChanged?.call();
      }

      final remoteOk = await NotificationApiService.markAsRead(notificationId);
      if (!remoteOk) {
        print('⚠️ Notification marked read locally, remote API call failed.');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications =
          await _getStoredNotifications();

      // Mark all as read
      for (var notification in notifications) {
        notification['isRead'] = true;
      }

      // Save updated list
      await _saveStoredNotifications(notifications, prefs);

      // Update unread count
      await prefs.setInt(_unreadCountKey, 0);

      // Notify listeners that count changed
      onCountChanged?.call();

      final remoteOk = await NotificationApiService.markAllAsRead();
      if (!remoteOk) {
        print('⚠️ Notifications marked read locally, remote API call failed.');
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final apiUnreadCount = await NotificationApiService.getUnreadCount();
      if (apiUnreadCount != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_unreadCountKey, apiUnreadCount);
        return apiUnreadCount;
      }
    } catch (e) {
      print('⚠️ Error getting unread count from API, fallback to local: $e');
    }

    try {
      final notifications = await _getStoredNotifications();
      return notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Update unread count in preferences
  static Future<void> _updateUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await _getStoredNotifications();
      final count = notifications.where((n) => n['isRead'] == false).length;
      await prefs.setInt(_unreadCountKey, count);
    } catch (e) {
      print('❌ Error updating unread count: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications =
          await _getStoredNotifications();

      // Remove the notification
      notifications.removeWhere((n) => n['id'] == notificationId);

      // Save updated list
      await _saveStoredNotifications(notifications, prefs);

      // Update unread count
      await _updateUnreadCount();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Get notifications by category
  static Future<List<Map<String, dynamic>>> getNotificationsByCategory(
      String category) async {
    try {
      final allNotifications = await getNotifications();
      if (category.toLowerCase() == 'all') {
        return allNotifications;
      }
      return allNotifications
          .where((notification) =>
              (notification['category'] ?? 'notification')
                  .toString()
                  .toLowerCase() ==
              category.toLowerCase())
          .toList();
    } catch (e) {
      print('❌ Error getting notifications by category: $e');
      return [];
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.setInt(_unreadCountKey, 0);
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Add sample notifications for testing (different categories)
  static Future<void> addSampleNotifications() async {
    try {
      // Sample notification
      await saveNotification(
        title: 'Leave Approved',
        body: 'Your leave request from Jan 15 to Jan 20 has been approved.',
        category: 'notification',
      );

      await saveNotification(
        title: 'Attendance Reminder',
        body: 'Please ensure to check in before 9:00 AM.',
        category: 'notification',
      );

      // Sample announcement
      await saveNotification(
        title: 'New Project Launch',
        body:
            'We are excited to announce the launch of Abu Dhabi Dialysis Center project.',
        category: 'announcement',
      );

      await saveNotification(
        title: 'Company Meeting',
        body: 'All staff meeting scheduled for tomorrow at 10:00 AM.',
        category: 'announcement',
      );

      // Sample circular
      await saveNotification(
        title: 'Safety Guidelines',
        body:
            'Please review the updated safety guidelines for construction sites.',
        category: 'circular',
      );

      await saveNotification(
        title: 'Policy Update',
        body:
            'New HR policies effective from next month. Please read carefully.',
        category: 'circular',
      );

      print('✅ Sample notifications added successfully');
    } catch (e) {
      print('❌ Error adding sample notifications: $e');
    }
  }
}
