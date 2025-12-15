import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorageService {
  static const String _notificationsKey = 'stored_notifications';
  static const String _unreadCountKey = 'unread_notification_count';

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
      List<Map<String, dynamic>> notifications = await getNotifications();

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
      final jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);

      // Update unread count
      await _updateUnreadCount();

      print('✅ Notification saved: $title');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Get all notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
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

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications = await getNotifications();

      // Find and update the notification
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;

        // Save updated list
        final jsonString = jsonEncode(notifications);
        await prefs.setString(_notificationsKey, jsonString);

        // Update unread count
        await _updateUnreadCount();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications = await getNotifications();

      // Mark all as read
      for (var notification in notifications) {
        notification['isRead'] = true;
      }

      // Save updated list
      final jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);

      // Update unread count
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
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
      final count = await getUnreadCount();
      await prefs.setInt(_unreadCountKey, count);
    } catch (e) {
      print('❌ Error updating unread count: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notifications = await getNotifications();

      // Remove the notification
      notifications.removeWhere((n) => n['id'] == notificationId);

      // Save updated list
      final jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);

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
