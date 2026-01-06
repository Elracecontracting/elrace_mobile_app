import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:el_race/utils/urll_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepo {
  ApiQuery apiQuery = ApiQuery();

  Future<Response> loginApiCall(
      String email, String password, String deviceId) async {
    // Get FCM token from SharedPreferences
    String? fcmToken = SharedPref().getPreferenceString(fcm_token);

    // If FCM token is null or empty, log a warning
    if (fcmToken.isEmpty) {
      log('⚠️ Warning: FCM token is empty during login');
    } else {
      log('✅ FCM token available for login: ${fcmToken.substring(0, 20)}...');
    }

    // Log device ID information
    log('📱 Device ID for login: $deviceId');

    Map<String, dynamic> body = {
      "jsonrpc": "2.0",
      "params": {
        "db": "odoo.elrace.com",
        "login": email,
        "password": password,
        "device_id": deviceId,
        "fcm_token": fcmToken,
      }
    };

    log('singIn: ${body.toString()}');
    var headers = {
      'Content-Type': 'application/json',
    };

    Response? response =
        await apiQuery.postQuery(UrlUtil.login, headers, body, 'login', true);
    debugPrint('singIn: ${response?.data}');
    return response!;
  }

  setLoginResponse(LoginResponseModel? loginResponse) async {
    if (loginResponse != null) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String userData = json.encode(loginResponse.toJson());
      await sharedPreferences.setString(loginResponseString, userData);
      log("✅ Login response saved:\n$userData");
    }
  }

  Future<LoginResponseModel?> getLoginResponse() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userData = sharedPreferences.getString(loginResponseString);
    if (userData == null) return null;
    return LoginResponseModel.fromJson(jsonDecode(userData));
  }

  setISLoggedIn(bool isLoggedIn) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.setBool(isLoggedIN, isLoggedIn);
  }

  Future<bool?> getIsLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(isLoggedIN) ?? false;
  }

  setDeviceInfo(String deviceInfo) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.setString(deviceInfoString, deviceInfo);
  }

  Future<String?> getDeviceInfo() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(deviceInfoString) ?? '';
  }
}
