import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/attachment_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/partner_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_projects_response.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/folder_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_document_item_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

abstract class ProjectRemoteDataSourceImpl {
  Future<List<ProjectModel>> fetchProjects();
  Future<List<AttachmentModel>> fetchProjectAttachments(String projectId,
      {String? folderType});
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword});
  Future<List<ProjectModel>> fetchProjectsByPartnerId(int partnerId);
  Future<List<FolderModel>> fetchProjectFolders();
  Future<UserProjectsResponse> fetchClientsList();
  Future<ProjectDocumentsResponse> fetchProjectDocuments(int projectId,
      {String? folderType});
  Future<FolderContentsResponse> fetchFolderContents(
      int projectId, String folderId);
  Future<FileDetailsResponse> fetchFileDetails(int projectId, String fileId);
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

  @override
  Future<List<AttachmentModel>> fetchProjectAttachments(String projectId,
      {String? folderType}) async {
    debugPrint("🔶 fetchProjectAttachments CALLED with projectId: $projectId, folderType: $folderType");
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/get_project_attachments");

    // Build params with optional folder_type
    final params = <String, dynamic>{
      "project_id": int.tryParse(projectId) ?? 0,
    };
    if (folderType != null) {
      params["folder_type"] = folderType;
    }

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": params,
    });

    debugPrint("===============================");
    debugPrint("fetchProjectAttachments REQUEST:");
    debugPrint("URL: $url");
    debugPrint("Body: $body");
    debugPrint("===============================");

    final response = await _client.post(url, headers: headers, body: body);

    debugPrint("fetchProjectAttachments RESPONSE: ${response.statusCode}");
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

  @override
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
  Future<UserProjectsResponse> fetchClientsList() async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/clients/list");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {},
    });

    debugPrint("=== fetchClientsList REQUEST ===");
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

    debugPrint("=== fetchClientsList RESPONSE ===");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Headers: ${response.headers}");
    debugPrint("Response Body: ${response.body}");
    debugPrint("Body Length: ${response.body.length}");
    debugPrint("===================================");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;

      if (result != null && result['status'] == 'success') {
        final clientsJson = result['data'] as List<dynamic>? ?? [];
        final projects =
            clientsJson.map((e) => UserProjectModel.fromJson(e)).toList();

        return UserProjectsResponse(
          success: true,
          employeeId: 0,
          projects: projects,
        );
      }

      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to load clients list: ${response.statusCode}');
    }
  }

  @override
  Future<ProjectDocumentsResponse> fetchProjectDocuments(int projectId,
      {String? folderType}) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/projects/documents");

    // Only include folder_type if provided
    final params = <String, dynamic>{
      "project_id": projectId,
    };
    if (folderType != null) {
      params["folder_type"] = folderType;
    }

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": params,
    });

    debugPrint("===============================");
    debugPrint("fetchProjectDocuments REQUEST:");
    debugPrint("URL: $url");
    debugPrint("Body: $body");
    debugPrint("===============================");

    // Use GET request with body
    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("fetchProjectDocuments RESPONSE: ${response.statusCode}");
    debugPrint("fetchProjectDocuments: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return ProjectDocumentsResponse.fromJson(decoded);
    } else {
      throw Exception(
          'Failed to load project documents: ${response.statusCode}');
    }
  }

  @override
  Future<FolderContentsResponse> fetchFolderContents(
      int projectId, String folderId) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/projects/documents/folder");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": projectId,
        "folder_id": folderId,
      },
    });

    debugPrint("===============================");
    debugPrint("fetchFolderContents REQUEST:");
    debugPrint("URL: $url");
    debugPrint("Body: $body");
    debugPrint("===============================");

    // Use GET request with body
    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("fetchFolderContents RESPONSE: ${response.statusCode}");
    debugPrint("fetchFolderContents: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return FolderContentsResponse.fromJson(decoded);
    } else {
      throw Exception('Failed to load folder contents: ${response.statusCode}');
    }
  }

  @override
  Future<FileDetailsResponse> fetchFileDetails(
      int projectId, String fileId) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/projects/documents/file");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": projectId,
        "file_id": fileId,
      },
    });

    debugPrint("===============================");
    debugPrint("fetchFileDetails REQUEST:");
    debugPrint("URL: $url");
    debugPrint("Body: $body");
    debugPrint("===============================");

    // Use GET request with body
    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("fetchFileDetails RESPONSE: ${response.statusCode}");
    debugPrint("fetchFileDetails: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return FileDetailsResponse.fromJson(decoded);
    } else {
      throw Exception('Failed to load file details: ${response.statusCode}');
    }
  }
}
