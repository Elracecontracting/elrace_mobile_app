import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/presence_service.dart';

/// Repository for chat-related Firestore and Storage operations.
/// 
/// Handles:
/// - DM creation and management
/// - Role chat setup
/// - Message sending (text, image, file, audio)
/// - Message streaming with pagination
/// - Read receipts
/// - User chat list management
class ChatRepository {
  static ChatRepository? _instance;
  static ChatRepository get instance => _instance ??= ChatRepository._();
  
  ChatRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Configuration
  static const bool groupByBranch = false; // Set to true to group by branch
  static const int defaultPageSize = 50;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');
  
  CollectionReference<Map<String, dynamic>> _userChatsCollection(String uid) =>
      _firestore.collection('userChats').doc(uid).collection('chats');

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ============== DM Chat Creation ==============

  /// Create or get an existing DM chat between two users.
  /// Returns the chat ID.
  Future<String> createOrGetDmChat({
    required String otherUid,
    required String otherName,
    required String currentUserName,
    int? otherRoleId,
    int? otherBranchId,
    int? otherCompanyId,
    int? currentUserRoleId,
    int? currentUserBranchId,
    int? currentUserCompanyId,
  }) async {
    final currentUid = _currentUid;
    if (currentUid == null) {
      throw Exception('Not authenticated');
    }

    final chatId = Chat.generateDmChatId(currentUid, otherUid);
    final dmPair = Chat.getSortedDmPair(currentUid, otherUid);

    try {
      final batch = _firestore.batch();

      // Create/update chat document
      final chatRef = _chatsCollection.doc(chatId);
      batch.set(chatRef, {
        'type': 'dm',
        'dm_pair': dmPair,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create member documents for both users
      final currentMemberRef = chatRef.collection('members').doc(currentUid);
      batch.set(currentMemberRef, {
        'joined_at': FieldValue.serverTimestamp(),
        'role_id_snapshot': currentUserRoleId,
        'branch_id_snapshot': currentUserBranchId,
        'company_id_snapshot': currentUserCompanyId,
        'muted': false,
      }, SetOptions(merge: true));

      final otherMemberRef = chatRef.collection('members').doc(otherUid);
      batch.set(otherMemberRef, {
        'joined_at': FieldValue.serverTimestamp(),
        'role_id_snapshot': otherRoleId,
        'branch_id_snapshot': otherBranchId,
        'company_id_snapshot': otherCompanyId,
        'muted': false,
      }, SetOptions(merge: true));

      // Create userChats entries for both users
      final currentUserChatRef = _userChatsCollection(currentUid).doc(chatId);
      batch.set(currentUserChatRef, {
        'type': 'dm',
        'peer_uid': otherUid,
        'title': otherName,
        'updated_at': FieldValue.serverTimestamp(),
        'pinned': false,
        'muted': false,
      }, SetOptions(merge: true));

      final otherUserChatRef = _userChatsCollection(otherUid).doc(chatId);
      batch.set(otherUserChatRef, {
        'type': 'dm',
        'peer_uid': currentUid,
        'title': currentUserName,
        'updated_at': FieldValue.serverTimestamp(),
        'pinned': false,
        'muted': false,
      }, SetOptions(merge: true));

      await batch.commit();
      print('✅ ChatRepository: Created/updated DM chat $chatId');

      return chatId;
    } catch (e) {
      print('❌ ChatRepository: Error creating DM chat: $e');
      rethrow;
    }
  }

  // ============== Role Chat Setup ==============

  /// Ensure role chat exists and current user is a member.
  /// Called during chat setup after login.
  Future<String> ensureRoleChatMembership({
    required String uid,
    required int roleId,
    int? branchId,
    int? companyId,
    String? roleChatId, // Backend-provided chat ID
    String? title, // Optional title for the group
  }) async {
    // Determine chat ID
    final chatId = roleChatId ?? Chat.generateRoleChatId(
      roleId: roleId,
      branchId: branchId,
      groupByBranch: groupByBranch,
    );

    // Generate default title - use provided title (role name) or fallback to role ID
    final groupTitle = title ?? 'مجموعة $roleId${groupByBranch && branchId != null ? ' - فرع $branchId' : ''}';

    try {
      final batch = _firestore.batch();

      // Create/update role chat document
      final chatRef = _chatsCollection.doc(chatId);
      batch.set(chatRef, {
        'type': 'role',
        'role_id': roleId,
        'branch_id': branchId,
        'company_id': companyId,
        'title': groupTitle,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add current user as member
      final memberRef = chatRef.collection('members').doc(uid);
      batch.set(memberRef, {
        'joined_at': FieldValue.serverTimestamp(),
        'role_id_snapshot': roleId,
        'branch_id_snapshot': branchId,
        'company_id_snapshot': companyId,
        'muted': false,
      }, SetOptions(merge: true));

      // Create userChats entry for current user
      final userChatRef = _userChatsCollection(uid).doc(chatId);
      batch.set(userChatRef, {
        'type': 'role',
        'role_id': roleId,
        'branch_id': branchId,
        'company_id': companyId,
        'title': groupTitle,
        'updated_at': FieldValue.serverTimestamp(),
        'pinned': false,
        'muted': false,
      }, SetOptions(merge: true));

      await batch.commit();
      print('✅ ChatRepository: Ensured role chat membership for $uid in $chatId');

      return chatId;
    } catch (e) {
      print('❌ ChatRepository: Error ensuring role chat membership: $e');
      rethrow;
    }
  }

  // ============== Chat List ==============

  /// Get user's chat list stream
  Stream<List<UserChat>> subscribeToUserChats(String uid) {
    return _userChatsCollection(uid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserChat.fromFirestore(doc)).toList();
    });
  }

  /// Get a specific chat
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _chatsCollection.doc(chatId).get();
      if (!doc.exists) return null;
      return Chat.fromFirestore(doc);
    } catch (e) {
      print('❌ ChatRepository: Error getting chat: $e');
      return null;
    }
  }

