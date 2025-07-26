import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/widgets/horizontal_slider_widget.dart';

class CustomSwipeButtonRepo{
  static Future<List<Project>> fetchProjects() async {
    String? token = SharedPref.getLoginData().result?.token;

    // 🔁 Fallback if token is missing
    if (token == null || token.isEmpty) {
      final storedData = SharedPref().getPreferenceString('LOGIN_RESPONSE');

      final jsonData = jsonDecode(storedData);
      final storedLoginResponse = LoginResponseModel.fromJson(jsonData);
      print(storedLoginResponse);
      token = storedLoginResponse.result?.token;
      print("🔁 Fallback token loaded from SharedPreferences: $token");
        }

    // 🚫 Still missing token?
    if (token == null || token.isEmpty) {
      throw Exception("No valid session. Token is missing.");
    }

    try {
      final url = Uri.parse("https://test.elrace.com/api/get_projects");
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {},
      });

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📡 Response: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['data'] is List) {
          final List projectsData = data['result']['data'];
          return projectsData.map((json) => Project.fromJson(json)).toList();
        } else {
          throw Exception("Project list is missing or invalid.");
        }
      } else {
        throw Exception("Failed to load projects: ${response.statusCode}");
      }
    } catch (e) {
      print('⚠️ Error in _fetchProjects: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> validateUserLocation(int projectId, double latitude, double longitude) async {
    final token = SharedPref.getLoginData().result?.token;

    final url = Uri.parse("https://test.elrace.com/api/validate_user_location");

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": projectId,
        "check_in_lat": latitude,
        "check_in_long": longitude,
        "office": null
      }
    });
    print(body);
    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);
      return data['result'];
    } catch (e) {
      return {"status": "error", "message": "Failed to validate location: $e"};
    }
  }

}