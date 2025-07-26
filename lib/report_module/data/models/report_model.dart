class ReportModel {
  final String id;
  final String name;
  final String companyId; //optional todo remove
  final DateTime createdAt;
  final String folderId;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.folderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      folderId: json['folder_id'].toString(),
      companyId: json['company_id'].toString(),
      createdAt:
          DateTime.parse(json['created_at'] ?? json['create_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
