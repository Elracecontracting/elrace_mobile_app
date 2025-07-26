class ReportItemModel {
  final String id;
  final String reportId;
  final String type;
  final String image;
  final String location;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportItemModel({
    required this.id,
    required this.reportId,
    required this.type,
    required this.image,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportItemModel.fromJson(Map<String, dynamic> json) {
    return ReportItemModel(
      id: json['item_id'].toString(),
      reportId: json['report_id'].toString(),
      type: json['type'],
      image: json['item_data'],
      location: json['location'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': id,
      'report_id': reportId,
      'type': type,
      'item_data': image,
      'location': location,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReportItemModel copyWith({
    String? itemId,
    String? reportId,
    String? type,
    String? itemData,
    String? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportItemModel(
      id: itemId ?? id,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      image: itemData ?? image,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
