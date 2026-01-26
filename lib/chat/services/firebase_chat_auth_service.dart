import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/models.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';
import 'presence_service.dart';

/// Main service for Firebase chat authentication and setup.
/// 
/// This service handles the complete setup flow after backend login:
/// 1. Sign in to Firebase using custom token
/// 2. Create/update user profile in Firestore
/// 3. Ensure role chat membership
/// 4. Subscribe to FCM topics
/// 5. Setup presence
/// 6. Store FCM token
class FirebaseChatAuthService {
  static FirebaseChatAuthService? _instance;
  static FirebaseChatAuthService get instance => 
      _instance ??= FirebaseChatAuthService._();
  
  FirebaseChatAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  ChatUserSession? _currentSession;
  String? _currentRoleChatId;
  bool _isSetupComplete = false;

  // Configuration
  static const bool groupByBranch = false; // Match with ChatRepository

  /// Get current user session
  ChatUserSession? get currentSession => _currentSession;
  
  /// Check if chat setup is complete
  bool get isSetupComplete => _isSetupComplete;
  
  /// Get current Firebase UID
  String? get currentUid => _auth.currentUser?.uid;
  
  /// Get current role chat ID
  String? get currentRoleChatId => _currentRoleChatId;

  /// Main setup method - call this after backend login success.
  /// 
  /// [session] - ChatUserSession created from backend login response
  /// 
  /// Returns ChatSetupResult indicating success/failure and chat availability.
  Future<ChatSetupResult> setupAfterBackendLogin(ChatUserSession session) async {
    _currentSession = session;
    _isSetupComplete = false;

    // Check if chat is available (has Firebase custom token)
    if (!session.isChatAvailable) {
      print('⚠️ FirebaseChatAuth: Chat not available - no Firebase custom token');
      return ChatSetupResult.disabled('Firebase custom token not provided by backend');
    }

    try {
      // Step 1: Sign in to Firebase with custom token
      print('🔐 FirebaseChatAuth: Signing in with custom token...');
      final userCredential = await _auth.signInWithCustomToken(
        session.firebaseCustomToken!,
      );

      final firebaseUid = userCredential.user?.uid;
      if (firebaseUid == null) {
        return ChatSetupResult.failed('Firebase sign-in succeeded but no UID returned');
      }

      // Verify UID matches expected (log warning if mismatch)
      if (firebaseUid != session.firebaseUid) {
        print('⚠️ FirebaseChatAuth: UID mismatch! Expected: ${session.firebaseUid}, Got: $firebaseUid');
        print('⚠️ FirebaseChatAuth: Using actual UID from Firebase: $firebaseUid');
      }

      print('✅ FirebaseChatAuth: Signed in as $firebaseUid');

      // Step 2: Create/update user profile in Firestore
      print('📝 FirebaseChatAuth: Upserting user profile...');
      await UserRepository.instance.upsertUser(session);

      // Step 3: Ensure role chat membership
      print('👥 FirebaseChatAuth: Ensuring role chat membership...');
      _currentRoleChatId = await ChatRepository.instance.ensureRoleChatMembership(
        uid: firebaseUid,
        roleId: session.roleId,
        branchId: session.branchId,
        companyId: session.companyId,
        roleChatId: session.roleChatId,
      );

      // Step 4: Subscribe to FCM topic for role group
      print('📲 FirebaseChatAuth: Subscribing to FCM topics...');
      final topicName = session.getRoleTopicName(groupByBranch: groupByBranch);
      await UserRepository.instance.subscribeToRoleTopic(topicName);

      // Step 5: Setup presence
      print('🟢 FirebaseChatAuth: Setting up presence...');
      await PresenceService.instance.initialize(firebaseUid);

      // Step 6: Store FCM token
      print('🔔 FirebaseChatAuth: Storing FCM token...');
      await UserRepository.instance.storeFcmToken(firebaseUid);

      _isSetupComplete = true;
      print('✅ FirebaseChatAuth: Setup complete!');

      return ChatSetupResult.success(
        firebaseUid: firebaseUid,
        roleChatId: _currentRoleChatId!,
      );
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseChatAuth: Firebase Auth error: ${e.code} - ${e.message}');
      return ChatSetupResult.failed('Firebase auth failed: ${e.message}');
    } catch (e) {
      print('❌ FirebaseChatAuth: Setup error: $e');
      return ChatSetupResult.failed('Chat setup failed: $e');
    }
  }

