import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/models.dart';
import 'services/services.dart';
import 'services/chat_session_storage.dart';

/// Chat module initialization helper.
/// 
/// Use this class to initialize the chat module after backend login
/// or to restore chat session on app restart.
class ChatModuleHelper {
  static final ChatModuleHelper _instance = ChatModuleHelper._();
  static ChatModuleHelper get instance => _instance;
  
  ChatModuleHelper._();

  bool _isInitialized = false;
  ChatSetupResult? _lastResult;
  ChatUserSession? _currentSession;

  /// Check if chat module is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if chat is enabled and ready to use
  bool get isChatEnabled => _lastResult?.chatEnabled ?? false;
  
  /// Get current role chat ID
  String? get roleChatId => _lastResult?.roleChatId;
  
  /// Get current Firebase UID
  String? get currentUid => _lastResult?.firebaseUid;
  
  /// Get current session
  ChatUserSession? get currentSession => _currentSession;

  /// Initialize chat from login response.
  /// 
  /// Call this immediately after successful backend login.
  /// 
  /// ```dart
  /// // In your login handler:
  /// if (loginResponse.result?.success == true) {
  ///   await ChatModuleHelper.instance.initializeFromLoginResponse(
  ///     loginResponse.toJson(),
  ///   );
  /// }
  /// ```
  Future<ChatSetupResult> initializeFromLoginResponse(
    Map<String, dynamic> loginResponseJson,
  ) async {
    try {
      print('🔷 ChatModuleHelper: Initializing from login response...');
      
      final session = ChatUserSession.fromLoginResponse(loginResponseJson);
      _currentSession = session;
      
      // Log session info (without sensitive data)
      print('🔷 ChatModuleHelper: Session created:');
      print('   - Firebase UID: ${session.firebaseUid}');
      print('   - Odoo User ID: ${session.odooUserId}');
      print('   - Employee ID: ${session.employeeId}');
      print('   - Role ID: ${session.roleId}');
      print('   - Branch ID: ${session.branchId}');
      print('   - Company ID: ${session.companyId}');
      print('   - Chat Available: ${session.isChatAvailable}');
      print('   - Has Firebase Token: ${session.firebaseCustomToken != null}');
      
      if (!session.isChatAvailable) {
        print('⚠️ ChatModuleHelper: Chat not available - no Firebase custom token');
        _lastResult = ChatSetupResult.disabled(
          'Firebase custom token not provided by backend. '
          'Backend needs to add firebase_custom_token field to login response.',
        );
        return _lastResult!;
      }

      // Setup Firebase chat
      _lastResult = await FirebaseChatAuthService.instance
          .setupAfterBackendLogin(session);

      if (_lastResult!.success && _lastResult!.chatEnabled) {
        _isInitialized = true;
        
        // Initialize lifecycle observer for presence
        ChatLifecycleObserver.instance.initialize();
        
        // Request notification permissions (non-blocking)
        FirebaseChatAuthService.instance.requestNotificationPermissions();
        
        print('✅ ChatModuleHelper: Chat initialized successfully');
        print('   - Role Chat ID: ${_lastResult!.roleChatId}');
      } else {
        print('⚠️ ChatModuleHelper: Chat setup completed but not enabled');
        print('   - Error: ${_lastResult!.error}');
      }

      return _lastResult!;
    } catch (e, stack) {
      print('❌ ChatModuleHelper: Error initializing chat: $e');
      print(stack);
      _lastResult = ChatSetupResult.failed(e.toString());
      return _lastResult!;
    }
  }

