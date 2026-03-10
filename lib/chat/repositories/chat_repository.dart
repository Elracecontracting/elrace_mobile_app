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
        'member_ids': FieldValue.arrayUnion(dmPair),
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
        'member_ids': FieldValue.arrayUnion([uid]),
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

  // ============== Support Chat (Helpdesk) ==============

  /// Create or get a support chat between a user and a department group.
  /// The user sees it as a DM with the group name.
  /// Group members see it as individual conversations per user (ticket-style).
  /// Group members can reply anonymously (user sees group name, not individual).
  Future<String> createOrGetSupportChat({
    required String userUid,
    required String userName,
    required int targetRoleId,
    required String groupTitle, // e.g. "HR"
    int? userRoleId,
    int? userBranchId,
    int? userCompanyId,
  }) async {
    final chatId = Chat.generateSupportChatId(
      roleId: targetRoleId,
      userUid: userUid,
    );

    try {
      final batch = _firestore.batch();

      // Create/update support chat document
      final chatRef = _chatsCollection.doc(chatId);
      batch.set(chatRef, {
        'type': 'support',
        'role_id': targetRoleId,
        'support_user_uid': userUid,
        'title': groupTitle,
        'member_ids': FieldValue.arrayUnion([userUid]),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add the external user as member
      final userMemberRef = chatRef.collection('members').doc(userUid);
      batch.set(userMemberRef, {
        'joined_at': FieldValue.serverTimestamp(),
        'role_id_snapshot': userRoleId,
        'branch_id_snapshot': userBranchId,
        'company_id_snapshot': userCompanyId,
        'muted': false,
        'is_support_user': true, // Mark as the external user
      }, SetOptions(merge: true));

      // Create userChats entry for the external user (sees group name)
      final userChatRef = _userChatsCollection(userUid).doc(chatId);
      batch.set(userChatRef, {
        'type': 'support',
        'role_id': targetRoleId,
        'title': groupTitle, // User sees "HR Group"
        'support_user_uid': userUid,
        'support_group_title': groupTitle,
        'updated_at': FieldValue.serverTimestamp(),
        'pinned': false,
        'muted': false,
      }, SetOptions(merge: true));

      await batch.commit();

      // Now add all role group members to this support chat
      await _addRoleMembersToSupportChat(
        chatId: chatId,
        targetRoleId: targetRoleId,
        userName: userName,
        userUid: userUid,
        groupTitle: groupTitle,
      );

      print('✅ ChatRepository: Created/updated support chat $chatId');
      return chatId;
    } catch (e) {
      print('❌ ChatRepository: Error creating support chat: $e');
      rethrow;
    }
  }

  /// Add all members of a role group to a support chat.
  /// Each group member sees the chat titled with the user's name (ticket-style).
  Future<void> _addRoleMembersToSupportChat({
    required String chatId,
    required int targetRoleId,
    required String userName,
    required String userUid,
    required String groupTitle,
  }) async {
    try {
      // Find the role chat to get its members
      final roleChatId = Chat.generateRoleChatId(roleId: targetRoleId);
      final membersSnapshot = await _chatsCollection
          .doc(roleChatId)
          .collection('members')
          .get();

      if (membersSnapshot.docs.isEmpty) {
        print('⚠️ ChatRepository: No members found in role chat $roleChatId');
        return;
      }

      final batch = _firestore.batch();
      final memberUids = <String>[];

      for (final memberDoc in membersSnapshot.docs) {
        final memberUid = memberDoc.id;
        if (memberUid == userUid) continue; // Skip the external user (already added)

        memberUids.add(memberUid);
        final memberData = memberDoc.data();

        // Add as member of support chat
        final memberRef = _chatsCollection
            .doc(chatId)
            .collection('members')
            .doc(memberUid);
        batch.set(memberRef, {
          'joined_at': FieldValue.serverTimestamp(),
          'role_id_snapshot': memberData['role_id_snapshot'],
          'branch_id_snapshot': memberData['branch_id_snapshot'],
          'company_id_snapshot': memberData['company_id_snapshot'],
          'muted': false,
          'is_support_user': false, // Mark as group member
        }, SetOptions(merge: true));

        // Create userChats entry for group member (sees user's name)
        final memberChatRef = _userChatsCollection(memberUid).doc(chatId);
        batch.set(memberChatRef, {
          'type': 'support',
          'role_id': targetRoleId,
          'title': userName, // Group member sees "محمد أحمد"
          'peer_uid': userUid, // To identify the external user
          'support_user_uid': userUid,
          'support_group_title': groupTitle,
          'updated_at': FieldValue.serverTimestamp(),
          'pinned': false,
          'muted': false,
        }, SetOptions(merge: true));
      }

      // Update chat member_ids array
      if (memberUids.isNotEmpty) {
        batch.update(_chatsCollection.doc(chatId), {
          'member_ids': FieldValue.arrayUnion(memberUids),
        });
      }

      await batch.commit();
      print('✅ ChatRepository: Added ${memberUids.length} role members to support chat $chatId');
    } catch (e) {
      print('❌ ChatRepository: Error adding role members to support chat: $e');
    }
  }

  /// Get all available role groups for support chat.
  /// Returns role chats that the current user is NOT a member of.
  Future<List<Chat>> getAvailableSupportGroups() async {
    final currentUid = _currentUid;
    if (currentUid == null) return [];

    try {
      // Get all role chats
      final roleChatSnapshot = await _chatsCollection
          .where('type', isEqualTo: 'role')
          .get();

      final availableGroups = <Chat>[];

      for (final doc in roleChatSnapshot.docs) {
        // Check if current user is NOT a member of this role chat
        final memberDoc = await doc.reference
            .collection('members')
            .doc(currentUid)
            .get();

        if (!memberDoc.exists) {
          availableGroups.add(Chat.fromFirestore(doc));
        }
      }

      return availableGroups;
    } catch (e) {
      print('❌ ChatRepository: Error getting available support groups: $e');
      return [];
    }
  }

  /// Check if the current user is the support user (external) in a support chat.
  Future<bool> isSupportUser(String chatId) async {
    final currentUid = _currentUid;
    if (currentUid == null) return false;

    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) return false;
      final data = chatDoc.data() as Map<String, dynamic>? ?? {};
      return data['support_user_uid'] == currentUid;
    } catch (e) {
      return false;
    }
  }

  /// Get role member UIDs for a support chat (for updating all member userChats on new message)
  Future<List<String>> _getSupportChatMemberUids(String chatId) async {
    try {
      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('members')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

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

      // For support chats, update all members' userChats timestamps
      if (chatId.startsWith('support_')) {
        _updateSupportChatMemberTimestamps(chatId, currentUid);
      }

      // Clear typing status
      await PresenceService.instance.setTyping(chatId, false);

      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      print('❌ ChatRepository: Error sending text message: $e');
      rethrow;
    }
  }

  /// Update all support chat members' userChats timestamps (fire-and-forget)
  Future<void> _updateSupportChatMemberTimestamps(String chatId, String excludeUid) async {
    try {
      final memberUids = await _getSupportChatMemberUids(chatId);
      final batch = _firestore.batch();
      for (final uid in memberUids) {
        if (uid == excludeUid) continue; // Already updated in the main batch
        batch.update(_userChatsCollection(uid).doc(chatId), {
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('⚠️ ChatRepository: Error updating support chat member timestamps: $e');
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

    // Verify file exists before attempting upload
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }

    final clientMsgId = _uuid.v4();
    final messageRef = _chatsCollection.doc(chatId).collection('messages').doc();
    
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final storagePath = 'chat_media/$chatId/${messageRef.id}/$fileName';

    try {
      // 1. Upload file to Storage
      print('📤 ChatRepository: Uploading to path: $storagePath');
      print('📤 ChatRepository: Storage bucket: ${_storage.bucket}');
      print('📤 ChatRepository: Current user UID: $currentUid');
      print('📤 ChatRepository: File exists: ${await file.exists()}, size: $fileSize');
      
      // Check Firebase Auth state
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('Firebase Auth: No user signed in. Cannot upload to Storage.');
      }
      print('📤 ChatRepository: Auth user email: ${authUser.email}, isAnonymous: ${authUser.isAnonymous}');
      
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: mimeType ?? _getMimeType(fileName),
        customMetadata: {
          'uploadedBy': currentUid,
          'chatId': chatId,
        },
      );
      
      // Read file bytes and use putData for better compatibility
      final fileBytes = await file.readAsBytes();
      print('📤 ChatRepository: Read ${fileBytes.length} bytes, starting upload...');
      
      final uploadTask = ref.putData(fileBytes, metadata);
      
      // Listen to upload progress for debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 ChatRepository: Upload progress: ${progress.toStringAsFixed(1)}%');
      }, onError: (e) {
        print('❌ ChatRepository: Upload stream error: $e');
      });
      
      // Wait for upload
      final snapshot = await uploadTask;
      print('📤 ChatRepository: Upload complete, state: ${snapshot.state}');
      
      // Get download URL
      final mediaUrl = await ref.getDownloadURL();
      print('📤 ChatRepository: Download URL obtained: ${mediaUrl.substring(0, 50)}...');

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

      // For support chats, update all members' userChats timestamps
      if (chatId.startsWith('support_')) {
        _updateSupportChatMemberTimestamps(chatId, currentUid);
      }

      return message;
    } on FirebaseException catch (e) {
      print('❌ ChatRepository: Firebase error sending media:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Plugin: ${e.plugin}');
      print('   Storage bucket: ${_storage.bucket}');
      print('   Path attempted: $storagePath');
      rethrow;
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

  // ============== Starred Messages ==============

  /// Star a message (stored per-user in userChats/{uid}/starred_messages/{messageId})
  Future<void> starMessage(String chatId, Message message) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    try {
      await _firestore
          .collection('userChats')
          .doc(currentUid)
          .collection('starred_messages')
          .doc(message.id)
          .set({
        'chat_id': chatId,
        'message_id': message.id,
        'sender_id': message.senderId,
        'type': message.type.toJson(),
        'text': message.text,
        'media_url': message.mediaUrl,
        'file_name': message.fileName,
        'file_size': message.fileSize,
        'mime_type': message.mimeType,
        'duration_ms': message.durationMs,
        'created_at': Timestamp.fromDate(message.createdAt),
        'starred_at': FieldValue.serverTimestamp(),
      });
      print('⭐ ChatRepository: Starred message ${message.id}');
    } catch (e) {
      print('❌ ChatRepository: Error starring message: $e');
    }
  }

  /// Unstar a message
  Future<void> unstarMessage(String messageId) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    try {
      await _firestore
          .collection('userChats')
          .doc(currentUid)
          .collection('starred_messages')
          .doc(messageId)
          .delete();
      print('⭐ ChatRepository: Unstarred message $messageId');
    } catch (e) {
      print('❌ ChatRepository: Error unstarring message: $e');
    }
  }

  /// Check if a message is starred
  Future<bool> isMessageStarred(String messageId) async {
    final currentUid = _currentUid;
    if (currentUid == null) return false;

    try {
      final doc = await _firestore
          .collection('userChats')
          .doc(currentUid)
          .collection('starred_messages')
          .doc(messageId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to starred message IDs (returns Set of message IDs for quick lookup)
  Stream<Set<String>> subscribeToStarredMessageIds() {
    final currentUid = _currentUid;
    if (currentUid == null) return Stream.value({});

    return _firestore
        .collection('userChats')
        .doc(currentUid)
        .collection('starred_messages')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  /// Get all starred messages stream
  Stream<List<Map<String, dynamic>>> subscribeToStarredMessages() {
    final currentUid = _currentUid;
    if (currentUid == null) return Stream.value([]);

    return _firestore
        .collection('userChats')
        .doc(currentUid)
        .collection('starred_messages')
        .orderBy('starred_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
