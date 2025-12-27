import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:http/http.dart' as http;

class ApprovalCountService {
  static Future<int> getTotalApprovalCount() async {
    try {
      final token = SharedPref.getLoginData().result?.token;
      if (token == null || token.isEmpty) {
        return 0;
      }

      // Fetch counts from all categories in parallel
      final results = await Future.wait([
        _fetchCategoryCount("hr", token),
        _fetchCategoryCount("rfq", token),
        _fetchCategoryCount("invoice", token),
        _fetchCategoryCount("petty_cash", token),
      ]);

      // Sum all counts
      final totalCount = results.reduce((a, b) => a + b);
      print(
          '📊 Total approval count: $totalCount (HR: ${results[0]}, RFQ: ${results[1]}, Invoice: ${results[2]}, Petty Cash: ${results[3]})');
      return totalCount;
    } catch (e) {
      print('❌ Error getting approval count: $e');
      return 0;
    }
  }

  static Future<int> _fetchCategoryCount(String category, String token) async {
    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = Uri.parse("https://test.elrace.com/api/my_approvals_grouped");

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "group_type": category,
        },
      });

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final response = await request.send().timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        final result = jsonData['result'];

        if (result != null && result['data'] != null) {
          // Map the category to the actual response key
          const Map<String, String> responseKeys = {
            "hr": "human_resources",
            "rfq": "rfq",
            "invoice": "invoices",
            "petty_cash": "petty_cash",
          };

          final actualKey = responseKeys[category] ?? category;
          final data = result['data'][actualKey];

          if (data is List) {
            return data.length;
          }
        }
      }
      return 0;
    } catch (e) {
      print('⚠️ Error fetching $category count: $e');
      return 0;
    }
  }
}
