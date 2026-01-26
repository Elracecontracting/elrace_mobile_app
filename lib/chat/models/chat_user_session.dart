/// Chat user session model that captures backend login response
/// for Firebase chat setup.
/// 
/// This model extracts and normalizes the fields needed for chat initialization
/// from the existing backend login response.
class ChatUserSession {
  /// Backend JWT token (for other API calls, not Firebase)
  final String backendJwt;
  
  /// Odoo user ID - MUST NOT be null
  final int odooUserId;
  
  /// Employee ID (optional)
  final int? employeeId;
  
  /// User's display name
  final String name;
  
  /// User's email (optional but desirable)
  final String? email;
  
  /// Role ID for role-based chat groups
  final int roleId;
  
  /// Branch ID (optional)
  final int? branchId;
  
  /// Company ID
  final int companyId;
  
  /// Firebase UID - expected format: "odoo_{odoo_user_id}"
  final String firebaseUid;
  
  /// Firebase custom token for signInWithCustomToken
  final String? firebaseCustomToken;
  
  /// Role chat ID (optional, backend may provide specific ID)
  final String? roleChatId;
  
  /// Avatar URL (must be URL, NOT base64)
  final String? avatarUrl;

  ChatUserSession({
    required this.backendJwt,
    required this.odooUserId,
    this.employeeId,
    required this.name,
    this.email,
    required this.roleId,
    this.branchId,
    required this.companyId,
    required this.firebaseUid,
    this.firebaseCustomToken,
    this.roleChatId,
    this.avatarUrl,
  });

  /// Create session from backend login response JSON.
  /// Call this when backend adds firebase_* fields to login response.
  factory ChatUserSession.fromLoginResponse(Map<String, dynamic> json) {
    final data = json['result']?['data'] ?? json['data'] ?? json;
    final token = json['result']?['token'] ?? json['token'] ?? '';
    
    final int odooUserId = _extractInt(data['uid']) ?? 
                           _extractInt(data['odoo_user_id']) ?? 
                           0;
    
    // Firebase UID: use provided or generate from odoo_user_id
    final String firebaseUid = data['firebase_uid']?.toString() ?? 
                               'odoo_$odooUserId';
    
    // Role ID extraction - try multiple possible field names
    final int roleId = _extractInt(data['role_id']) ?? 
                       _extractInt(data['default_role_id']) ?? 
                       0;
    
    return ChatUserSession(
      backendJwt: token,
      odooUserId: odooUserId,
      employeeId: _extractInt(data['emp_id']) ?? 
                  _extractInt(data['employee_id']),
      name: data['name']?.toString() ?? 
            data['emp_name']?.toString() ?? 
            data['username']?.toString() ?? 
            '',
      email: data['email']?.toString() ?? 
             data['username']?.toString(),
      roleId: roleId,
      branchId: _extractInt(data['branch_id']),
      companyId: _extractInt(data['company_id']) ?? 1,
      firebaseUid: firebaseUid,
      firebaseCustomToken: data['firebase_custom_token']?.toString(),
      roleChatId: data['role_chat_id']?.toString(),
      avatarUrl: _extractAvatarUrl(data['image_url'] ?? data['avatar_url']),
    );
  }

  /// Extract int from various possible types (int, String, etc.)
  static int? _extractInt(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Extract avatar URL, filtering out base64 data
  static String? _extractAvatarUrl(dynamic value) {
    if (value == null || value == false || value == '') return null;
    final str = value.toString();
    // Skip base64 images
    if (str.startsWith('data:') || str.length > 500) return null;
    // Only accept http/https URLs
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }
    return null;
  }

  /// Check if Firebase chat is available (has custom token)
  bool get isChatAvailable => firebaseCustomToken != null && 
                              firebaseCustomToken!.isNotEmpty;

  /// Computed role chat ID based on configuration
  String getRoleChatId({bool groupByBranch = false}) {
    if (roleChatId != null && roleChatId!.isNotEmpty) {
      return roleChatId!;
    }
    if (groupByBranch && branchId != null) {
      return 'role_${roleId}_branch_$branchId';
    }
    return 'role_$roleId';
  }

  /// Get FCM topic name for role group (sanitized)
  String getRoleTopicName({bool groupByBranch = false}) {
    final baseTopic = getRoleChatId(groupByBranch: groupByBranch);
    // Sanitize: only letters, numbers, underscores, hyphens allowed
    return baseTopic.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  @override
  String toString() => 'ChatUserSession(uid: $firebaseUid, name: $name, roleId: $roleId)';

  Map<String, dynamic> toJson() => {
    'backend_jwt': backendJwt,
    'odoo_user_id': odooUserId,
    'employee_id': employeeId,
    'name': name,
    'email': email,
    'role_id': roleId,
    'branch_id': branchId,
    'company_id': companyId,
    'firebase_uid': firebaseUid,
    'firebase_custom_token': firebaseCustomToken != null ? '***' : null,
    'role_chat_id': roleChatId,
    'avatar_url': avatarUrl,
  };

  factory ChatUserSession.fromJson(Map<String, dynamic> json) => ChatUserSession(
    backendJwt: json['backend_jwt'] ?? '',
    odooUserId: json['odoo_user_id'] ?? 0,
    employeeId: json['employee_id'],
    name: json['name'] ?? '',
    email: json['email'],
    roleId: json['role_id'] ?? 0,
    branchId: json['branch_id'],
    companyId: json['company_id'] ?? 1,
    firebaseUid: json['firebase_uid'] ?? '',
    firebaseCustomToken: json['firebase_custom_token'],
    roleChatId: json['role_chat_id'],
    avatarUrl: json['avatar_url'],
  );
}

/// Result of chat setup after backend login
class ChatSetupResult {
  final bool success;
  final String? firebaseUid;
  final String? error;
  final bool chatEnabled;
  final String? roleChatId;

  ChatSetupResult({
    required this.success,
    this.firebaseUid,
    this.error,
    this.chatEnabled = false,
    this.roleChatId,
  });

  factory ChatSetupResult.success({
    required String firebaseUid,
    required String roleChatId,
  }) => ChatSetupResult(
    success: true,
    firebaseUid: firebaseUid,
    chatEnabled: true,
    roleChatId: roleChatId,
  );

  factory ChatSetupResult.failed(String error) => ChatSetupResult(
    success: false,
    error: error,
    chatEnabled: false,
  );

  factory ChatSetupResult.disabled(String reason) => ChatSetupResult(
    success: true, // Not a failure, just not available
    error: reason,
    chatEnabled: false,
  );

  @override
  String toString() => 'ChatSetupResult(success: $success, chatEnabled: $chatEnabled, uid: $firebaseUid)';
}
