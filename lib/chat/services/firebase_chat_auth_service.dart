import 'dart:async';
import 'dart:convert';
import 'dart:math' show min, max;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/models.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';
import 'presence_service.dart';
import 'chat_notification_service.dart';

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
  
  FirebaseChatAuthService._() {
    // Enable Firebase Auth persistence (automatic session storage)
    _auth.setPersistence(Persistence.LOCAL).catchError((error) {
      print('⚠️ FirebaseChatAuth: Could not set persistence: $error');
    });
  }

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
      // Check if already signed in with correct UID
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == session.firebaseUid) {
        print('✅ FirebaseChatAuth: Already signed in as ${currentUser.uid}');
        print('⏭️ FirebaseChatAuth: Skipping sign-in, proceeding to setup...');
      } else {
        // Step 1: Sign in to Firebase with custom token
        print('🔐 FirebaseChatAuth: Signing in with custom token...');
        
        // Clean and fix token format issues
        String token = _cleanFirebaseToken(session.firebaseCustomToken!);
        
        // Debug: Log token info (first/last chars only for security)
        print('🔐 FirebaseChatAuth: Token length: ${token.length}');
        print('🔐 FirebaseChatAuth: Token preview: ${token.substring(0, min(20, token.length))}...${token.substring(max(0, token.length - 20))}');
        
        // Validate token format (should be JWT: xxx.yyy.zzz)
        if (!token.contains('.') || token.split('.').length != 3) {
          print('❌ FirebaseChatAuth: Invalid token format - not a valid JWT');
          return ChatSetupResult.failed(
            'Invalid Firebase token format from backend. Please contact support.',
          );
        }
        
        final userCredential = await _auth.signInWithCustomToken(token);

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
      }

      final firebaseUid = _auth.currentUser!.uid;

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
        title: session.roleName, // Use role name as chat title
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

      // Step 7: Initialize chat notifications
      print('🔔 FirebaseChatAuth: Setting up chat notifications...');
      await ChatNotificationService.instance.initialize();
      await ChatNotificationService.instance.startListening();

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
  /// 
  /// Returns true if already authenticated with valid token,
  /// or if reauthentication succeeded. Returns false if token expired
  /// and needs fresh token from backend.
  Future<bool> reauthenticate() async {
    // Check if user is already signed in with correct UID
    if (_auth.currentUser != null && _currentSession != null) {
      if (_auth.currentUser!.uid == _currentSession!.firebaseUid) {
        print('✅ FirebaseChatAuth: User already authenticated as ${_auth.currentUser!.uid}');
        return true;
      } else {
        print('⚠️ FirebaseChatAuth: UID mismatch. Current: ${_auth.currentUser!.uid}, Expected: ${_currentSession!.firebaseUid}');
      }
    }
    
    // Try to reauthenticate with stored token
    if (_currentSession == null || !_currentSession!.isChatAvailable) {
      print('⚠️ FirebaseChatAuth: No session or token available for reauthentication');
      return false;
    }

    try {
      print('🔄 FirebaseChatAuth: Attempting reauthentication with stored token...');
      final cleanToken = _cleanFirebaseToken(_currentSession!.firebaseCustomToken!);
      await _auth.signInWithCustomToken(cleanToken);
      print('✅ FirebaseChatAuth: Reauthentication successful');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseChatAuth: Reauthentication failed - ${e.code}: ${e.message}');
      
      // Token expired or invalid - need fresh token from backend
      if (e.code == 'invalid-custom-token' || e.code == 'custom-token-expired') {
        print('⚠️ FirebaseChatAuth: Token expired. Need fresh token from backend.');
      }
      
      return false;
    } catch (e) {
      print('❌ FirebaseChatAuth: Reauthentication error: $e');
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

      // Dispose notification service
      await ChatNotificationService.instance.dispose();

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
  
  /// Clean Firebase custom token by stripping surrounding whitespace only.
  /// 
  /// IMPORTANT: Do NOT modify the JWT content (header/payload). The signature
  /// is computed over the exact original bytes. Changing even whitespace inside
  /// the decoded JSON header invalidates the signature.
  String _cleanFirebaseToken(String rawToken) {
    try {
      print('🧹 Cleaning token...');
      
      // Only trim leading/trailing whitespace and newlines
      String token = rawToken.trim();
      
      print('🔍 Original length: ${rawToken.length}, Cleaned length: ${token.length}');
      
      // Validate it has 3 JWT parts
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ Token does not have 3 parts (has ${parts.length}), returning as-is');
        return token;
      }
      
      // Debug: decode header for logging only (do NOT modify)
      try {
        String headerPart = parts[0];
        String padded = headerPart;
        while (padded.length % 4 != 0) {
          padded += '=';
        }
        final decoded = base64Url.decode(padded);
        final headerJson = utf8.decode(decoded);
        print('🔍 Token header: $headerJson');
      } catch (e) {
        print('⚠️ Could not decode header for logging: $e');
      }
      
      print('✅ Token ready: ${token.length} chars');
      print('🔐 FirebaseChatAuth: Token preview: ${token.substring(0, 20)}...${token.substring(token.length - 20)}');
      
      return token;
    } catch (e) {
      print('❌ Error cleaning token: $e');
      return rawToken.trim();
    }
  }
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