  /// Restore chat session from stored login data.
  /// 
  /// Call this on app startup if user is already logged in.
  /// 
  /// ```dart
  /// // In main.dart or splash screen:
  /// if (SharedPref.isUserAuthenticated()) {
  ///   await ChatModuleHelper.instance.restoreFromStoredSession();
  /// }
  /// ```
  Future<ChatSetupResult?> restoreFromStoredSession() async {
    try {
      print('🔷 ChatModuleHelper: Attempting to restore from stored session...');
      
      // First check if user is already signed in to Firebase
      final isAlreadySignedIn = FirebaseChatAuthService.instance.isSignedIn;
      if (isAlreadySignedIn) {
        print('✅ ChatModuleHelper: User already signed in to Firebase');
        
        // If we have cached result and it's enabled, return it
        if (_isInitialized && _lastResult != null && _lastResult!.chatEnabled) {
          print('✅ ChatModuleHelper: Returning cached chat session');
          return _lastResult;
        }

        // Try to restore from secure storage cache (fast path - no Firestore)
        final cachedSession = await ChatSessionStorage.instance.loadSession();
        if (cachedSession != null && cachedSession.isFresh) {
          print('🔄 ChatModuleHelper: Restoring from secure storage cache...');
          
          final result = await FirebaseChatAuthService.instance
              .restoreFromCachedSession(cachedSession);

          if (result.success && result.chatEnabled) {
            _isInitialized = true;
            _lastResult = result;
            
            // Restore session model from cached data
            _currentSession = ChatUserSession(
              backendJwt: '',
              odooUserId: cachedSession.sessionData['odoo_user_id'] ?? 0,
              employeeId: cachedSession.sessionData['employee_id'],
              name: cachedSession.sessionData['name'] ?? '',
              email: cachedSession.sessionData['email'],
              roleId: cachedSession.sessionData['role_id'] ?? 0,
              roleName: cachedSession.sessionData['role_name'],
              branchId: cachedSession.sessionData['branch_id'],
              companyId: cachedSession.sessionData['company_id'] ?? 0,
              firebaseUid: cachedSession.firebaseUid,
              avatarUrl: cachedSession.sessionData['avatar_url'],
            );
            
            // Initialize lifecycle observer for presence
            ChatLifecycleObserver.instance.initialize();
            
            print('✅ ChatModuleHelper: Restored from secure cache successfully');
            print('   - Role Chat ID: ${result.roleChatId}');
            return result;
          } else {
            print('⚠️ ChatModuleHelper: Cached restore failed, trying full setup...');
          }
        }
      }
      
      // Fall back to full setup from SharedPreferences login response
      final prefs = await SharedPreferences.getInstance();
      final loginJson = prefs.getString('loginResponse');
      
      if (loginJson == null || loginJson.isEmpty) {
        print('ℹ️ ChatModuleHelper: No stored login response found');
        return null;
      }

      print('✅ ChatModuleHelper: Found stored login response (${loginJson.length} chars)');
      final decoded = jsonDecode(loginJson) as Map<String, dynamic>;
      
      // Debug: Check if firebase fields exist in stored data
      final data = decoded['result']?['data'] ?? decoded['data'];
      print('🔍 Stored data contains:');
      print('   - firebase_uid: ${data?['firebase_uid'] ?? "NOT FOUND"}'  );
      print('   - firebase_custom_token: ${data?['firebase_custom_token'] != null ? "EXISTS (${data['firebase_custom_token'].toString().length} chars)" : "NOT FOUND ❌"}');
      print('   - odoo_user_id: ${data?['odoo_user_id'] ?? "NOT FOUND"}');
      print('   - employee_id: ${data?['employee_id'] ?? "NOT FOUND"}');
      
      // If already initialized and signed in, just try to complete setup
      if (_isInitialized && isAlreadySignedIn) {
        print('🔷 ChatModuleHelper: Already initialized and signed in, verifying setup...');
        if (_lastResult != null && _lastResult!.chatEnabled) {
          print('✅ ChatModuleHelper: Setup already complete');
          return _lastResult;
        }
      }
      
      // Try to initialize with stored data
      final result = await initializeFromLoginResponse(decoded);
      
      // If failed due to token expiry, provide clear message
      if (result.error != null && result.error!.contains('custom-token')) {
        print('⚠️ ChatModuleHelper: Token expired or invalid. User needs to login again.');
        return ChatSetupResult.failed(
          'Chat session expired. Please logout and login again to restore chat.',
        );
      }
      
      return result;
    } catch (e) {
      print('❌ ChatModuleHelper: Error restoring session: $e');
      
      // Provide user-friendly error message
      if (e.toString().contains('custom-token') || e.toString().contains('auth/')) {
        return ChatSetupResult.failed(
          'Chat session expired. Please logout and login again.',
        );
      }
      
      return ChatSetupResult.failed('Unable to restore chat: $e');
    }
  }

  /// Cleanup on logout.
  /// 
  /// Call this when user logs out.
  /// 
  /// ```dart
  /// // In your logout handler:
  /// await ChatModuleHelper.instance.cleanup();
  /// ```
  Future<void> cleanup() async {
    try {
      print('🔷 ChatModuleHelper: Cleaning up...');
      
      // Dispose lifecycle observer
      ChatLifecycleObserver.instance.dispose();
      
      // Sign out from Firebase and cleanup (also clears secure cache)
      await FirebaseChatAuthService.instance.signOut();
      
      _isInitialized = false;
      _lastResult = null;
      _currentSession = null;
      
      print('✅ ChatModuleHelper: Cleanup complete');
    } catch (e) {
      print('❌ ChatModuleHelper: Error during cleanup: $e');
    }
  }

  /// Check if chat should be shown based on current state.
  bool shouldShowChat() {
    return _isInitialized && isChatEnabled;
  }

  /// Get status message for UI display.
  String getStatusMessage() {
    if (!_isInitialized) {
      return 'Chat not initialized';
    }
    if (!isChatEnabled) {
      final error = _lastResult?.error ?? 'Chat not available';
      
      // Provide user-friendly messages
      if (error.contains('invalid-custom-token') || error.contains('token format')) {
        return 'Chat service error: Invalid authentication token from server.\nBackend needs to fix token generation.\nPlease contact IT support.';
      }
      if (error.contains('expired') || error.contains('login again')) {
        return 'Chat session expired. Please logout and login again.';
      }
      if (error.contains('custom token not provided')) {
        return 'Chat not configured on server. Contact IT support.';
      }
      
      return error;
    }
    return 'Chat ready';
  }
}
