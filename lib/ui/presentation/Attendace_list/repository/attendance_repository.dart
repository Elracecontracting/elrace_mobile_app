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
        Uri.parse("https://erp.elrace.com/api/attendance/list"),
        headers: headers,
        body: body,
      );

      debugPrint('getAttendanceSummary: $body \nresponse:${response.body}');

      final decoded = jsonDecode(response.body);
      // Handle error structure {result: {status: 'error', message: 'Invalid token'}}
      final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
      if (result is Map<String, dynamic>) {
        final status = result['status'];
        if (status == 'error') {
          final message = result['message']?.toString() ?? 'Unknown error';
          throw Exception(message);
        }
        // Return summary data calculated from the list
        final data = result['data'] as List? ?? [];
        
        int totalDays = 0;
        int presentDays = 0;
        int absentDays = 0;
        int lateDays = 0;
        double totalHours = 0.0;
        
        for (var item in data) {
          totalDays++;
          final workedHours = (item['worked_hours'] ?? 0.0).toDouble();
          totalHours += workedHours;
          
          if (item['check_out'] == null || item['is_open'] == true) {
            // Still open - count as present but not complete
            presentDays++;
          } else {
            presentDays++;
          }
          
          // Check if late (check_in after 08:15)
          final checkIn = item['check_in'] as String?;
          if (checkIn != null) {
            try {
              final checkInTime = DateTime.parse(checkIn.replaceAll(' ', 'T'));
              final lateThreshold = DateTime(
                checkInTime.year,
                checkInTime.month,
                checkInTime.day,
                8,
                15,
              );
              if (checkInTime.isAfter(lateThreshold)) {
                lateDays++;
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }
        
        absentDays = 0; // We only get present days from the API
        
        return {
          'total_days': totalDays,
          'present_days': presentDays,
          'absent_days': absentDays,
          'late_days': lateDays,
          'total_hours': totalHours,
        };
      }
      throw Exception('Malformed response');
    } catch (e) {
      log("Error in getAttendanceSummary: $e");
      rethrow;
    }
  }
}
