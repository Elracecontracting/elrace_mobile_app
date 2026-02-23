import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/models/delayed_approval_model.dart';
import 'package:http/http.dart' as http;

class DelayedApprovalsRepository {
  static const String _baseUrl = 'https://erp.elrace.com/api';

  Map<String, String> _buildHeaders(String token) => {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

  String _requireToken() {
    final token = SharedPref.getLoginData().result?.token;
    if (token == null || token.isEmpty) throw Exception('User not authenticated');
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

      print('=== DELAYED COUNTERS RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('=================================');

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

      print('=== DELAYED DETAILS RESPONSE ($type) ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('=========================================');

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

      print('=== DELAYED ALL RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================');

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

  // ─────────────────────────────────────────────────────────────
  // Legacy method – kept for backward compatibility.
  // Calls the old single endpoint (now maps to /all).
  // ─────────────────────────────────────────────────────────────
  @Deprecated('Use fetchCounters() for dashboard and fetchDetails(type) on tap.')
  Future<DelayedApprovalsResponse> fetchDelayedApprovals() => fetchAll();
}
