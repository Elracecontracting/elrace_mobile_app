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

    final dynamic reportsValue =
        json['report_count'] ??
        json['reports_count'] ??
        json['total_reports'] ??
        json['count'] ??
        json['reports'];

    final int parsedReportCount = reportsValue is List
        ? reportsValue.length
        : _toInt(reportsValue);

    return FolderModel(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      companyId: json['company_id'],
      reportCount: parsedReportCount,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
