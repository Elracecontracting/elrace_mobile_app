class CoverPageModel {
  final String empId;
  final String title;
  final String? description;
  final String? id; // for update
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CoverPageModel({
    required this.empId,
    required this.title,
    this.description,
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  factory CoverPageModel.fromJson(Map<String, dynamic> json) => CoverPageModel(
        empId:
            json['emp_id'] ?? '', // Updated to extract from JSON if available
        title: json['title'],
        description: json['description'],
        id: json['id'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'emp_id': empId,
        'title': title,
        'description': description,
        'id': id,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  CoverPageModel copyWith({
    String? empId,
    String? title,
    String? description,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoverPageModel(
      empId: empId ?? this.empId,
      title: title ?? this.title,
      description: description ?? this.description,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
