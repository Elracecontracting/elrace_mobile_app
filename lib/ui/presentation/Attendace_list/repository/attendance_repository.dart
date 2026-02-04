import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../../utils/di.dart';
import '../../signin/data/repository.dart';

final userRepo = sl.get<UserRepo>();

class AttendanceRepo {
  Future<http.Response> getAttendanceList({
    String? keyword,
    int? month,
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      final loginResponse = await userRepo.getLoginResponse();
      final token = loginResponse?.result?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Invalid token');
      }

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      var url = Uri.parse("https://erp.elrace.com/api/attendance/list");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "keyword": keyword,
          "limit": limit,
          "offset": offset,
          "month": month,
        }
      });

      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response;
    } catch (e) {
      log('Error in getAttendanceList: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final loginResponse = await userRepo.getLoginResponse();
      final token = loginResponse?.result?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Invalid token');
      }

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "start_date": startDate,
          "end_date": endDate,
        }
      });

      final response = await http.post(
        Uri.parse("https://erp.elrace.com/attendance/summary"),
        headers: headers,
        body: body,
      );

      log('getAttendanceSummary: $body \nresponse:${response.body}');

      final decoded = jsonDecode(response.body);
      // Handle error structure {result: {status: 'error', message: 'Invalid token'}}
      final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
      if (result is Map<String, dynamic>) {
        final status = result['status'];
        if (status == 'error') {
          final message = result['message']?.toString() ?? 'Unknown error';
          throw Exception(message);
        }
        final data = result['data'];
        return data;
      }
      throw Exception('Malformed response');
    } catch (e) {
      log("Error in getAttendanceSummary: $e");
      rethrow;
    }
  }
}