  /// Re-authenticate with existing session (e.g., on app resume if token expired).
  Future<bool> reauthenticate() async {
    if (_currentSession == null || !_currentSession!.isChatAvailable) {
      return false;
    }

    try {
      await _auth.signInWithCustomToken(_currentSession!.firebaseCustomToken!);
      return true;
    } catch (e) {
      print('❌ FirebaseChatAuth: Reauthentication failed: $e');
      return false;
    }
  }

  /// Sign out from Firebase and cleanup.
  Future<void> signOut() async {
    try {
      // Remove FCM token
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await UserRepository.instance.removeFcmToken(uid);
        
        // Unsubscribe from role topic
        if (_currentSession != null) {
          final topicName = _currentSession!.getRoleTopicName(groupByBranch: groupByBranch);
          await UserRepository.instance.unsubscribeFromRoleTopic(topicName);
        }
      }

      // Dispose presence service
      await PresenceService.instance.dispose();

      // Sign out from Firebase
      await _auth.signOut();

      _currentSession = null;
      _currentRoleChatId = null;
      _isSetupComplete = false;

      print('✅ FirebaseChatAuth: Signed out successfully');
    } catch (e) {
      print('❌ FirebaseChatAuth: Sign out error: $e');
    }
  }

  /// Request notification permissions (call during app initialization or login).
  Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;
      
      print('🔔 FirebaseChatAuth: Notification permission: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      print('❌ FirebaseChatAuth: Error requesting notification permission: $e');
      return false;
    }
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in to Firebase
  bool get isSignedIn => _auth.currentUser != null;
}

// ============== Push Notification Trigger Notes ==============
// 
// The client-side FCM token storage and topic subscription is implemented above.
// Actual push notification sending should be done via Cloud Functions.
// 
// Example Cloud Function (Node.js) for sending DM notifications:
// 
// ```javascript
// exports.onNewMessage = functions.firestore
//   .document('chats/{chatId}/messages/{messageId}')
//   .onCreate(async (snap, context) => {
//     const message = snap.data();
//     const chatId = context.params.chatId;
//     
//     // Get chat document
//     const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
//     const chat = chatDoc.data();
//     
//     if (chat.type === 'dm') {
//       // For DM: Send to other user's device tokens
//       const otherUid = chat.dm_pair.find(uid => uid !== message.sender_id);
//       const tokensSnapshot = await admin.firestore()
//         .collection('users').doc(otherUid).collection('fcm_tokens').get();
//       
//       const tokens = tokensSnapshot.docs.map(doc => doc.id);
//       if (tokens.length === 0) return;
//       
//       const payload = {
//         notification: {
//           title: senderName,
//           body: message.text || 'Sent a media',
//         },
//         data: {
//           chatId: chatId,
//           type: 'dm',
//         },
//       };
//       
//       await admin.messaging().sendToDevice(tokens, payload);
//     } else if (chat.type === 'role') {
//       // For role chat: Send to topic
//       const topic = `role_${chat.role_id}`;
//       const payload = {
//         notification: {
//           title: chat.title,
//           body: `${senderName}: ${message.text || 'Sent a media'}`,
//         },
//         data: {
//           chatId: chatId,
//           type: 'role',
//         },
//       };
//       
//       await admin.messaging().sendToTopic(topic, payload);
//     }
//   });
// ```
