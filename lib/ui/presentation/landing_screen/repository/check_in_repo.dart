import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:intl/intl.dart';

import '../../../../utils/urll_utils.dart';

UserRepo _userRepo = UserRepo();

ApiQuery _apiQuery = ApiQuery();

/// Check-In Repository
///
/// Time Tracking Rules:
/// • Check-in is global and unified across all projects
/// • Does not send project-specific information in the API call
/// • Timer starts with fixed 8-hour duration regardless of project
/// • Detailed project-based time tracking is handled via job missions
///
/// NOTE: The 8 working hours are global and shared across all projects.
///       Switching projects does NOT reset or create a new timer.
class CheckInREpo {
  Future<Response?> checkInUser(String lat, String long) async {
    final loginResponse = await _userRepo.getLoginResponse();

    var token = loginResponse!.result!.token!;
    var userResponse = await _userRepo.getLoginResponse();
    var deviceInfo = await _userRepo.getDeviceInfo();
    try {
      var userID = userResponse!.result!.data!.uid.toString();
      Map<String, String> header = {
        "Content-Type": "application/json",
        'Accept': 'application/json',
        "Authorization": "Bearer $token"
      };
      var officeId = userResponse!.result!.data!.default_operating_unit_id;

      // Compute fresh timestamp at call time (NOT at import time)
      final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      Map<String, dynamic> data = {
        "jsonrpc": "2.0",
        "params": {
          "user_id": int.tryParse(userID.toString()) ?? 0,
          "device_id": deviceInfo,
          "checkin_date_time": formattedDate,
          "check_in_long": long,
          "check_in_lat": lat,
          "office": officeId,
        }
      };

      log(data.toString());

      Response? response = await _apiQuery.postQuery(
          UrlUtil.checkInApi, header, data, 'checkin', true);
      log(UrlUtil.checkInApi);
      log(data.toString());
      log('checkInUser: ${response.toString()}');

      return response!;
    } catch (e) {
      log('checkInUser $e');
    }
    return null;
  }
}
