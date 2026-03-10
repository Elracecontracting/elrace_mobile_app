import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:http/http.dart' as http;

class NotificationApiResult {
  final List<Map<String, dynamic>> notifications;
  final int? unreadCount;

  const NotificationApiResult({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationApiService {
  static const String _baseUrl = 'https://erp.elrace.com/api';

  static Map<String, String> _headers() {
    final token = SharedPref.getLoginData().result?.token ?? '';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static bool _looksSuccessful(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    if (response.body.trim().isEmpty) {
      return true;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'];
        if (success is bool) return success;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<NotificationApiResult> getNotifications({
    int page = 1,
    int perPage = 50,
    String category = 'all',
    bool unreadOnly = false,
  }) async {
    final uri = Uri.parse('$_baseUrl/notifications').replace(
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        'category': category,
        'unread_only': unreadOnly ? 'true' : 'false',
      },
    );

    final response = await http.get(uri, headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid notifications response format');
    }

    dynamic data = decoded['data'];
    if (data == null && decoded['result'] is Map<String, dynamic>) {
      data = (decoded['result'] as Map<String, dynamic>)['data'] ??
          decoded['result'];
    }

    List<dynamic> rawNotifications = const [];
    int? unreadCount;

    if (data is Map<String, dynamic>) {
      final notificationsValue =
          data['notifications'] ?? data['items'] ?? data['data'];
      if (notificationsValue is List) {
        rawNotifications = notificationsValue;
      }
      unreadCount = _toIntOrNull(data['unread_count']);
    } else if (decoded['notifications'] is List) {
      rawNotifications = decoded['notifications'] as List<dynamic>;
    }

    unreadCount ??= _toIntOrNull(decoded['unread_count']);

    final notifications = rawNotifications
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
        .toList();

    return NotificationApiResult(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  static Future<int?> getUnreadCount() async {
    final uri = Uri.parse('$_baseUrl/notifications/unread-count');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch unread count: ${response.statusCode}');
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final direct = _toIntOrNull(decoded['unread_count']);
    if (direct != null) return direct;

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return _toIntOrNull(data['unread_count']);
    }

    return null;
  }

  static Future<bool> markAsRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return false;

    final attempts = <Future<http.Response>>[
      http.put(
        Uri.parse('$_baseUrl/notifications/read'),
        headers: _headers(),
        body: jsonEncode({'id': id}),
      ),
      http.post(
        Uri.parse('$_baseUrl/notifications/read'),
        headers: _headers(),
        body: jsonEncode({'id': id}),
      ),
      http.put(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: _headers(),
      ),
      http.post(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: _headers(),
      ),
    ];

    for (final attempt in attempts) {
      try {
        final response = await attempt;
        if (_looksSuccessful(response)) {
          return true;
        }
      } catch (_) {
        // Try next endpoint shape
      }
    }

    return false;
  }

  static Future<bool> markAllAsRead() async {
    final attempts = <Future<http.Response>>[
      http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: _headers(),
      ),
      http.put(
        Uri.parse('$_baseUrl/notifications/read'),
        headers: _headers(),
        body: jsonEncode({'all': true}),
      ),
    ];

    for (final attempt in attempts) {
      try {
        final response = await attempt;
        if (_looksSuccessful(response)) {
          return true;
        }
      } catch (_) {
        // Try next endpoint shape
      }
    }

    return false;
  }
}
