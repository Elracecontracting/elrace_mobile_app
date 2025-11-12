class ReportPdfModel {
  final String fileId;
  final String fileName;
  final String createdAt;
  final String reportLink;

  ReportPdfModel({
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    required this.reportLink,
  });

  factory ReportPdfModel.fromJson(Map<String, dynamic> json) {
    return ReportPdfModel(
      fileId: json['file_id'],
      fileName: json['file_name'],
      createdAt: json['created_at'],
      reportLink: json['report_link'],
    );
  }
}
