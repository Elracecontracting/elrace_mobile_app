import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:el_race/core/utils/shared_pref.dart';

/// Model for team member fetched from backend
class TeamMember {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? jobPosition;
  final String? department;
  final String? image;

  const TeamMember({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.jobPosition,
    this.department,
    this.image,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      jobPosition: json['job_position'] as String?,
      department: json['department'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'job_position': jobPosition,
      'department': department,
      'image': image,
    };
  }

  @override
  String toString() => 'TeamMember(id: $id, name: $name)';
}

/// Service to fetch team members from backend API
/// This is the ONLY backend interaction for the task management system
class TeamMembersApiService {
  static TeamMembersApiService? _instance;
  static TeamMembersApiService get instance =>
      _instance ??= TeamMembersApiService._();

  TeamMembersApiService._();

  static const String _baseUrl = 'https://erp.elrace.com/api';
  static const String _employeeListEndpoint = '/employee/listx';

  // Cache for team members
  List<TeamMember>? _cachedMembers;
  DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 15);

  /// Get authorization headers
  Map<String, String> _getHeaders() {
    final token = SharedPref.getLoginData().result?.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all team members from backend
  /// Uses caching to minimize API calls
  Future<List<TeamMember>> getTeamMembers({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh &&
        _cachedMembers != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout) {
      print('📋 TeamMembersApiService: Returning cached members');
      return _cachedMembers!;
    }

    try {
      final url = Uri.parse('$_baseUrl$_employeeListEndpoint');
      final headers = _getHeaders();

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {},
      });

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employeesList =
            data['result']?['employees'] as List<dynamic>? ?? [];

        _cachedMembers = employeesList
            .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
            .toList();
        _lastFetchTime = DateTime.now();

        print(
            '✅ TeamMembersApiService: Fetched ${_cachedMembers!.length} members');
        return _cachedMembers!;
      } else {
        throw Exception('Failed to fetch members: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ TeamMembersApiService: Error fetching members: $e');
      // Return cached data if available
      if (_cachedMembers != null) {
        return _cachedMembers!;
      }
      rethrow;
    }
  }

  /// Search members by name
  Future<List<TeamMember>> searchMembers(String query) async {
    final members = await getTeamMembers();
    if (query.isEmpty) return members;

    final queryLower = query.toLowerCase();
    return members
        .where((m) => m.name.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Get member by ID
  Future<TeamMember?> getMemberById(int id) async {
    final members = await getTeamMembers();
    try {
      return members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedMembers = null;
    _lastFetchTime = null;
  }
}
