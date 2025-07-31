import 'package:el_race/report_module/data/models/cover_page_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/models/report_model.dart';

class ReportDetailModel {
  final ReportModel report;
  final List<ReportItemModel> reportItems;
  final CoverPageModel? coverPage;

  ReportDetailModel({
    required this.report,
    required this.coverPage,
    required this.reportItems,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    return ReportDetailModel(
      report: ReportModel.fromJson(json['report']),
      coverPage: json['cover_page'] != null
          ? CoverPageModel.fromJson(json['cover_page'])
          : null,
      reportItems: (json['report_items'] as List<dynamic>)
          .map((item) => ReportItemModel.fromJson(item, json['report']['id']))
          .toList(),
    );
  }

  ReportDetailModel copyWith({
    ReportModel? report,
    CoverPageModel? coverPage,
    List<ReportItemModel>? reportItems,
  }) {
    return ReportDetailModel(
      report: report ?? this.report,
      coverPage: coverPage ?? this.coverPage,
      reportItems: reportItems ?? this.reportItems,
    );
  }
}
