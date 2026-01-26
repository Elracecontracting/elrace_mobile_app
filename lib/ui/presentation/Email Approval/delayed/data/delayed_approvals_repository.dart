import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/models/delayed_approval_model.dart';
import 'package:http/http.dart' as http;

class DelayedApprovalsRepository {
  static const String _baseUrl = 'https://erp.elrace.com/api';
  static const String _delayedApprovalsEndpoint = '/my_delayed_approvals';

  /// Fetches delayed approvals from the API
  Future<DelayedApprovalsResponse> fetchDelayedApprovals() async {
    final token = SharedPref.getLoginData().result?.token;

    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse('$_baseUrl$_delayedApprovalsEndpoint');

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {},
    });

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== DELAYED REQUESTS RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DelayedApprovalsResponse.fromJson(data);
      } else {
        throw Exception('Failed to fetch delayed approvals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delayed approvals: $e');
    }
  }
}
