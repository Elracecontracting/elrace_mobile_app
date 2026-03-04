/// Model for content items from get_contents API
/// Handles both photos and 360_view items
class ContentModel {
  final int id;
  final String fileName;
  final String projectName;
  final bool is360View;
  final String previewUrl;
  final DateTime? dateCreated;

  const ContentModel({
    required this.id,
    required this.fileName,
    required this.projectName,
    required this.is360View,
    required this.previewUrl,
    this.dateCreated,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? '',
      projectName: json['project_name'] ?? '',
      is360View: json['is_360_view'] ?? false,
      previewUrl: json['preview_url'] ?? '',
      dateCreated: _parseDateTime(json['date_created']) ??
          _parseDateTime(json['uploaded_on']) ??
          _parseDateTime(json['created_at']) ??
          _parseDateTime(json['create_date']) ??
          _parseDateTime(json['date']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Heuristic: treat large values as milliseconds, else seconds.
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return null;
    }
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'project_name': projectName,
      'is_360_view': is360View,
      'preview_url': previewUrl,
      'date_created': dateCreated?.toIso8601String(),
    };
  }

  ContentModel copyWith({
    int? id,
    String? fileName,
    String? projectName,
    bool? is360View,
    String? previewUrl,
    DateTime? dateCreated,
  }) {
    return ContentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      projectName: projectName ?? this.projectName,
      is360View: is360View ?? this.is360View,
      previewUrl: previewUrl ?? this.previewUrl,
      dateCreated: dateCreated ?? this.dateCreated,
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
  final List<List<ContentModel>> photoGroups;
  final List<ContentModel> view360;

  const ContentsResponse({
    required this.photos,
    this.photoGroups = const [],
    required this.view360,
  });

  factory ContentsResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dynamic rawData = json['result']?['data'] ?? json['data'] ?? json;
      final Map<String, dynamic> data =
          rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

      List<ContentModel> photosList = [];
      List<List<ContentModel>> photoGroupsList = [];
      List<ContentModel> view360List = [];

      final rawPhotos = data['photos'];
      if (rawPhotos is List) {
        for (final entry in rawPhotos) {
          if (entry is List) {
            final group = entry
                .whereType<Map<String, dynamic>>()
                .map(ContentModel.fromJson)
                .toList();
            _sortNewestFirst(group);
            if (group.isNotEmpty) {
              photoGroupsList.add(group);
              photosList.addAll(group);
            }
          } else if (entry is Map<String, dynamic>) {
            photosList.add(ContentModel.fromJson(entry));
          }
        }

        if (photoGroupsList.isEmpty && photosList.isNotEmpty) {
          _sortNewestFirst(photosList);
          photoGroupsList = [List<ContentModel>.from(photosList)];
        }
      }

      if (data['360_view'] != null && data['360_view'] is List) {
        view360List = (data['360_view'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ContentModel.fromJson)
            .toList();
      }

      _sortNewestFirst(photosList);
      _sortNewestFirst(view360List);

      print(
          '✅ ContentsResponse parsed: ${photosList.length} photos (${photoGroupsList.length} groups), ${view360List.length} 360 views');

      return ContentsResponse(
        photos: photosList,
        photoGroups: photoGroupsList,
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

  static void _sortNewestFirst(List<ContentModel> items) {
    items.sort((a, b) {
      final aDate = a.dateCreated;
      final bDate = b.dateCreated;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
  }
}
