import 'dart:convert';
import 'package:el_race/ui/presentation/tasks/data/assignable_user_model.dart';
import 'package:el_race/ui/presentation/tasks/data/task_model.dart';
import 'package:http/http.dart' as http;

class TasksApiException implements Exception {
  final String message;
  final int? code;
  TasksApiException(this.message, {this.code});

  @override
  String toString() => 'TasksApiException(code: $code, message: $message)';
}

class TasksUnauthorizedException extends TasksApiException {
  TasksUnauthorizedException() : super('Unauthorized', code: 401);
}

class TasksApiService {
  final String baseUrl;
  final http.Client _client;

  TasksApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? 'https://erp.elrace.com',
        _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _getWithBody({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final request = http.Request('GET', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);
    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }

  void _guardStatus(http.Response response) {
    if (response.statusCode == 401) {
      throw TasksUnauthorizedException();
    }
    if (response.statusCode >= 500) {
      throw TasksApiException('Server error', code: response.statusCode);
    }
  }

  dynamic _decodeResult(http.Response response) {
    final decoded = jsonDecode(response.body);
    final result = decoded['result'];
    return result;
  }

  Future<List<TaskModel>> fetchTasks({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/get_user_tasks');
    final response = await _getWithBody(
      uri: uri,
      headers: _headers(token),
      body: {'jsonrpc': '2.0'},
    );

    _guardStatus(response);
    if (response.statusCode != 200) {
      throw TasksApiException('Failed to fetch tasks',
          code: response.statusCode);
    }

    final result = _decodeResult(response);

    // Print response for debugging
    print('====== GET USER TASKS RESPONSE ======');
    print('Result: $result');
    print('=====================================');

    if (result is Map && result['success'] == true) {
      final data = result['data'];
      print('Tasks data: $data');
      if (data is List) {
        return data
            .map((e) => e is Map<String, dynamic>
                ? TaskModel.fromJson(e)
                : TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return const [];
    }

    final message =
        (result is Map ? result['message'] : null) ?? 'Unable to fetch tasks';
    throw TasksApiException(message);
  }

  Future<List<AssignableUser>> fetchAssignableUsers(
      {required String token}) async {
    final uri = Uri.parse('$baseUrl/api/get_assignable_users');
    final response = await _getWithBody(
      uri: uri,
      headers: _headers(token),
      body: {'jsonrpc': '2.0'},
    );
    _guardStatus(response);
    if (response.statusCode != 200) {
      throw TasksApiException('Failed to fetch assignable users',
          code: response.statusCode);
    }

    final result = _decodeResult(response);
    if (result is Map && result['status'] == 'success') {
      final data = result['data'];
      if (data is List) {
        return data
            .map((e) => AssignableUser.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    throw TasksApiException(
        (result is Map ? result['message'] : null) ?? 'Unable to fetch users');
  }

  Future<TaskModel> createTask({
    required String token,
    required String name,
    String? description,
    String? priority,
    int? userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/create_task');
    final params = <String, dynamic>{
      'name': name,
      'description': description ?? '',
      'priority': priority ?? '3',
    };
    if (userId != null) {
      params['user_id'] = userId;
    }
    final response = await _getWithBody(
      uri: uri,
      headers: _headers(token),
      body: {
        'jsonrpc': '2.0',
        'params': params,
      },
    );

    _guardStatus(response);
    if (response.statusCode != 200) {
      throw TasksApiException('Failed to create task',
          code: response.statusCode);
    }

    final result = _decodeResult(response);
    if (result is Map && result['status'] == 'success') {
      final data = result['data'];
      if (data is Map) {
        return TaskModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw TasksApiException('Unexpected task payload');
    }

    throw TasksApiException(
        (result is Map ? result['message'] : null) ?? 'Unable to create task');
  }

  Future<String> submitTask(
      {required String token, required int taskId}) async {
    final uri = Uri.parse('$baseUrl/api/submit_task');
    final response = await _getWithBody(
      uri: uri,
      headers: _headers(token),
      body: {
        'jsonrpc': '2.0',
        'params': {
          'task_id': taskId,
        },
      },
    );

    _guardStatus(response);
    if (response.statusCode != 200) {
      throw TasksApiException('Failed to submit task',
          code: response.statusCode);
    }

    final result = _decodeResult(response);
    if (result is Map && result['status'] == 'success') {
      return (result['message'] as String?) ?? 'Task submitted';
    }

    throw TasksApiException(
        (result is Map ? result['message'] : null) ?? 'Unable to submit task');
  }

  Future<String> linkReportToTask({
    required String token,
    required int taskId,
    required String reportId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/link_report_to_task');
    final response = await _getWithBody(
      uri: uri,
      headers: _headers(token),
      body: {
        'jsonrpc': '2.0',
        'params': {
          'task_id': taskId,
          'report_id': reportId,
        },
      },
    );

    _guardStatus(response);
    if (response.statusCode != 200) {
      throw TasksApiException('Failed to link report',
          code: response.statusCode);
    }

    final result = _decodeResult(response);
    if (result is Map && result['status'] == 'success') {
      return (result['message'] as String?) ?? 'Report linked to task';
    }

    throw TasksApiException(
        (result is Map ? result['message'] : null) ?? 'Unable to link report');
  }
}
