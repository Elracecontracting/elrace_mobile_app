import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/models/delayed_approval_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DelayedAllPageResult {
  final DelayedApprovalsResponse data;
  final int currentPage;
  final int? nextPage;
  final bool hasMore;

  const DelayedAllPageResult({
    required this.data,
    required this.currentPage,
    required this.nextPage,
    required this.hasMore,
  });
}

class DelayedApprovalsRepository {
  static const String _baseUrl = 'https://erp.elrace.com/api';

  Map<String, String> _buildHeaders(String token) => {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

  String _requireToken() {
    final token = SharedPref.getLoginData().result?.token;
    if (token == null || token.isEmpty)
      throw Exception('User not authenticated');
    return token;
  }

  // ─────────────────────────────────────────────────────────────
  // 1. COUNTERS  →  /api/my_delayed_approvals/counters
  //    Very fast – use for dashboard badge and tab counts.
  // ─────────────────────────────────────────────────────────────
  Future<DelayedCountersResponse> fetchCounters() async {
    final token = _requireToken();
    final url = Uri.parse('$_baseUrl/my_delayed_approvals/counters');

    final body = jsonEncode({"jsonrpc": "2.0", "params": {}});

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(_buildHeaders(token))
        ..body = body;

      final response = await http.Response.fromStream(await request.send());

      if (kDebugMode) {
        debugPrint(
            'DELAYED COUNTERS status=${response.statusCode} bytes=${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DelayedCountersResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to fetch delayed counters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delayed counters: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. DETAILS  →  /api/my_delayed_approvals/details?type=hr|rfq|invoice|petty_cash
  //    Load on user tap – returns records for the selected category only.
  // ─────────────────────────────────────────────────────────────
  Future<DelayedDetailsResponse> fetchDetails(String type) async {
    final token = _requireToken();
    final url = Uri.parse('$_baseUrl/my_delayed_approvals/details')
        .replace(queryParameters: {'type': type});

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {"type": type},
    });

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(_buildHeaders(token))
        ..body = body;

      final response = await http.Response.fromStream(await request.send());

      if (kDebugMode) {
        debugPrint(
            'DELAYED DETAILS($type) status=${response.statusCode} bytes=${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DelayedDetailsResponse.fromJson(data, type);
      } else {
        throw Exception(
            'Failed to fetch delayed details for $type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delayed details for $type: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. ALL  →  /api/my_delayed_approvals/all
  //    Optional – avoid unless absolutely necessary.
  // ─────────────────────────────────────────────────────────────
  Future<DelayedApprovalsResponse> fetchAll() async {
    final token = _requireToken();
    final url = Uri.parse('$_baseUrl/my_delayed_approvals/all');

    final body = jsonEncode({"jsonrpc": "2.0", "params": {}});

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(_buildHeaders(token))
        ..body = body;

      final response = await http.Response.fromStream(await request.send());

      if (kDebugMode) {
        debugPrint(
            'DELAYED ALL status=${response.statusCode} bytes=${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DelayedApprovalsResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to fetch all delayed approvals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all delayed approvals: $e');
    }
  }

  /// Paginated fetch from /api/my_delayed_approvals/all.
  ///
  /// Sends common pagination keys in both query params and request body to
  /// match backend variants without breaking existing behavior.
  Future<DelayedAllPageResult> fetchAllPage({
    required int page,
    int pageSize = 20,
  }) async {
    final token = _requireToken();
    final url = Uri.parse('$_baseUrl/my_delayed_approvals/all').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$pageSize',
        'per_page': '$pageSize',
      },
    );

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "page": page,
        "limit": pageSize,
        "per_page": pageSize,
        "page_size": pageSize,
      }
    });

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(_buildHeaders(token))
        ..body = body;

      final response = await http.Response.fromStream(await request.send());

      if (kDebugMode) {
        debugPrint(
            'DELAYED ALL PAGED status=${response.statusCode} page=$page pageSize=$pageSize bytes=${response.body.length}');
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch delayed approvals page $page: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final parsed = DelayedApprovalsResponse.fromJson(json);

      final result = json['result'];
      final resultMap =
          result is Map<String, dynamic> ? result : <String, dynamic>{};
      final meta = _extractPaginationMeta(resultMap);

      final currentPage =
          _readInt(meta, const ['current_page', 'page'], fallback: page);
      final totalPages = _readInt(meta, const ['total_pages', 'last_page']);
      final explicitNextPage = _readNullableInt(meta, const ['next_page']);
      final explicitHasMore = _readBool(meta, const ['has_more', 'has_next']);

      final bool hasMore;
      if (explicitHasMore != null) {
        hasMore = explicitHasMore;
      } else if (explicitNextPage != null) {
        hasMore = explicitNextPage > currentPage;
      } else if (totalPages > 0) {
        hasMore = currentPage < totalPages;
      } else {
        // Fallback when metadata is missing.
        hasMore = parsed.totalCount >= pageSize;
      }

      final nextPage = explicitNextPage ?? (hasMore ? currentPage + 1 : null);

      return DelayedAllPageResult(
        data: parsed,
        currentPage: currentPage,
        nextPage: nextPage,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Error fetching delayed approvals page $page: $e');
    }
  }

  Map<String, dynamic> _extractPaginationMeta(Map<String, dynamic> resultMap) {
    final directMeta = resultMap['pagination'];
    if (directMeta is Map<String, dynamic>) return directMeta;

    final directMeta2 = resultMap['meta'];
    if (directMeta2 is Map<String, dynamic>) return directMeta2;

    final data = resultMap['data'];
    if (data is Map<String, dynamic>) {
      final nestedPagination = data['pagination'];
      if (nestedPagination is Map<String, dynamic>) return nestedPagination;

      final nestedMeta = data['meta'];
      if (nestedMeta is Map<String, dynamic>) return nestedMeta;

      return data;
    }

    return resultMap;
  }

  int _readInt(Map<String, dynamic> source, List<String> keys,
      {int fallback = 0}) {
    final value = _readNullableInt(source, keys);
    return value ?? fallback;
  }

  int? _readNullableInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Legacy method – kept for backward compatibility.
  // Calls the old single endpoint (now maps to /all).
  // ─────────────────────────────────────────────────────────────
  @Deprecated(
      'Use fetchCounters() for dashboard and fetchDetails(type) on tap.')
  Future<DelayedApprovalsResponse> fetchDelayedApprovals() => fetchAll();
}
