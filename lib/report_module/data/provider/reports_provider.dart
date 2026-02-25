import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/models/report_pdf_model.dart';
import 'package:el_race/report_module/data/services/report_hive_service.dart';
import 'package:el_race/ui/presentation/call_screen/data/repository.dart';
import 'package:flutter/foundation.dart';
import 'package:el_race/main.dart';
import 'package:el_race/report_module/core/utils/flush_bar.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';

ReportProvider reportProvider =
    Provider.of<ReportProvider>(navKey.currentContext!, listen: false);

class ReportProvider extends ChangeNotifier {
  static String baseUrl = "";
  static String empID = "";
  static String companyId = "";

  List<FolderModel> _folders = [];
  List<ReportModel> _reports = [];

  bool _isLoading = false;

  List<ReportModel> get reports => _reports;
  List<FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;

  Future<void> init({required String base}) async {
    baseUrl = base;
    empID =
        (await userRepo.getLoginResponse())!.result!.data!.emp_id.toString();
    companyId =
        (await userRepo.getLoginResponse())!.result!.data!.companyId.toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _handleResponse(http.StreamedResponse response,
      {bool alwaysShowMessage = false, bool neverShowMessage = false}) async {
    final res = await response.stream.bytesToString();
    final jsonData = json.decode(res);

    if (jsonData is Map && jsonData['status'] == "upcoming") {
      if (!neverShowMessage) {
        showFlushBar(navKey.currentContext!, message: jsonData['message']);
      }
      return {};
    }

    if (!neverShowMessage &&
        (alwaysShowMessage ||
            (jsonData is Map && jsonData['status'] != "success"))) {
      showFlushBar(navKey.currentContext!, message: jsonData['message']);
    }
    if (jsonData is List) {
      return {"data": jsonData};
    }

    return jsonData;
  }

  Future<void> createFolder(
      {required String title, String description = ""}) async {
    _setLoading(true);
    var request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/create_report_folder'))
      ..fields.addAll({
        'emp_id': empID,
        'folder_name': title,
        'description': description,
        'company_id': companyId,
        'report_id': "1", //todo remove
        'company': "test" //todo remove
      });
    // print(companyId);
    final jsonData = await _handleResponse(await request.send());
    // print(jsonData);
    _setLoading(false);

    final createdReport = FolderModel.fromJson(jsonData['data']);
    _folders.insert(0, createdReport);
    notifyListeners();
  }

  Future<void> createReport({
    required String title,
    required String folderID,
    String? reportType,
  }) async {
    _setLoading(true);
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/create_report'))
          ..fields.addAll({
            'emp_id': empID,
            'name': title,
            'company_id': companyId,
            'folder_id': folderID,
            'company': "test", //todo remove
            if (reportType != null) 'report_type': reportType,
          });
    final jsonData = await _handleResponse(await request.send());
    print(jsonData);
    _setLoading(false);
    ReportModel createdReport = ReportModel.fromJson(jsonData['data']);
    // If API doesn't return reportType, preserve what we sent
    if (createdReport.reportType == null && reportType != null) {
      createdReport = ReportModel(
        id: createdReport.id,
        name: createdReport.name,
        companyId: createdReport.companyId,
        folderId: createdReport.folderId,
        createdAt: createdReport.createdAt,
        updatedAt: createdReport.updatedAt,
        reportType: reportType,
      );
    }
    _reports.insert(0, createdReport);
    notifyListeners();
  }

  Future<void> updateReport(
      {required String name, required String reportId}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/reports/update'))
            ..fields.addAll({
              'emp_id': empID,
              'report_id': reportId,
              'name': name,
            });

      final jsonData = await _handleResponse(await request.send());
      _setLoading(false);
      final updatedReport = ReportModel.fromJson(jsonData['data']);
      int index = _reports.indexWhere((r) => r.id == updatedReport.id);
      if (index != -1) {
        _reports[index] = updatedReport;
        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteReport({required String reportId}) async {
    try {
      _reports.removeWhere((r) => r.id == reportId);
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/reports/delete'))
            ..fields.addAll({
              'emp_id': empID,
              'report_id': reportId,
            });

      final jsonData = await _handleResponse(await request.send());
      _setLoading(false);
      final updatedReport = ReportModel.fromJson(jsonData['data']);
      int index = _reports.indexWhere((r) => r.id == updatedReport.id);
      if (index != -1) {
        _reports.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchAllFolders() async {
    // Ensure empID and companyId are initialized before proceeding
    if (empID.isEmpty || companyId.isEmpty) {
      await init(base: baseUrl); // Ensure init is complete
    }

    _setLoading(true);
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/reports/list'))
            ..fields.addAll({
              'emp_id': empID,
              'company_id': companyId,
            });

      final jsonData = await _handleResponse(await request.send());

      _folders = (jsonData['data'] as List)
          .map((e) => FolderModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error in fetchAllFolders: $e');
      _folders = []; // Avoid crash if data is bad
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllReports({required String folderID}) async {
    _setLoading(true);
    var request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/get_folder_report_list'))
      ..fields.addAll({
        'emp_id': empID,
        'company_id': companyId,
        'folder_id': folderID,
      });
    final jsonData = await _handleResponse(await request.send());

    if (kDebugMode) {
      print('🔍 get_folder_report_list response: $jsonData');
    }
    _setLoading(false);
    // Preserve locally-stored reportTypes before overwriting
    final Map<String, String?> oldTypes = {};
    for (final r in _reports) {
      if (r.reportType != null) {
        oldTypes[r.id] = r.reportType;
      }
    }
    _reports =
        (jsonData['data'] as List).map((e) => ReportModel.fromJson(e)).toList();
    // Re-apply preserved reportTypes if API didn't return them
    for (int i = 0; i < _reports.length; i++) {
      if (_reports[i].reportType == null && oldTypes.containsKey(_reports[i].id)) {
        _reports[i] = ReportModel(
          id: _reports[i].id,
          name: _reports[i].name,
          companyId: _reports[i].companyId,
          folderId: _reports[i].folderId,
          createdAt: _reports[i].createdAt,
          updatedAt: _reports[i].updatedAt,
          reportType: oldTypes[_reports[i].id],
        );
      }
    }
    debugPrint('🔍 Loaded ${_reports.length} reports. Types: ${_reports.map((r) => '${r.name}:${r.reportType}').join(', ')}');
    notifyListeners();
  }

  Future<ReportDetailModel?> getReportDetail(ReportModel report) async {
    Box<ReportDetailModel> reportDetailBox =
        await ReportHiveService.getReportDetailBox();
    return reportDetailBox.get("$empID-${report.folderId}-${report.id}");
  }

  Future<void> updateReportDetail(ReportDetailModel report) async {
    try {
      Box<ReportDetailModel> reportDetailBox =
          await ReportHiveService.getReportDetailBox();
      await reportDetailBox.put(
          "$empID-${report.report.folderId}-${report.report.id}", report);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> deleteCoverPage(ReportDetailModel report) async {
    Box<ReportDetailModel> reportDetailBox =
        await ReportHiveService.getReportDetailBox();
    await reportDetailBox.put(
        "$empID-${report.report.folderId}-${report.report.id}",
        report.copyWith(coverPage: null));
    return true;
  }

  Future<List<ReportPdfModel>> fetchReports(
      {required String empId,
      required String reportId,
      required String folderId}) async {
    final url = Uri.parse('$baseUrl/api/get_report_list');
    final response = await http.post(
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      url,
      body: {
        'emp_id': empId,
        'report_id': reportId,
        'folder_id': folderId,
      },
    );
    print('body: $empId $reportId $folderId');
    print('fetchReports: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => ReportPdfModel.fromJson(json)).toList();
    } else {
      showFlushBar(navKey.currentContext!,
          message: jsonDecode(response.body)['message']);
      return [];
    }
  }

  Future<bool> uploadReportPdf({
    required String empId,
    required Uint8List pdfBytes,
    required String reportId,
    required String folderId,
    required String fileName,
  }) async {
    final url = Uri.parse(
        '$baseUrl/api/upload_site_report?folder_id=$folderId&file_name=$fileName');
    // print('folderId: $folderId,  file_name:$fileName, ');

    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['emp_id'] = empId
        ..fields['report_id'] = reportId
        ..fields['folder_id'] = folderId
        ..fields['file_name'] = fileName
        ..files.add(
          http.MultipartFile.fromBytes(
            'file', // field name on backend
            pdfBytes,
            filename: fileName,
          ),
        );
      print(request.fields);
      print("Sending request to $url");
      final streamedResponse = await request.send();

      print("Streamed response status: ${streamedResponse.statusCode}");

      final response = await http.Response.fromStream(streamedResponse);

      print("Final response body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception caught during PDF upload: $e");
      return false;
    }
  }

  // ── Report Items API (server-side) ──

  /// Add a report item (image + location + description) to the server
  Future<ReportItemModel?> addReportItem({
    required String reportId,
    required File imageFile,
    required String location,
    required String description,
    String type = 'image',
    int index = 0,
  }) async {
    try {
      debugPrint('📤 addReportItem: reportId=$reportId, location=$location, image=${imageFile.path}');
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/api/upload_report_item'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': reportId,
          'location': location,
          'description': description,
          'type': type,
        });

      request.files
          .add(await http.MultipartFile.fromPath('item_data', imageFile.path));

      final response = await request.send();
      final res = await response.stream.bytesToString();
      debugPrint('📤 upload_report_item response: $res');
      final jsonData = json.decode(res);
      
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('data') && jsonData['data'] != null) {
        final data = jsonData['data'];
        if (data is List && data.isNotEmpty) {
          return ReportItemModel.fromJson(data[0] as Map<String, dynamic>, reportId);
        } else if (data is Map<String, dynamic>) {
          return ReportItemModel.fromJson(data, reportId);
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding report item: $e');
      debugPrint('❌ Stack: $stackTrace');
      return null;
    }
  }

  /// Update a report item on the server
  Future<ReportItemModel?> updateReportItem({
    required String reportId,
    required String itemId,
    String? location,
    String? description,
    File? imageFile,
    int index = 0,
  }) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/report-items/update'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': reportId,
          'item_id': itemId,
          if (location != null) 'location': location,
          if (description != null) 'description': description,
          'index': index.toString(),
        });

      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      debugPrint('📤 updateReportItem: url=${request.url} fields=${request.fields}');
      final jsonData = await _handleResponse(await request.send(), neverShowMessage: true);
      debugPrint('📤 updateReportItem response: $jsonData');
      if (jsonData.containsKey('data') && jsonData['data'] != null) {
        return ReportItemModel.fromJson(jsonData['data'], reportId);
      }
      return null;
    } catch (e) {
      debugPrint('📤 Error updating report item: $e');
      return null;
    }
  }

  /// Delete a report item from the server
  Future<bool> deleteReportItem({
    required String reportId,
    required String itemId,
  }) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/report-items/delete'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': reportId,
          'item_id': itemId,
        });

      await _handleResponse(await request.send());
      return true;
    } catch (e) {
      debugPrint('Error deleting report item: $e');
      return false;
    }
  }

  /// Fetch full report detail (with items) from the server
  Future<ReportDetailModel?> fetchReportDetailFromApi(String reportId) async {
    try {
      debugPrint('🔍 fetchReportDetailFromApi: reportId=$reportId, baseUrl=$baseUrl');
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/reports/detail'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': reportId,
        });

      final response = await request.send();
      final res = await response.stream.bytesToString();
      debugPrint('🔍 reports/detail raw response: $res');
      final jsonData = json.decode(res);
      
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('data') && jsonData['data'] != null) {
        return ReportDetailModel.fromJson(jsonData['data']);
      }
      debugPrint('🔍 reports/detail: no data in response');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching report detail: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }
}
