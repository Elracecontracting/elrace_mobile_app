import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/models/report_pdf_model.dart';
<<<<<<< Updated upstream
import 'package:el_race/report_module/data/services/report_hive_service.dart';
=======
>>>>>>> Stashed changes
import 'package:el_race/ui/presentation/call_screen/data/repository.dart';
import 'package:flutter/foundation.dart';
import 'package:el_race/main.dart';
import 'package:el_race/report_module/core/utils/flush_bar.dart';
import 'package:el_race/report_module/data/models/cover_page_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
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
      {bool alwaysShowMessage = false}) async {
    final res = await response.stream.bytesToString();
    print('fff ${res}');
    final jsonData = json.decode(res);

<<<<<<< Updated upstream
    if (jsonData is Map && jsonData['status'] == "upcoming") {
=======
    if (jsonData.toString().toLowerCase().contains('status') && jsonData['status'] != null && jsonData['status'] == "upcoming") {
>>>>>>> Stashed changes
      showFlushBar(navKey.currentContext!, message: jsonData['message']);
      return {};
    }

    if (alwaysShowMessage ||
        (jsonData is Map && jsonData['status'] != "success")) {
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
<<<<<<< Updated upstream
    // print(companyId);
    final jsonData = await _handleResponse(await request.send());
    // print(jsonData);
=======
    final jsonData = await _handleResponse(await request.send());

>>>>>>> Stashed changes
    _setLoading(false);

    final createdReport = FolderModel.fromJson(jsonData['data']);
    _folders.insert(0, createdReport);
    notifyListeners();
  }

  Future<void> createReport(
      {required String title, required String folderID}) async {
    _setLoading(true);
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/create_report'))
          ..fields.addAll({
            'emp_id': empID,
            'name': title,
            'company_id': companyId,
            'folder_id': folderID,
            'company': "test" //todo remove
          });
    final jsonData = await _handleResponse(await request.send());
    print(jsonData);
    _setLoading(false);
    final createdReport = ReportModel.fromJson(jsonData['data']);
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
              'name': companyId,
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
      print(jsonData);
    }
    _setLoading(false);
    _reports =
        (jsonData['data'] as List).map((e) => ReportModel.fromJson(e)).toList();
    notifyListeners();
  }

<<<<<<< Updated upstream
  Future<ReportDetailModel?> getReportDetail(ReportModel report) async {
    Box<ReportDetailModel> reportDetailBox =
        await ReportHiveService.getReportDetailBox();
    return reportDetailBox.get("$empID-${report.folderId}-${report.id}");
=======
  Future<ReportDetailModel> getReportDetail(ReportModel report) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/reports/detail'))
          ..fields.addAll({
            'emp_id': empID,
            'report_id': report.id,
            'folder_id': report.folderId
          });

    final jsonData = await _handleResponse(await request.send());
    return ReportDetailModel.fromJson(jsonData['data']);
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
  Future<bool> deleteCoverPage(ReportDetailModel report) async {
    Box<ReportDetailModel> reportDetailBox =
        await ReportHiveService.getReportDetailBox();
    await reportDetailBox.put(
        "$empID-${report.report.folderId}-${report.report.id}",
        report.copyWith(coverPage: null));
    return true;
=======
  Future<CoverPageModel?> editCoverPage(CoverPageModel cover) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/report-cover/update'))
        ..fields.addAll({
          'emp_id': cover.empId,
          'cover_id': cover.id!,
          'title': cover.title,
          'description': cover.description ?? "",
        });
      final jsonData = await _handleResponse(await request.send());
      return CoverPageModel.fromJson(jsonData['data']);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<bool> deleteCoverPage(String coverId) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/report-cover/delete'))
          ..fields.addAll({
            'emp_id': empID,
            'cover_id': coverId,
          });
    final jsonData =
        await _handleResponse(await request.send(), alwaysShowMessage: true);
    return jsonData['status'] == "success";
  }

  Future<ReportItemModel?> addReportItem(
      {required String reportId,
      String type = "text",
      String? location,
      String? description,
      File? imageFile}) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/api/upload_report_item'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': reportId,
          'location': location ?? "",
          'description': description ?? '',
          'type': type,
          'index': "0",
        });

      if (imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('item_data', imageFile.path));
      }

      final jsonData = await _handleResponse(await request.send());
      return ReportItemModel.fromJson(jsonData['data'][0], reportId);
    } catch (e) {
      return null;
    }
  }

  Future<ReportItemModel?> updateReportItem(ReportItemModel item,
      {var imageFile}) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/report-items/update'))
        ..fields.addAll({
          'emp_id': empID,
          'report_id': item.reportId,
          'item_id': item.id,
          'location': item.location,
          'description': item.description,
        });

      if (imageFile != null && imageFile is File) {
        request.files.add(
            await http.MultipartFile.fromPath('item_data', imageFile.path));
      }

      if (imageFile != null && imageFile is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('item_data', imageFile));
      }
      final jsonData = await _handleResponse(await request.send());
      if (jsonData.isEmpty) return null;

      return ReportItemModel.fromJson(jsonData['data'], item.reportId);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<bool> deleteReportItem(String itemId, String reportId) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/report-items/delete'))
          ..fields.addAll({
            'emp_id': empID,
            'report_id': reportId,
            'item_id': itemId,
          });
    final jsonData =
        await _handleResponse(await request.send(), alwaysShowMessage: true);
    return jsonData['status'] == "success";
>>>>>>> Stashed changes
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
}
