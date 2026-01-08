/// Model for announcements/news/circulars
/// Category mapping:
/// 1 → News
/// 2 → Announcements
/// 3 → Circulars
class AnnouncementModel {
  final int id;
  final String name;
  final String description;
  final bool hasAttachment;
  final String? attachmentUrl;

  AnnouncementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.hasAttachment,
    this.attachmentUrl,
  });

  /// Factory constructor to parse from JSON response
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      hasAttachment:
          json['has_attachment'] == true || json['has_attachment'] == 1,
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'has_attachment': hasAttachment,
      'attachment_url': attachmentUrl,
    };
  }

  /// Copy with method for immutability
  AnnouncementModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? hasAttachment,
    String? attachmentUrl,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, name: $name, hasAttachment: $hasAttachment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnouncementModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.hasAttachment == hasAttachment &&
        other.attachmentUrl == attachmentUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        hasAttachment.hashCode ^
        attachmentUrl.hashCode;
  }
}
