import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:el_race/utils/urll_utils.dart';

class QrCodeRepository {
  ApiQuery apiQuery = ApiQuery();
  final UserRepo userRepo = UserRepo();

  Future<Uint8List?> getQrCodeImage() async {
    try {
      final loginResponse = await userRepo.getLoginResponse();

      if (loginResponse?.result?.data == null) {
        log('❌ No login data found');
        return null;
      }

      // Try emp_profile_id first, fallback to emp_id
      int? empId;
      if (loginResponse!.result!.data!.emp_profile_id != null) {
        empId = int.tryParse(loginResponse.result!.data!.emp_profile_id!);
      } else if (loginResponse.result!.data!.emp_id != null) {
        empId = int.tryParse(loginResponse.result!.data!.emp_id!);
      }

      if (empId == null) {
        log('❌ No employee ID found in login response (tried emp_profile_id and emp_id)');
        return null;
      }

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
      print('\n🚀 ========== QR CODE LOADING START ==========');

      // Get current user's login data
      final loginResponse = await userRepo.getLoginResponse();
      print('📦 Login Response: ${loginResponse != null ? "Found" : "NULL"}');

      if (loginResponse?.result?.data == null) {
        print('❌ ERROR: No login data found');
        print('🔚 ========== QR CODE LOADING FAILED ==========\n');
        return null;
      }

      // Debug: Print all employee IDs
      print('👤 emp_id: ${loginResponse!.result!.data!.emp_id}');
      print('👤 emp_profile_id: ${loginResponse.result!.data!.emp_profile_id}');

      // Try emp_profile_id first, fallback to emp_id
      int? empId;
      if (loginResponse.result!.data!.emp_profile_id != null) {
        empId = int.tryParse(loginResponse.result!.data!.emp_profile_id!);
        print('✅ Using emp_profile_id: $empId');
      } else if (loginResponse.result!.data!.emp_id != null) {
        empId = int.tryParse(loginResponse.result!.data!.emp_id!);
        print('✅ Using emp_id: $empId');
      }

      if (empId == null) {
        print(
            '❌ ERROR: No employee ID found (emp_profile_id and emp_id both invalid)');
        print('🔚 ========== QR CODE LOADING FAILED ==========\n');
        return null;
      }

      // Get authentication token
      final token = loginResponse.result?.token;
      print(
          '🔑 Token: ${token != null && token.isNotEmpty ? "${token.substring(0, 20)}..." : "NULL/EMPTY"}');

      if (token == null || token.isEmpty) {
        print('❌ ERROR: No authentication token found');
        print('🔚 ========== QR CODE LOADING FAILED ==========\n');
        return null;
      }

      // Build API URL
      final apiUrl = '${UrlUtil.baseUrl}${UrlUtil.qrCodeApi}$empId';
      print('🌐 API URL: $apiUrl');

      // Create Dio instance for direct image download
      final dio = Dio();

      // Prepare headers with authentication
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
      };
      print('📋 Headers: Authorization Bearer ***');

      print('⏳ Making API request...');

      // Make direct GET request to QR code endpoint
      final response = await dio.get(
        apiUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes, // Important for binary data
        ),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📦 Response Data Type: ${response.data.runtimeType}');
      print('📊 Response Data Length: ${response.data?.length ?? 0} bytes');

      if (response.statusCode == 200) {
        if (response.data != null && response.data.length > 0) {
          print('✅ QR Code loaded successfully!');
          print('🔚 ========== QR CODE LOADING SUCCESS ==========\n');
          return response.data;
        } else {
          print('❌ ERROR: Response data is empty');
          print('🔚 ========== QR CODE LOADING FAILED ==========\n');
          return null;
        }
      } else {
        print('❌ ERROR: HTTP ${response.statusCode}');
        print('📄 Response Message: ${response.statusMessage}');
        print('🔚 ========== QR CODE LOADING FAILED ==========\n');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION: $e');
      print(
          '📍 Stack Trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      print('🔚 ========== QR CODE LOADING FAILED ==========\n');
      return null;
    }
  }
}
