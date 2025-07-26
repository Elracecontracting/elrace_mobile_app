import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../utils/di.dart';
import '../../signin/data/repository.dart';

final userRepo = sl.get<UserRepo>();

class AttendanceRepo {
  Future<http.Response> getAttendanceList({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final loginResponse = await userRepo.getLoginResponse();
      var token = loginResponse!.result!.token!;

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      var url = Uri.parse("https://test.elrace.com/attendance/filter-by-date");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "start_date": startDate,
          "end_date": endDate,
        }
      });

      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      // ✅ Properly send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Optionally log
      log('Attendance API Response: ${response.statusCode}');
      log('Response body: ${response.body}');

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
      var token = loginResponse!.result!.token!;

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
        Uri.parse("https://test.elrace.com/attendance/summary"),
        headers: headers,
        body: body,
      );

      debugPrint('getAttendanceSummary: ${body} \nresponse:${response.body}');

      final json = jsonDecode(response.body);
      return json['result']['data'];
    } catch (e) {
      log("Error in getAttendanceSummary: $e");
      rethrow;
    }
  }

}
