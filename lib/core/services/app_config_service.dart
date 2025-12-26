import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:el_race/utils/urll_utils.dart';

/// Global app configuration fetched from backend
class AppConfigService {
  AppConfigService._internal();
  static final AppConfigService instance = AppConfigService._internal();

  static const _cacheKeyIsTestMode = 'app_config_is_test_mode';

  bool _isTestMode = false;
  bool get isTestMode => _isTestMode;

  /// Load config from remote API and cache locally
  Future<void> load() async {
    // Try read cached value first
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTestMode = prefs.getBool(_cacheKeyIsTestMode) ?? false;
    } catch (_) {}

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      const String url = '${UrlUtil.baseUrl}app/config';
      final resp = await dio.get(url);

      // Response can be jsonrpc envelope: { jsonrpc, id, result: { success, isTestMode } }
      final data = resp.data;
      bool? remoteIsTest;
      if (data is Map<String, dynamic>) {
        if (data['result'] is Map<String, dynamic>) {
          remoteIsTest =
              (data['result'] as Map<String, dynamic>)['isTestMode'] as bool?;
        } else if (data['isTestMode'] is bool) {
          remoteIsTest = data['isTestMode'] as bool;
        }
      } else if (data is String) {
        // Fallback if dio returned a string
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map<String, dynamic>) {
            if (parsed['result'] is Map<String, dynamic>) {
              remoteIsTest = (parsed['result']
                  as Map<String, dynamic>)['isTestMode'] as bool?;
            } else if (parsed['isTestMode'] is bool) {
              remoteIsTest = parsed['isTestMode'] as bool;
            }
          }
        } catch (_) {}
      }

      if (remoteIsTest != null) {
        _isTestMode = remoteIsTest;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_cacheKeyIsTestMode, _isTestMode);
        } catch (_) {}
      }

      if (kDebugMode) {
        debugPrint('AppConfigService: isTestMode=$_isTestMode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfigService: failed to load config: $e');
      }
      // Keep cached value
    }
  }
}
