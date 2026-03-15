import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/models.dart';

/// Repository for user-related Firestore operations.
/// 
/// Handles:
/// - User profile upsert
/// - User search with keyword-based prefix matching
/// - FCM token management
class UserRepository {
  static UserRepository? _instance;
  static UserRepository get instance => _instance ??= UserRepository._();
  
  UserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// In-memory user cache to avoid repeated Firestore reads
  final Map<String, ChatUser> _userCache = {};
  /// Cache expiry tracking (5 minutes)
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(minutes: 5);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Upsert user profile in Firestore.
  /// Creates the document if it doesn't exist, updates if it does.
  Future<void> upsertUser(ChatUserSession session) async {
    final docRef = _usersCollection.doc(session.firebaseUid);
    final keywords = ChatUser.buildSearchKeywords(session.name, session.email);

    final data = {
      'odoo_user_id': session.odooUserId,
      'employee_id': session.employeeId,
      'name': session.name,
      'email': session.email,
      'role_name': session.roleName,
      'role_id': session.roleId,
      'branch_id': session.branchId,
      'company_id': session.companyId,
      'avatar_url': session.avatarUrl,
      'last_login_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'search_keywords': keywords,
    };

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        // Update existing user
        await docRef.update(data);
        print('✅ UserRepository: Updated user ${session.firebaseUid}');
      } else {
        // Create new user
        data['created_at'] = FieldValue.serverTimestamp();
        await docRef.set(data);
        print('✅ UserRepository: Created user ${session.firebaseUid}');
      }
    } catch (e) {
      print('❌ UserRepository: Error upserting user: $e');
      rethrow;
    }
  }

  /// Get a user by UID (cached)
  Future<ChatUser?> getUser(String uid) async {
    // Check cache first
    final cached = _userCache[uid];
    final cachedAt = _cacheTimestamps[uid];
    if (cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheDuration) {
      return cached;
    }

    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      final user = ChatUser.fromFirestore(doc);
      _userCache[uid] = user;
      _cacheTimestamps[uid] = DateTime.now();
      return user;
    } catch (e) {
      print('❌ UserRepository: Error getting user: $e');
      return cached; // Return stale cache on error
    }
  }

  /// Get a user from cache only (sync, no Firestore call)
  ChatUser? getCachedUser(String uid) => _userCache[uid];

  /// Pre-warm user cache for multiple UIDs
  Future<void> prefetchUsers(List<String> uids) async {
    final uncached = uids.where((uid) {
      final cachedAt = _cacheTimestamps[uid];
      return cachedAt == null || DateTime.now().difference(cachedAt) >= _cacheDuration;
    }).toList();
    if (uncached.isEmpty) return;
    final users = await getUsersByIds(uncached);
    for (final user in users) {
      _userCache[user.uid] = user;
      _cacheTimestamps[user.uid] = DateTime.now();
    }
  }

  /// Get user stream by UID
  Stream<ChatUser?> subscribeToUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatUser.fromFirestore(doc);
    });
  }

  /// Search users by fetching all and filtering client-side.
  /// No Firestore index required.
  Future<UserSearchResult> searchUsers({
    required String query,
    int limit = 20,
    DocumentSnapshot? startAfter,
    int? companyId, // Optional filter by company
  }) async {
    if (query.trim().isEmpty) {
      return UserSearchResult(users: [], hasMore: false);
    }

    final searchTerm = query.toLowerCase().trim();
    
    try {
      // Fetch all users (no complex query, no index needed)
      Query<Map<String, dynamic>> queryBuilder = _usersCollection;
      
      // If company filter, use simple where (single field, no index needed)
      if (companyId != null) {
        queryBuilder = queryBuilder.where('company_id', isEqualTo: companyId);
      }

      final snapshot = await queryBuilder.get();
      
      // Filter client-side by name or email
      final allUsers = snapshot.docs
          .map((doc) => ChatUser.fromFirestore(doc))
          .where((user) {
            final name = user.name.toLowerCase();
            final email = (user.email ?? '').toLowerCase();
            return name.contains(searchTerm) || email.contains(searchTerm);
          })
          .toList();
      
      // Sort by name
      allUsers.sort((a, b) => a.name.compareTo(b.name));
      
      // Apply limit
      final hasMore = allUsers.length > limit;
      final users = hasMore ? allUsers.sublist(0, limit) : allUsers;

      return UserSearchResult(
        users: users,
        hasMore: hasMore,
        lastDocument: null, // Not using pagination with this approach
      );
    } catch (e) {
      print('❌ UserRepository: Error searching users: $e');
      return UserSearchResult(users: [], hasMore: false, error: e.toString());
    }
  }

  /// Get multiple users by UIDs
  Future<List<ChatUser>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    
    try {
      // Firestore whereIn has a limit of 10, so batch if needed
      final users = <ChatUser>[];
      final batches = <List<String>>[];
      
      for (var i = 0; i < uids.length; i += 10) {
        final end = (i + 10 < uids.length) ? i + 10 : uids.length;
        batches.add(uids.sublist(i, end));
      }

      for (final batch in batches) {
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        users.addAll(snapshot.docs.map((doc) => ChatUser.fromFirestore(doc)));
      }

      return users;
    } catch (e) {
      print('❌ UserRepository: Error getting users by IDs: $e');
      return [];
    }
  }

  /// Update user's last seen timestamp
  Future<void> updateLastSeen(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'last_seen_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ UserRepository: Error updating last seen: $e');
    }
  }

  // ============== FCM Token Management ==============

  /// Store FCM token for user
  Future<void> storeFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('⚠️ UserRepository: FCM token is null');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      
      await _usersCollection
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'created_at': FieldValue.serverTimestamp(),
        'platform': platform,
      });

      print('✅ UserRepository: Stored FCM token for $uid');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _usersCollection
            .doc(uid)
            .collection('fcm_tokens')
            .doc(newToken)
            .set({
          'created_at': FieldValue.serverTimestamp(),
          'platform': platform,
        });
        print('✅ UserRepository: Updated FCM token for $uid');
      });
    } catch (e) {
      print('❌ UserRepository: Error storing FCM token: $e');
    }
  }

  /// Remove FCM token (e.g., on logout)
  Future<void> removeFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _usersCollection
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .delete();

      print('✅ UserRepository: Removed FCM token for $uid');
    } catch (e) {
      print('❌ UserRepository: Error removing FCM token: $e');
    }
  }

  /// Subscribe to FCM topic for role-based notifications
  Future<void> subscribeToRoleTopic(String topicName) async {
    try {
      await _messaging.subscribeToTopic(topicName);
      print('✅ UserRepository: Subscribed to topic $topicName');
    } catch (e) {
      print('❌ UserRepository: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromRoleTopic(String topicName) async {
    try {
      await _messaging.unsubscribeFromTopic(topicName);
      print('✅ UserRepository: Unsubscribed from topic $topicName');
    } catch (e) {
      print('❌ UserRepository: Error unsubscribing from topic: $e');
    }
  }
}

/// Result of user search with pagination support
class UserSearchResult {
  final List<ChatUser> users;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String? error;

  UserSearchResult({
    required this.users,
    required this.hasMore,
    this.lastDocument,
    this.error,
  });

  bool get hasError => error != null;
}
