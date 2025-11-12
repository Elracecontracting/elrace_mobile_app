import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:el_race/utils/api_query.dart';
import 'package:intl/intl.dart';

import '../../../../utils/urll_utils.dart';

UserRepo _userRepo = UserRepo();

DateTime now = DateTime.now();

// Format it as 'YYYY-MM-DD HH:mm:ss'
String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

ApiQuery _apiQuery = ApiQuery();

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
      Map<String, dynamic> data = {
        "jsonrpc": "2.0",
        "params": {
          "user_id": userID,
          "device_id": deviceInfo,
          "checkin_date_time": formattedDate,
          "check_in_long": long,
          "check_in_lat": lat,
        }
      };

      log(data.toString());

      Response? response = await _apiQuery.postQuery(
          UrlUtil.checkInApi, header, data, 'checkin', true);
      return response!;
    } catch (e) {
      log('checkInUser $e');
    }
    return null;
  }
}
