import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/attachment_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/partner_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_projects_response.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/folder_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

abstract class ProjectRemoteDataSourceImpl {
  Future<List<ProjectModel>> fetchProjects();
  Future<List<AttachmentModel>> fetchProjectAttachments(String projectId);
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword});
  Future<List<ProjectModel>> fetchProjectsByPartnerId(int partnerId);
  Future<List<FolderModel>> fetchProjectFolders();
  Future<UserProjectsResponse> fetchUserProjects();
}

class ProjectRemoteDataSource implements ProjectRemoteDataSourceImpl {
  ProjectRemoteDataSource({
    http.Client? client,
    String Function()? getToken,
  })  : _client = client ?? http.Client(),
        _getToken = getToken ?? _defaultGetToken;

  final http.Client _client;
  final String Function() _getToken;

  static String _defaultGetToken() {
    return SharedPref.getLoginData().result?.token ?? '';
  }

  @override
  Future<List<ProjectModel>> fetchProjects() async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/get_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "keyword": null,
      },
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("fetchProjects: ${request.url} \n${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['result']['data'];
      return data.map((e) => ProjectModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load projects: ${response.statusCode}');
    }
  }

  Future<List<AttachmentModel>> fetchProjectAttachments(
      String projectId) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/get_project_attachments");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": int.tryParse(projectId) ?? 0,
      },
    });

    final response = await _client.post(url, headers: headers, body: body);

    debugPrint("fetchProjectAttachments: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Check for success status
      if (decoded['result'] != null &&
          decoded['result']['status'] == 'success' &&
          decoded['result']['data'] != null) {
        final List data = decoded['result']['data'];
        return data.map((e) => AttachmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load attachments: ${response.statusCode}');
    }
  }

  @override
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword}) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/get_partner_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "partner_id": partnerId,
        "keyword": keyword,
      },
    });

    final response = await _client.post(url, headers: headers, body: body);

    debugPrint("fetchPartnerProjects: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['result']['data'];
      return data.map((e) => PartnerModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load partner projects: ${response.statusCode}');
    }
  }

  @override
  Future<List<ProjectModel>> fetchProjectsByPartnerId(int partnerId) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/get_partner_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "partner_id": partnerId,
        "keyword": null,
      },
    });

    final response = await _client.post(url, headers: headers, body: body);

    debugPrint("fetchProjectsByPartnerId: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Check if the response has the expected structure
      if (decoded['result'] != null &&
          decoded['result']['status'] == 'success' &&
          decoded['result']['data'] != null) {
        final List data = decoded['result']['data'];

        // Extract projects from the partner data
        List<ProjectModel> allProjects = [];
        for (var partnerData in data) {
          final projectsList = partnerData['projects'] as List<dynamic>? ?? [];
          for (var projectJson in projectsList) {
            allProjects.add(ProjectModel.fromJson(projectJson));
          }
        }

        return allProjects;
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception(
          'Failed to load projects by partner: ${response.statusCode}');
    }
  }

  Future<List<FolderModel>> fetchProjectFolders() async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/project_folders");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "id": null,
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("fetchProjectFolders: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['result'] != null &&
          decoded['result']['status'] == 'success' &&
          decoded['result']['data'] != null) {
        final List data = decoded['result']['data'];
        return data.map((e) => FolderModel.fromJson(e)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load folders: ${response.statusCode}');
    }
  }

  @override
  Future<UserProjectsResponse> fetchUserProjects() async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/user/projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {},
    });

    debugPrint("=== fetchUserProjects REQUEST ===");
    debugPrint("URL: $url");
    debugPrint("Method: GET");
    debugPrint("Headers: $headers");
    debugPrint("Body: $body");
    debugPrint(
        "Token (first 20 chars): ${token.length > 20 ? token.substring(0, 20) : token}...");
    debugPrint("===================================");

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("=== fetchUserProjects RESPONSE ===");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Headers: ${response.headers}");
    debugPrint("Response Body: ${response.body}");
    debugPrint("Body Length: ${response.body.length}");
    debugPrint("===================================");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;

      if (result != null && result['success'] == true) {
        final projectsJson = result['projects'] as List<dynamic>? ?? [];
        final projects =
            projectsJson.map((e) => UserProjectModel.fromJson(e)).toList();

        return UserProjectsResponse(
          success: true,
          employeeId: result['employee_id'] as int? ?? 0,
          projects: projects,
        );
      }

      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to load user projects: ${response.statusCode}');
    }
  }
}
