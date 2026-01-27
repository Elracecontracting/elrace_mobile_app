import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/models.dart';
import 'services/services.dart';

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
      
      final prefs = await SharedPreferences.getInstance();
      final loginJson = prefs.getString('loginResponse');
      
      if (loginJson == null || loginJson.isEmpty) {
        print('ℹ️ ChatModuleHelper: No stored login response found');
        return null;
      }

      final decoded = jsonDecode(loginJson) as Map<String, dynamic>;
      return await initializeFromLoginResponse(decoded);
    } catch (e) {
      print('❌ ChatModuleHelper: Error restoring session: $e');
      return ChatSetupResult.failed(e.toString());
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
      
      // Sign out from Firebase and cleanup
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
      return _lastResult?.error ?? 'Chat not available';
    }
    return 'Chat ready';
  }
}
