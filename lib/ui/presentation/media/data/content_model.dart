/// Model for content items from get_contents API
/// Handles both photos and 360_view items
class ContentModel {
  final int id;
  final String fileName;
  final String projectName;
  final bool is360View;
  final String previewUrl;

  const ContentModel({
    required this.id,
    required this.fileName,
    required this.projectName,
    required this.is360View,
    required this.previewUrl,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? '',
      projectName: json['project_name'] ?? '',
      is360View: json['is_360_view'] ?? false,
      previewUrl: json['preview_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'project_name': projectName,
      'is_360_view': is360View,
      'preview_url': previewUrl,
    };
  }

  ContentModel copyWith({
    int? id,
    String? fileName,
    String? projectName,
    bool? is360View,
    String? previewUrl,
  }) {
    return ContentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      projectName: projectName ?? this.projectName,
      is360View: is360View ?? this.is360View,
      previewUrl: previewUrl ?? this.previewUrl,
    );
  }

  /// Display name without extension
  String get displayName {
    if (fileName.contains('.')) {
      return fileName.substring(0, fileName.lastIndexOf('.'));
    }
    return fileName;
  }

  /// Check if this is a photo (non-360 view)
  bool get isPhoto => !is360View;

  /// Check if this is a 360 view
  bool get is360 => is360View;
}

/// Response model for get_contents API
class ContentsResponse {
  final List<ContentModel> photos;
  final List<ContentModel> view360;

  const ContentsResponse({
    required this.photos,
    required this.view360,
  });

  factory ContentsResponse.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['result']?['data'] ?? json['data'] ?? json;
      
      List<ContentModel> photosList = [];
      List<ContentModel> view360List = [];

      if (data['photos'] != null && data['photos'] is List) {
        photosList = (data['photos'] as List)
            .map((item) => ContentModel.fromJson(item))
            .toList();
      }

      if (data['360_view'] != null && data['360_view'] is List) {
        view360List = (data['360_view'] as List)
            .map((item) => ContentModel.fromJson(item))
            .toList();
      }

      print('✅ ContentsResponse parsed: ${photosList.length} photos, ${view360List.length} 360 views');

      return ContentsResponse(
        photos: photosList,
        view360: view360List,
      );
    } catch (e) {
      print('❌ Error parsing ContentsResponse: $e');
      print('📦 JSON data: $json');
      rethrow;
    }
  }

  /// Get all content items combined
  List<ContentModel> get allContent => [...photos, ...view360];

  /// Check if there are any photos
  bool get hasPhotos => photos.isNotEmpty;

  /// Check if there are any 360 views
  bool get has360Views => view360.isNotEmpty;

  /// Check if there is any content
  bool get hasContent => hasPhotos || has360Views;
}
