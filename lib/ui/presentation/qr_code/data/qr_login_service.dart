import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';

class QrLoginService {
  final Dio _dio = Dio();
  static const String baseUrl = 'https://rcc.sawatech.ae/api/auth';

  /// Login to website using QR code
  /// Similar to WhatsApp Web login
  Future<Map<String, dynamic>> loginWithQrCode(String qrCode) async {
    try {
      print('\n🟢 ========== QR LOGIN SERVICE ==========');
      // Get odoo_id from current user session
      final loginData = SharedPref.getLoginData();
      print('📦 Login Data Retrieved:');
      print('   - Has Result: ${loginData.result != null}');
      print('   - Has Data: ${loginData.result?.data != null}');
      
      final odooId = loginData.result?.data?.odoo_user_id;
      print('🆔 User IDs Available:');
      print('   - odoo_user_id: $odooId');
      print('   - uid: ${loginData.result?.data?.uid}');
      print('   - emp_id: ${loginData.result?.data?.emp_id}');
      print('   - emp_profile_id: ${loginData.result?.data?.emp_profile_id}');

      if (odooId == null) {
        print('❌ QR Login: No odoo_user_id found in session');
        print('🟢 ========================================\n');
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
        };
      }

      // Parse QR code if it's JSON
      String actualCode = qrCode;
      try {
        final qrJson = jsonDecode(qrCode);
        if (qrJson is Map && qrJson.containsKey('code')) {
          actualCode = qrJson['code'];
          print('🔍 QR Code is JSON - Extracted code field:');
          print('   - Original: $qrCode');
          print('   - Extracted Code: $actualCode');
          print('   - Type: ${qrJson['type']}');
          print('   - Timestamp: ${qrJson['timestamp']}');
          print('   - ExpiresIn: ${qrJson['expiresIn']}');
        }
      } catch (e) {
        print('ℹ️ QR Code is plain text (not JSON)');
        actualCode = qrCode;
      }

      print('\n📡 API Request Details:');
      print('   - Original QR: $qrCode');
      print('   - Actual Code to Send: $actualCode');
      print('   - Odoo ID: $odooId');
      print('   - Code Length: ${actualCode.length}');

      final url = '$baseUrl/login-with-code/$actualCode';
      print('\n🌐 Making HTTP Request:');
      print('   - Method: POST');
      print('   - URL: $url');
      print('   - Body: {"odoo_id": $odooId}');
      print('   - Headers: {"Content-Type": "application/json", "Accept": "application/json"}');
      
      final response = await _dio.post(
        url,
        data: {'odoo_id': odooId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true, // Accept all status codes
        ),
      );

      print('\n📥 HTTP Response Received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Status Message: ${response.statusMessage}');
      print('   - Headers: ${response.headers}');
      print('   - Data Type: ${response.data.runtimeType}');
      print('   - Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('\n✅ SUCCESS: Status ${response.statusCode}');
        print('🟢 ========================================\n');
        return {
          'success': true,
          'message': 'Login successful',
          'data': response.data,
        };
      } else {
        print('\n⚠️ FAILED: Status ${response.statusCode}');
        print('   - Error Message: ${response.data?['message']}');
        print('🟢 ========================================\n');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Login failed',
          'data': response.data,
        };
      }
    } catch (e, stackTrace) {
      print('\n❌ EXCEPTION CAUGHT:');
      print('   - Error: $e');
      print('   - Type: ${e.runtimeType}');
      print('   - Stack Trace: $stackTrace');
      print('🟢 ========================================\n');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
