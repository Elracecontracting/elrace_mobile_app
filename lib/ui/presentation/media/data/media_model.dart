enum MediaType { image, video }

class MediaModel {
  final String id;
  final String name;
  final String url;
  final String? xWebUrl;
  final MediaType type;
  final DateTime dateCreated;
  final int? duration;
  final double? size;

  MediaModel({
    required this.id,
    required this.name,
    required this.url,
    this.xWebUrl,
    required this.type,
    required this.dateCreated,
    this.duration,
    this.size,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    String fileName = json['name'] ?? '';
    String fileUrl = json['url'] ?? json['x_web_url'] ?? '';
    
    return MediaModel(
      id: json['id']?.toString() ?? '',
      name: fileName,
      url: fileUrl,
      xWebUrl: json['x_web_url'],
      type: getMediaTypeFromExtension(fileName.split('.').last),
      dateCreated: DateTime.now(), // API doesn't provide date, using current time
      duration: json['duration'],
      size: json['size']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'x_web_url': xWebUrl,
      'type': type.name,
      'dateCreated': dateCreated.toIso8601String(),
      'duration': duration,
      'size': size,
    };
  }

  MediaModel copyWith({
    String? id,
    String? name,
    String? url,
    String? xWebUrl,
    MediaType? type,
    DateTime? dateCreated,
    int? duration,
    double? size,
  }) {
    return MediaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      xWebUrl: xWebUrl ?? this.xWebUrl,
      type: type ?? this.type,
      dateCreated: dateCreated ?? this.dateCreated,
      duration: duration ?? this.duration,
      size: size ?? this.size,
    );
  }

  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;

  String get fileExtension {
    return url.split('.').last.toLowerCase();
  }

  static MediaType getMediaTypeFromExtension(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'];
    
    if (imageExtensions.contains(extension.toLowerCase())) {
      return MediaType.image;
    } else if (videoExtensions.contains(extension.toLowerCase())) {
      return MediaType.video;
    }
    return MediaType.image;
  }
} 