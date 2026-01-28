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

  Future<List<MyActionItem>> fetchByType(MyActionsType type) async {
    final token = SharedPref.getLoginDataOrNull()?.result?.token;
    if (token == null || token.isEmpty) {
      throw Exception('Invalid token');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = {
      'jsonrpc': '2.0',
      'params': {
        'type': type.apiValue,
      },
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
    final result = json['result'];
    if (result is! Map) {
      throw Exception('Malformed my_actions response');
    }

    final status = result['status']?.toString();
    if (status != 'success') {
      final message = result['message']?.toString() ?? 'Unknown error';
      throw Exception(message);
    }

    final data = result['data'];
    if (data is! Map) {
      return const <MyActionItem>[];
    }

    final list = data[type.responseKey];
    if (list is! List) {
      return const <MyActionItem>[];
    }

    return list
        .whereType<Map>()
        .map((e) => MyActionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
