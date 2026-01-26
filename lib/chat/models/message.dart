import 'package:cloud_firestore/cloud_firestore.dart';

/// Message types supported
enum MessageType {
  text,
  image,
  file,
  audio,
  video;

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  String toJson() => name;
}

/// Message status (client-side only for now)
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  String toJson() => name;
}

/// Reply to message info (minimal for now)
class ReplyTo {
  final String messageId;
  final String senderId;
  final String? text;
  final String type;

  ReplyTo({
    required this.messageId,
    required this.senderId,
    this.text,
    required this.type,
  });

  factory ReplyTo.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return ReplyTo(messageId: '', senderId: '', type: 'text');
    }
    return ReplyTo(
      messageId: data['message_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      text: data['text'],
      type: data['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'text': text,
      'type': type,
    };
  }
}

/// Represents a message in a chat.
/// Stored in Firestore at: chats/{chatId}/messages/{messageId}
class Message {
  final String id;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? mediaPath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? durationMs; // For audio/video
  final String? thumbUrl;
  final ReplyTo? replyTo;
  final DateTime createdAt;
  final String clientMsgId; // UUID for dedup
  final MessageStatus status;
  
  // Local state (not persisted)
  final bool isUploading;
  final double uploadProgress;

  Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.mediaPath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.durationMs,
    this.thumbUrl,
    this.replyTo,
    required this.createdAt,
    required this.clientMsgId,
    this.status = MessageStatus.sent,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Message(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      type: MessageType.fromString(data['type'] ?? 'text'),
      text: data['text'],
      mediaUrl: data['media_url'],
      mediaPath: data['media_path'],
      fileName: data['file_name'],
      fileSize: data['file_size'],
      mimeType: data['mime_type'],
      durationMs: data['duration_ms'],
      thumbUrl: data['thumb_url'],
      replyTo: data['reply_to'] != null
          ? ReplyTo.fromMap(data['reply_to'] as Map<String, dynamic>)
          : null,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clientMsgId: data['client_msg_id'] ?? '',
      status: MessageStatus.fromString(data['status'] ?? 'sent'),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'sender_id': senderId,
      'type': type.toJson(),
      'created_at': FieldValue.serverTimestamp(),
      'client_msg_id': clientMsgId,
      'status': 'sent',
    };

    if (text != null) map['text'] = text;
    if (mediaUrl != null) map['media_url'] = mediaUrl;
    if (mediaPath != null) map['media_path'] = mediaPath;
    if (fileName != null) map['file_name'] = fileName;
    if (fileSize != null) map['file_size'] = fileSize;
    if (mimeType != null) map['mime_type'] = mimeType;
    if (durationMs != null) map['duration_ms'] = durationMs;
    if (thumbUrl != null) map['thumb_url'] = thumbUrl;
    if (replyTo != null) map['reply_to'] = replyTo!.toMap();

    return map;
  }

  /// Get preview text for last_message in chat
  String getPreviewText() {
    switch (type) {
      case MessageType.text:
        return text ?? '';
      case MessageType.image:
        return text?.isNotEmpty == true ? '📷 $text' : '📷 Photo';
      case MessageType.file:
        return '📎 ${fileName ?? 'File'}';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.video:
        return '🎬 Video';
    }
  }

  Message copyWith({
    String? id,
    String? senderId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    String? mediaPath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? durationMs,
    String? thumbUrl,
    ReplyTo? replyTo,
    DateTime? createdAt,
    String? clientMsgId,
    MessageStatus? status,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaPath: mediaPath ?? this.mediaPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      replyTo: replyTo ?? this.replyTo,
      createdAt: createdAt ?? this.createdAt,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      status: status ?? this.status,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  String toString() => 'Message(id: $id, type: $type, senderId: $senderId)';
}
