import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../../../../utils/di.dart';
import '../../../../utils/api_query.dart';
import '../../../../utils/urll_utils.dart';
import '../../signin/data/repository.dart';

final userRepo = sl.get<UserRepo>();

class ContactRepo {
  ApiQuery apiQuery = ApiQuery();

  Future<http.Response> getEmployeeList() async {
    var url = Uri.parse(UrlUtil.baseUrl + UrlUtil.contactApi);

    final loginResponse = await userRepo.getLoginResponse();
    final token = loginResponse?.result?.token;
    if (token == null || token.isEmpty) {
      // Return a synthetic 401-like response to be handled by caller
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "id": null,
        "result": {"status": "error", "message": "Invalid token"}
      });
      return http.Response(body, 401,
          headers: {"content-type": "application/json"});
    }

    Map<String, String> header = {
      "Content-Type": "application/json",
      'Accept': 'application/json',
      "Authorization": "Bearer $token"
    };
    final request = http.Request('GET', url)
      ..headers.addAll(header)
      ..body = jsonEncode({});

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('\n🔵 ========== CONTACTS API RESPONSE ==========');
    print('📡 Status Code: ${response.statusCode}');
    print('📦 Response Length: ${response.body.length} characters');
    print('\n📄 Full Response Body:');

    try {
      final jsonData = jsonDecode(response.body);
      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
      print(prettyJson);

      // Print summary
      if (jsonData['result'] != null &&
          jsonData['result']['employees'] != null) {
        final employees = jsonData['result']['employees'] as List;
        print('\n✅ Total Employees: ${employees.length}');
        if (employees.isNotEmpty) {
          print('\n📋 Sample Employee Data:');
          final firstEmp = employees[0];
          print('  - ID: ${firstEmp['id']}');
          print('  - Name: ${firstEmp['name']}');
          print('  - Emp ID: ${firstEmp['emp_id']}');
          print('  - Job ID: ${firstEmp['job_id']}');
          print('  - Mobile: ${firstEmp['mobile_phone']}');
        }
      }
    } catch (e) {
      print('❌ JSON Parse Error: $e');
      print('Raw Response: ${response.body}');
    }

    print('🔵 ========== END CONTACTS API RESPONSE ==========\n');

    return response;
  }
}
