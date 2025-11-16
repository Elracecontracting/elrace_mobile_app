import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/attachment_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/partner_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

abstract class ProjectRemoteDataSourceImpl {
  Future<List<ProjectModel>> fetchProjects();
  Future<List<AttachmentModel>> fetchProjectAttachments(String projectId);
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword});
  Future<List<ProjectModel>> fetchProjectsByPartnerId(int partnerId);
}

class ProjectRemoteDataSource implements ProjectRemoteDataSourceImpl {
  Future<List<ProjectModel>> fetchProjects() async {
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://test.elrace.com/api/get_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "keyword": null,
      },
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await request.send();
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
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url =
        Uri.parse("https://test.elrace.com/api/get_project_attachments");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": 13326,
      },
    });

    final response = await http.post(url, headers: headers, body: body);

    debugPrint("fetchProjectAttachments: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['result']['data'];
      return data.map((e) => AttachmentModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load attachments: ${response.statusCode}');
    }
  }

  @override
  Future<List<PartnerModel>> fetchPartnerProjects(
      {int? partnerId, String? keyword}) async {
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://test.elrace.com/api/get_partner_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "partner_id": partnerId,
        "keyword": keyword,
      },
    });

    final response = await http.post(url, headers: headers, body: body);

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
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://test.elrace.com/api/get_partner_projects");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "partner_id": partnerId,
        "keyword": null,
      },
    });

    final response = await http.post(url, headers: headers, body: body);

    debugPrint("fetchProjectsByPartnerId: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
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
      throw Exception(
          'Failed to load projects by partner: ${response.statusCode}');
    }
  }
}
