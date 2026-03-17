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

      log('Attendance API request -> POST $url');
      log('Attendance API request body -> $body');

      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('Attendance API response status -> ${response.statusCode}');
      log('Attendance API response body -> ${response.body}');

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

  Future<Map<String, dynamic>> getTodayStatus() async {
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
        "params": {},
      });

      final response = await http.post(
        Uri.parse("https://erp.elrace.com/api/attendance/today_status"),
        headers: headers,
        body: body,
      );

      log('getTodayStatus: $body \nresponse:${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch today status: HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Malformed response');
      }

      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw Exception('Malformed response result');
      }

      final status = result['status']?.toString();
      if (status == 'error') {
        final message = result['message']?.toString() ?? 'Unknown error';
        throw Exception(message);
      }

      final rawData = (result['data'] is Map<String, dynamic>)
          ? result['data'] as Map<String, dynamic>
          : result;

      return {
        'checked_in': _toBool(rawData['checked_in']),
        'checked_out': _toBool(rawData['checked_out']),
        'check_in_time': rawData['check_in_time']?.toString(),
        'check_out_time': rawData['check_out_time']?.toString(),
        'is_today': _toBool(rawData['is_today']),
      };
    } catch (e) {
      log("Error in getTodayStatus: $e");
      rethrow;
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value == null) {
      return false;
    }

    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }
}