  /// Get user's chat entry (for checking mute status, etc.)
  Future<UserChat?> getUserChat(String chatId) async {
    final uid = _currentUid;
    if (uid == null) return null;
    
    try {
      final doc = await _userChatsCollection(uid).doc(chatId).get();
      if (!doc.exists) return null;
      return UserChat.fromFirestore(doc);
    } catch (e) {
      print('❌ ChatRepository: Error getting user chat: $e');
      return null;
    }
  }

  /// Subscribe to a specific chat
  Stream<Chat?> subscribeToChat(String chatId) {
    return _chatsCollection.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Chat.fromFirestore(doc);
    });
  }

  // ============== Messages ==============

  /// Subscribe to messages in a chat with pagination
  Stream<List<Message>> subscribeToMessages(
    String chatId, {
    int pageSize = defaultPageSize,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// Load more messages (for pagination)
  Future<List<Message>> loadMoreMessages(
    String chatId, {
    required DocumentSnapshot startAfter,
    int pageSize = defaultPageSize,
  }) async {
    try {
      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('created_at', descending: true)
          .startAfterDocument(startAfter)
          .limit(pageSize)
          .get();

      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ ChatRepository: Error loading more messages: $e');
      return [];
    }
  }

  /// Send a text message
  Future<Message> sendText(String chatId, String text, {ReplyTo? replyTo}) async {
    final currentUid = _currentUid;
    if (currentUid == null) {
      throw Exception('Not authenticated');
    }

    final clientMsgId = _uuid.v4();
    final messageRef = _chatsCollection.doc(chatId).collection('messages').doc();

    final message = Message(
      id: messageRef.id,
      senderId: currentUid,
      type: MessageType.text,
      text: text,
      createdAt: DateTime.now(),
      clientMsgId: clientMsgId,
      replyTo: replyTo,
      status: MessageStatus.sending,
    );

    try {
      final batch = _firestore.batch();

      // Add message
      batch.set(messageRef, message.toFirestore());

      // Update chat last_message and updated_at
      final chatRef = _chatsCollection.doc(chatId);
      batch.update(chatRef, {
        'last_message': {
          'text': text,
          'type': 'text',
          'sender_id': currentUid,
          'created_at': FieldValue.serverTimestamp(),
        },
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update sender's userChats entry
      batch.update(_userChatsCollection(currentUid).doc(chatId), {
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Clear typing status
      await PresenceService.instance.setTyping(chatId, false);

      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      print('❌ ChatRepository: Error sending text message: $e');
      rethrow;
    }
  }

  /// Send an image message
  Future<Message> sendImage(
    String chatId,
    File imageFile, {
    String? caption,
    ReplyTo? replyTo,
  }) async {
    return _sendMedia(
      chatId: chatId,
      file: imageFile,
      type: MessageType.image,
      caption: caption,
      replyTo: replyTo,
    );
  }

  /// Send a file message
  Future<Message> sendFile(
    String chatId,
    File file, {
    String? caption,
    String? mimeType,
    ReplyTo? replyTo,
  }) async {
    return _sendMedia(
      chatId: chatId,
      file: file,
      type: MessageType.file,
      caption: caption,
      mimeType: mimeType,
      replyTo: replyTo,
    );
  }

  /// Send a voice message
  Future<Message> sendVoice(
    String chatId,
    File audioFile, {
    required int durationMs,
    ReplyTo? replyTo,
  }) async {
    return _sendMedia(
      chatId: chatId,
      file: audioFile,
      type: MessageType.audio,
      durationMs: durationMs,
      mimeType: 'audio/m4a',
      replyTo: replyTo,
    );
  }

  /// Internal method to send media messages
  Future<Message> _sendMedia({
    required String chatId,
    required File file,
    required MessageType type,
    String? caption,
    String? mimeType,
    int? durationMs,
    ReplyTo? replyTo,
  }) async {
    final currentUid = _currentUid;
    if (currentUid == null) {
      throw Exception('Not authenticated');
    }

    final clientMsgId = _uuid.v4();
    final messageRef = _chatsCollection.doc(chatId).collection('messages').doc();
    
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final storagePath = 'chat_media/$chatId/${messageRef.id}/$fileName';

    try {
      // 1. Upload file to Storage
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: mimeType ?? _getMimeType(fileName),
      );
      
      final uploadTask = ref.putFile(file, metadata);
      
      // Wait for upload
      await uploadTask;
      
      // Get download URL
      final mediaUrl = await ref.getDownloadURL();

      // 2. Create message document
      final message = Message(
        id: messageRef.id,
        senderId: currentUid,
        type: type,
        text: caption,
        mediaUrl: mediaUrl,
        mediaPath: storagePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType ?? _getMimeType(fileName),
        durationMs: durationMs,
        createdAt: DateTime.now(),
        clientMsgId: clientMsgId,
        replyTo: replyTo,
        status: MessageStatus.sent,
      );

      final batch = _firestore.batch();

      // Add message
      batch.set(messageRef, message.toFirestore());

      // Update chat last_message
      final previewText = message.getPreviewText();
      batch.update(_chatsCollection.doc(chatId), {
        'last_message': {
          'text': previewText,
          'type': type.toJson(),
          'sender_id': currentUid,
          'created_at': FieldValue.serverTimestamp(),
        },
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update sender's userChats
      batch.update(_userChatsCollection(currentUid).doc(chatId), {
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return message;
    } catch (e) {
      print('❌ ChatRepository: Error sending media: $e');
      rethrow;
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/m4a';
      case '.aac':
        return 'audio/aac';
      case '.wav':
        return 'audio/wav';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  // ============== Read Receipts ==============

  /// Mark a chat as read (update last_read_at in userChats)
  Future<void> markChatRead(String chatId) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    try {
      await _userChatsCollection(currentUid).doc(chatId).update({
        'last_read_at': FieldValue.serverTimestamp(),
      });
      print('✅ ChatRepository: Marked $chatId as read');
    } catch (e) {
      print('❌ ChatRepository: Error marking chat as read: $e');
    }
  }

  /// Get unread count for a chat based on last_read_at
  Stream<int> subscribeToUnreadCount(String chatId) {
    final currentUid = _currentUid;
    if (currentUid == null) {
      return Stream.value(0);
    }

    // This is a simplified approach - count messages after last_read_at
    // For accurate counts, consider using a Cloud Function
    return _userChatsCollection(currentUid)
        .doc(chatId)
        .snapshots()
        .asyncMap((userChatDoc) async {
      if (!userChatDoc.exists) return 0;

      final data = userChatDoc.data();
      final lastReadAt = (data?['last_read_at'] as Timestamp?)?.toDate();
      
      if (lastReadAt == null) {
        // Never read - count all messages not from current user
        final snapshot = await _chatsCollection
            .doc(chatId)
            .collection('messages')
            .where('sender_id', isNotEqualTo: currentUid)
            .count()
            .get();
        return snapshot.count ?? 0;
      }

      // Count messages after last_read_at not from current user
      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: currentUid)
          .where('created_at', isGreaterThan: Timestamp.fromDate(lastReadAt))
          .count()
          .get();
      return snapshot.count ?? 0;
    });
  }

  // ============== Chat Members ==============

  /// Get members of a chat
  Future<List<ChatMember>> getChatMembers(String chatId) async {
    try {
      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('members')
          .get();

      return snapshot.docs
          .map((doc) => ChatMember.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ ChatRepository: Error getting chat members: $e');
      return [];
    }
  }

  /// Toggle mute for a chat
  Future<void> toggleMute(String chatId, bool muted) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    try {
      final batch = _firestore.batch();

      // Update in members subcollection
      batch.update(
        _chatsCollection.doc(chatId).collection('members').doc(currentUid),
        {'muted': muted},
      );

      // Update in userChats
      batch.update(
        _userChatsCollection(currentUid).doc(chatId),
        {'muted': muted},
      );

      await batch.commit();
    } catch (e) {
      print('❌ ChatRepository: Error toggling mute: $e');
    }
  }

  /// Toggle pin for a chat
  Future<void> togglePin(String chatId, bool pinned) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    try {
      await _userChatsCollection(currentUid).doc(chatId).update({
        'pinned': pinned,
      });
    } catch (e) {
      print('❌ ChatRepository: Error toggling pin: $e');
    }
  }
}
