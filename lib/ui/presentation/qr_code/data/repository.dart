import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:el_race/utils/urll_utils.dart';
import 'package:flutter/material.dart';

class QrCodeRepository {
  ApiQuery apiQuery = ApiQuery();
  final UserRepo userRepo = UserRepo();

  Future<Uint8List?> getQrCodeImage() async {
    try {
      final loginResponse = await userRepo.getLoginResponse();
      if (loginResponse?.result?.data?.emp_id == null) {
        log('❌ No employee ID found in login response');
        return null;
      }

      final empId = loginResponse!.result!.data!.emp_id!;
      log('🔍 Fetching QR code for employee ID: $empId');

      final token = loginResponse.result?.token;
      if (token == null || token.isEmpty) {
        log('❌ No authentication token found');
        return null;
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await apiQuery.getQuery(
        '${UrlUtil.qrCodeApi}$empId',
        headers,
        null,
        'qr_code',
        false,
        true,
        false,
      );

      if (response?.statusCode == 200) {
        if (response?.data is List<int>) {
          return Uint8List.fromList(response!.data);
        } else if (response?.data is String) {
          return base64Decode(response!.data);
        } else {
          log('❌ Unexpected response format for QR code');
          return null;
        }
      } else {
        log('❌ Failed to fetch QR code: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching QR code: $e');
      return null;
    }
  }

  Future<Uint8List?> getQrCodeImageDirect() async {
    try {
      // Get current user's login data
      final loginResponse = await userRepo.getLoginResponse();
      if (loginResponse?.result?.data?.emp_id == null) {
        log('❌ No employee ID found in login response');
        return null;
      }

      final empId = loginResponse!.result!.data!.emp_id!;
      log('🔍 Fetching QR code directly for employee ID: $empId');

      // Get authentication token
      final token = loginResponse.result?.token;
      if (token == null || token.isEmpty) {
        log('❌ No authentication token found');
        return null;
      }

      // Create Dio instance for direct image download
      final dio = Dio();

      // Prepare headers with authentication
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
      };

      // Make direct GET request to QR code endpoint
      final response = await dio.get(
        '${UrlUtil.baseUrl}${UrlUtil.qrCodeApi}$empId',
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes, // Important for binary data
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        log('❌ Failed to fetch QR code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching QR code directly: $e');
      return null;
    }
  }
}
