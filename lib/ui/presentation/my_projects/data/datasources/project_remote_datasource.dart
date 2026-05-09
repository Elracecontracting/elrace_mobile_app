import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/attachment_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/partner_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_expense_dashboard_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_financial_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_scurve_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_manager_filter_item.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_projects_response.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/folder_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_document_item_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:el_race/utils/urll_utils.dart';

abstract class ProjectRemoteDataSourceImpl {
  Future<List<ProjectModel>> fetchProjects();
  Future<List<AttachmentModel>> fetchProjectAttachments(String projectId,
      {String? folderType});
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword});
  Future<List<ProjectModel>> fetchProjectsByPartnerId(int partnerId);
  Future<List<ProjectModel>> fetchProjectsByFilters({
    int? agreementId,
    int? partnerId,
    int? projectManagerId,
    int? cityId,
    String? keyword,
  });
  Future<List<FolderModel>> fetchProjectFolders();
  Future<UserProjectsResponse> fetchClientsList();
  Future<List<ProjectManagerFilterItem>> fetchProjectManagersList();
  Future<List<ProjectManagerFilterItem>> fetchClientsGroupedList(
      {required String groupBy});
  Future<ProjectDocumentsResponse> fetchProjectDocuments(int projectId,
      {String? folderType});
  Future<FolderContentsResponse> fetchFolderContents(
      int projectId, String folderId);
  Future<FileDetailsResponse> fetchFileDetails(int projectId, String fileId);
  Future<ProjectScurveData> fetchProjectScurve(
    int projectId, {
    int rangeStart = 1,
    int rangeSize = 50,
  });
  Future<ProjectExpenseDashboardModel> fetchProjectExpenseDashboard(int projectId);
  Future<ProjectFinancialModel> fetchProjectFinancialData(
    int projectId, {
    String? dateFrom,
    String? dateTo,
  });
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

    final url = Uri.parse("${UrlUtil.baseUrl}get_projects");

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
    debugPrint(
        "🔶 fetchProjectAttachments CALLED with projectId: $projectId, folderType: $folderType");
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("${UrlUtil.baseUrl}get_project_attachments");

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

    final url = Uri.parse("${UrlUtil.baseUrl}get_partner_projects");

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
    return fetchProjectsByFilters(partnerId: partnerId);
  }

  @override
  Future<List<ProjectModel>> fetchProjectsByFilters({
    int? agreementId,
    int? partnerId,
    int? projectManagerId,
    int? cityId,
    String? keyword,
  }) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("${UrlUtil.baseUrl}get_partner_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "agreement": agreementId,
        "agreement_id": agreementId,
        "partner_id": partnerId,
        "project_manager_id": projectManagerId,
        "city_id": cityId,
        "keyword": keyword,
      },
    });

    final response = await _client.post(url, headers: headers, body: body);

    debugPrint("fetchProjectsByFilters: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['result'] != null &&
          decoded['result']['status'] == 'success' &&
          decoded['result']['data'] != null) {
        final List data = decoded['result']['data'];

        final List<ProjectModel> allProjects = [];
        for (final partnerData in data) {
          if (partnerData is! Map) continue;

          final partnerMap = Map<String, dynamic>.from(partnerData);
          final projectsList = partnerMap['projects'];
          if (projectsList is List) {
            for (final projectJson in projectsList) {
              if (projectJson is Map<String, dynamic>) {
                allProjects.add(ProjectModel.fromJson(projectJson));
              } else if (projectJson is Map) {
                allProjects.add(ProjectModel.fromJson(
                    Map<String, dynamic>.from(projectJson)));
              }
            }
          } else if (partnerMap.containsKey('project_id')) {
            allProjects.add(ProjectModel.fromJson(partnerMap));
          }
        }

        return allProjects;
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception(
          'Failed to load filtered projects: ${response.statusCode}');
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

    final url = Uri.parse("${UrlUtil.baseUrl}project_folders");

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

    final url = Uri.parse("${UrlUtil.baseUrl}clients/list");

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
  Future<List<ProjectManagerFilterItem>> fetchProjectManagersList() async {
    return fetchClientsGroupedList(groupBy: 'project_manager');
  }

  @override
  Future<List<ProjectManagerFilterItem>> fetchClientsGroupedList(
      {required String groupBy}) async {
    final token = _getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("${UrlUtil.baseUrl}clients/list");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "group_by": groupBy,
      },
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to load grouped clients: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final result = decoded['result'] as Map<String, dynamic>?;
    if (result == null || result['status'] != 'success') {
      throw Exception('Invalid grouped clients response format');
    }

    final list = (result['data'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) =>
            ProjectManagerFilterItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    return list;
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

    final url = Uri.parse("${UrlUtil.baseUrl}projects/documents");

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

    final url =
        Uri.parse("${UrlUtil.baseUrl}projects/documents/folder");

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

    final url = Uri.parse("${UrlUtil.baseUrl}projects/documents/file");

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

  @override
  Future<ProjectScurveData> fetchProjectScurve(
    int projectId, {
    int rangeStart = 1,
    int rangeSize = 500,
  }) async {
    final token = _getToken();
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    const endpoint = "${UrlUtil.baseUrl}project/scurve";
    final url = Uri.parse(endpoint);
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": null,
        "params": {
          "project_id": projectId,
          "range_start": rangeStart,
          "range_size": rangeSize,
        },
      }),
    );
    debugPrint("fetchProjectScurve [$endpoint]: ${response.statusCode}");
    debugPrint("fetchProjectScurve body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Failed to load project analytics (${response.statusCode})');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final result = decoded['result'] as Map<String, dynamic>?;
    if (result == null) {
      return ProjectScurveData.empty();
    }
    if (result['status'] != 'success' || result['data'] == null) {
      return ProjectScurveData.empty(
        projectName: result['project']?.toString() ?? '',
      );
    }

    var data = ProjectScurveData.fromJson(
      (result['data'] as Map).cast<String, dynamic>(),
    );

    // Ensure we fetch all weeks, not only the default window.
    final totalWeeks = data.totalWeeks;
    if (totalWeeks > data.series.length) {
      final fullResponse = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": null,
          "params": {
            "project_id": projectId,
            "range_start": 1,
            "range_size": totalWeeks,
          },
        }),
      );
      if (fullResponse.statusCode == 200) {
        final fullDecoded = json.decode(fullResponse.body) as Map<String, dynamic>;
        final fullResult = fullDecoded['result'] as Map<String, dynamic>?;
        if (fullResult != null &&
            fullResult['status'] == 'success' &&
            fullResult['data'] != null) {
          data = ProjectScurveData.fromJson(
            (fullResult['data'] as Map).cast<String, dynamic>(),
          );
        }
      }
    }

    return data;
  }

  @override
  Future<ProjectExpenseDashboardModel> fetchProjectExpenseDashboard(
    int projectId,
  ) async {
    final token = _getToken();
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    const endpoint = "${UrlUtil.baseUrl}project/expense/dashboard";
    final response = await _client.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": null,
        "params": {
          "project_id": projectId,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load expense dashboard (${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final result = decoded['result'] as Map<String, dynamic>?;
    if (result == null || result['status'] != 'success') {
      throw Exception(
        result?['message']?.toString() ?? 'Invalid expense dashboard response',
      );
    }
    final payload = result['data'] is Map
        ? (result['data'] as Map).cast<String, dynamic>()
        : result;
    return ProjectExpenseDashboardModel.fromJson(
      payload,
    );
  }

  @override
  Future<ProjectFinancialModel> fetchProjectFinancialData(
    int projectId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    final token = _getToken();
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    final params = <String, dynamic>{"project_id": projectId};
    if ((dateFrom ?? '').isNotEmpty && (dateTo ?? '').isNotEmpty) {
      params['date_from'] = dateFrom;
      params['date_to'] = dateTo;
    }

    const endpoint = "${UrlUtil.baseUrl}project/financial";
    final response = await _client.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": null,
        "params": params,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load financial statement (${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final result = decoded['result'] as Map<String, dynamic>?;
    if (result == null || result['status'] != 'success') {
      throw Exception(
        result?['message']?.toString() ?? 'Invalid financial statement response',
      );
    }
    final payload = result['data'] is Map
        ? (result['data'] as Map).cast<String, dynamic>()
        : result;
    return ProjectFinancialModel.fromJson(
      payload,
    );
  }
}
