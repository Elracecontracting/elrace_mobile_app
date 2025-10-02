import 'dart:io';

import 'package:el_race/data/models/pdf_model.dart';
import 'package:el_race/data/models/report_detail_item.dart';
import 'package:el_race/data/models/report_detail_model.dart';
import 'package:el_race/report_module/data/models/company_model.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';
import '../../core/constants/hive_constants.dart';

class HiveService {
  static Box<ReportModel>? _reportBox;
  static Box<ReportDetailModel>? _reportDetailBox;
  static Box<CompanyModel>? _companyBox;
  static Box<PdfModel>? _pdfBox;

  static Future<void> setupHive() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);
    Hive.registerAdapter(ReportModelAdapter());
    Hive.registerAdapter(ReportDetailModelAdapter());
    Hive.registerAdapter(ReportDetailItemAdapter());
    Hive.registerAdapter(CompanyModelAdapter());
    Hive.registerAdapter(PdfModelAdapter());
  }

  static Future<Box<PdfModel>> getPdfBox() async {
    if (_pdfBox == null || !_pdfBox!.isOpen) {
      _pdfBox = await Hive.openBox<PdfModel>(HiveConstants.reportPdfBox);
    }
    return _pdfBox!;
  }

  static Future<Box<ReportModel>> getReportBox() async {
    if (_reportBox == null || !_reportBox!.isOpen) {
      _reportBox = await Hive.openBox<ReportModel>(HiveConstants.reportBox);
    }
    return _reportBox!;
  }

  static Future<Box<CompanyModel>> getCompanyBox() async {
    if (_companyBox == null || !_companyBox!.isOpen) {
      _companyBox = await Hive.openBox<CompanyModel>(HiveConstants.companyBox);
    }
    return _companyBox!;
  }

  static Future<Box<ReportDetailModel>> getReportDetailBox() async {
    if (_reportDetailBox == null || !_reportDetailBox!.isOpen) {
      _reportDetailBox = await Hive.openBox(HiveConstants.reportDetailBox);
    }
    return _reportDetailBox!;
  }
}
