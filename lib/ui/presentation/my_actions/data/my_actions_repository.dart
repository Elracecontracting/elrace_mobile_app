import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:el_race/utils/urll_utils.dart';

class MyActionsRepository {
  final ApiQuery _apiQuery;

  MyActionsRepository({ApiQuery? apiQuery})
      : _apiQuery = apiQuery ?? ApiQuery();

  Future<List<MyActionItem>> fetchByType(
    MyActionsType type, {
    int page = 1,
    int perPage = 50,
    String keyword = '',
  }) async {
    final token = SharedPref.getLoginDataOrNull()?.result?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Invalid token');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> params = {
      'type': type.apiValue,
      'page': page,
      'per_page': perPage,
    };
    if (keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
    }

    final body = {
      'jsonrpc': '2.0',
      'params': params,
    };

    final Response? response = await _apiQuery.postQuery(
      UrlUtil.myActionsApi,
      headers,
      body,
      'my_actions_${type.apiValue}',
      true,
    );

    if (response == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode != 200) {
      throw Exception('My actions HTTP ${response.statusCode}');
    }

    final dynamic payload = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    if (payload is! Map) {
      throw Exception(
          'Unexpected my_actions payload type: ${payload.runtimeType}');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(payload);

    // Handle JSON-RPC error envelope from Odoo
    if (json.containsKey('error') && json['error'] is Map) {
      final err = Map<String, dynamic>.from(json['error'] as Map);
      // Odoo nests the real message inside error.data.message
      final errData = err['data'];
      String message;
      if (errData is Map) {
        message = errData['message']?.toString() ??
            errData['name']?.toString() ??
            err['message']?.toString() ??
            'Odoo Server Error';
      } else {
        message = err['message']?.toString() ?? 'Odoo Server Error';
      }
      print('[MyActions] Odoo error for type=${type.apiValue}: $message');
      throw Exception(message);
    }

    final result = json['result'];

    // result might be the list/data directly (no wrapping map)
    if (result is List) {
      return result
          .whereType<Map>()
          .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (result is! Map) {
      // Log for debugging, then return empty instead of crashing
      print(
          '[MyActions] Unexpected result type: ${result.runtimeType}, value: $result');
      return const <MyActionItem>[];
    }

    final status = result['status']?.toString();
    if (status != null && status != 'success') {
      final message = result['message']?.toString() ?? 'Unknown error';
      throw Exception(message);
    }

    // Try the expected nested structure first: result.data.<key>
    final data = result['data'];
    if (data is Map) {
      final list = data[type.responseKey];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    // Fallback: result.<key> directly (flat response)
    final directList = result[type.responseKey];
    if (directList is List) {
      return directList
          .whereType<Map>()
          .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Fallback: result.data is a list
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Fallback: result.records (some Odoo endpoints)
    final records = result['records'];
    if (records is List) {
      return records
          .whereType<Map>()
          .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return const <MyActionItem>[];
  }
}
