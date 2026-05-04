class FolderModel {
  final String id;
  final String name;
  final String description;
  final int companyId;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.name,
    required this.description,
    required this.companyId,
    required this.reportCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper: check if a report item is a generated PDF artifact (not an editable report)
    bool _isGeneratedArtifact(Map item) {
      final rawS3 = item['s3_key'];
      final hasS3Key =
          rawS3 != null && rawS3 != false && rawS3.toString().trim().isNotEmpty;
      final rawFileName = item['file_name'];
      final hasFileName = rawFileName != null &&
          rawFileName != false &&
          rawFileName.toString().trim().isNotEmpty;
      return hasS3Key || hasFileName;
    }

    final dynamic reportsValue = json['report_count'] ??
        json['reports_count'] ??
        json['total_reports'] ??
        json['count'] ??
        json['reports'];

    int parsedReportCount;
    if (reportsValue is List) {
      // Filter out generated PDF artifacts — only count editable reports
      parsedReportCount = reportsValue
          .whereType<Map>()
          .where((item) => !_isGeneratedArtifact(item))
          .length;
    } else {
      parsedReportCount = _toInt(reportsValue);
    }

    return FolderModel(
      id: (json['id'] ?? json['folder_id']).toString(),
      name: (json['name'] ?? json['folder_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      companyId: _toInt(json['company_id']),
      reportCount: parsedReportCount,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['create_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ??
                  json['created_at'] ??
                  json['create_at'] ??
                  '')
              .toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'company_id': companyId,
      'report_count': reportCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FolderModel copyWith({
    String? id,
    String? name,
    String? description,
    int? companyId,
    int? reportCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
